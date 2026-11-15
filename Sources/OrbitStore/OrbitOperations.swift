import Foundation
import AppKit
import Combine
import UserNotifications

// Operations are opt-in, auditable and local to this Mac. No privileged helper,
// Gatekeeper override, or arbitrary shell execution is provided by OrbitStore.

struct OrbitHistoryEvent: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    let name: String
    let action: String
    let result: String
    let details: String
    let path: String?
}

struct OrbitInstallReceipt: Codable {
    let repo:String
    let bundleID:String
    let teamID:String
    let path:String
    let approvedAt:Date
}

struct OrbitActionFeedback:Identifiable {
    enum Kind { case information,success,warning }
    let id=UUID()
    let title:String
    let message:String
    let kind:Kind
}

struct OrbitJob: Identifiable {
    let id: UUID
    let repo: String
    let name: String
    var phase: String
    var detail: String
    var finished: Bool
}

struct OrbitDiagnosis {
    let signature: String
    let gatekeeper: String
    let architectures: String
    let sparkle: String?
    let bundleID: String
}

struct OrbitSource {
    let name: String
    let description: String
    let url: URL
}

enum OrbitInstallError: LocalizedError {
    case unsupported(String)
    case unsafe(String)
    case permission(String)
    case operation(String)
    var errorDescription: String? {
        switch self {
        case .unsupported(let msg): return msg
        case .unsafe(let msg): return "Vérification de sécurité : \(msg)"
        case .permission(let msg): return msg
        case .operation(let msg): return msg
        }
    }
}

enum OrbitInstallResult {
    case installed(String, String?)
    case manual(String)
}

enum OrbitShell {
    static func run(_ executable: String, _ args: [String]) throws -> (Int32, String) {
        let process=Process()
        process.executableURL=URL(fileURLWithPath:executable)
        process.arguments=args
        let pipe=Pipe()
        process.standardOutput=pipe
        process.standardError=pipe
        try process.run()
        let data=pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus,String(data:data,encoding:.utf8) ?? "")
    }
}

enum OrbitArchivePolicy {
    static func isSafeEntry(_ raw:String)->Bool {
        let normalized=raw.replacingOccurrences(of:"\\",with:"/")
        let components=normalized.split(separator:"/",omittingEmptySubsequences:false)
        return !normalized.hasPrefix("/") &&
               !normalized.contains("\0") &&
               !components.contains("..")
    }
}

enum OrbitPackageInstaller {
    static func install(package:URL, targetDirectory:URL, expectedBundleID:String?,
                        runningBundleIDs:Set<String>) throws -> OrbitInstallResult {
        let fm=FileManager.default
        guard fm.fileExists(atPath:package.path), package.isFileURL else {
            throw OrbitInstallError.operation("Le téléchargement n'existe plus.")
        }
        guard ["dmg","zip","pkg"].contains(package.pathExtension.lowercased()) else {
            return .manual("Format non pris en charge. Inspecte ce fichier dans le Finder.")
        }
        if package.pathExtension.lowercased() == "pkg" {
            return .manual("Un paquet PKG peut exécuter des scripts et modifier le système. OrbitStore ne l'exécute pas silencieusement ; valide-le dans l'installateur macOS.")
        }
        let temporary=fm.temporaryDirectory.appendingPathComponent("OrbitStore-\(UUID().uuidString)",isDirectory:true)
        try fm.createDirectory(at:temporary,withIntermediateDirectories:true)
        defer { try? fm.removeItem(at:temporary) }
        var sourceRoot: URL?
        var mount: URL?
        defer {
            if let mount {
                _ = try? OrbitShell.run("/usr/bin/hdiutil",["detach",mount.path,"-quiet"])
            }
        }
        if package.pathExtension.lowercased() == "dmg" {
            let (status,output)=try OrbitShell.run("/usr/bin/hdiutil",
                    ["attach",package.path,"-plist","-readonly","-nobrowse"])
            guard status == 0,
                  let data=output.data(using:.utf8),
                  let plist=try? PropertyListSerialization.propertyList(from:data,format:nil) as? [String:Any],
                  let entities=plist["system-entities"] as? [[String:Any]],
                  let mountPath=entities.compactMap({ $0["mount-point"] as? String }).first else {
                throw OrbitInstallError.operation("Impossible de monter le DMG en lecture seule.")
            }
            mount=URL(fileURLWithPath:mountPath,isDirectory:true)
            sourceRoot=mount
        } else {
            // Reject archive entries that could escape the extraction directory.
            let (status,listing)=try OrbitShell.run("/usr/bin/unzip",["-Z","-1",package.path])
            guard status == 0 else { throw OrbitInstallError.unsafe("Liste ZIP illisible.") }
            for raw in listing.components(separatedBy:"\n").filter({ !$0.isEmpty }) {
                guard OrbitArchivePolicy.isSafeEntry(raw) else {
                    throw OrbitInstallError.unsafe("Chemin dangereux dans l'archive.")
                }
            }
            let extract=temporary.appendingPathComponent("extracted",isDirectory:true)
            try fm.createDirectory(at:extract,withIntermediateDirectories:true)
            let (code,_)=try OrbitShell.run("/usr/bin/ditto",["-x","-k",package.path,extract.path])
            guard code == 0 else { throw OrbitInstallError.operation("Impossible d'extraire le ZIP.") }
            sourceRoot=extract
        }
        guard let root=sourceRoot else { throw OrbitInstallError.operation("Archive inaccessible.") }
        var choices:[URL]=[]
        func inspect(_ root:URL,_ depth:Int) {
            guard let listing=try? fm.contentsOfDirectory(at:root,includingPropertiesForKeys:[.isDirectoryKey,.isSymbolicLinkKey],options:[.skipsHiddenFiles]) else { return }
            for url in listing {
                if url.pathExtension.lowercased() == "app" {
                    if (try? url.resourceValues(forKeys:[.isSymbolicLinkKey]).isSymbolicLink) != true {
                        choices.append(url)
                    }
                } else if depth > 0,
                          (try? url.resourceValues(forKeys:[.isDirectoryKey]).isDirectory) == true {
                    inspect(url,depth-1)
                }
            }
        }
        inspect(root,2)
        guard choices.count == 1, let candidate=choices.first else {
            return .manual(choices.isEmpty
                ? "Aucune application .app trouvée : ouvre le paquet dans Finder."
                : "Plusieurs applications ont été trouvées. Choisis manuellement celle à installer.")
        }
        let staged=temporary.appendingPathComponent(candidate.lastPathComponent,isDirectory:true)
        try fm.copyItem(at:candidate,to:staged)
        guard let bundle=Bundle(url:staged),
              let bundleID=bundle.bundleIdentifier, !bundleID.isEmpty else {
            throw OrbitInstallError.unsafe("Bundle ID absent ou invalide.")
        }
        if let expectedBundleID, bundleID != expectedBundleID {
            throw OrbitInstallError.unsafe("Identifiant inattendu : \(bundleID), attendu : \(expectedBundleID).")
        }
        if runningBundleIDs.contains(bundleID) {
            return .manual("Ferme l'application actuellement ouverte avant de la remplacer.")
        }
        let (code,verification)=try OrbitShell.run("/usr/bin/codesign",
                ["--verify","--deep","--strict","--verbose=2",staged.path])
        guard code == 0 else {
            throw OrbitInstallError.unsafe("Signature macOS invalide ou absente. \(verification.prefix(180))")
        }
        let (accepted,assessment)=try OrbitShell.run("/usr/sbin/spctl",
                ["--assess","--type","execute","--verbose=2",staged.path])
        guard accepted == 0 else {
            return .manual("Gatekeeper ne valide pas ce logiciel. Aucune installation silencieuse : \(assessment.prefix(160))")
        }
        if let minimum=bundle.object(forInfoDictionaryKey:"LSMinimumSystemVersion") as? String {
            let numbers=minimum.split(separator:".").compactMap { Int($0) }
            if let major=numbers.first {
                let current=ProcessInfo.processInfo.operatingSystemVersion
                let minor=numbers.count>1 ? numbers[1] : 0
                if major>current.majorVersion || (major==current.majorVersion && minor>current.minorVersion) {
                    throw OrbitInstallError.unsupported("macOS \(minimum) minimum requis.")
                }
            }
        }
        let directory=targetDirectory.standardizedFileURL.resolvingSymlinksInPath()
        guard directory.path.hasPrefix("/Users/") || directory.path=="/Applications",
              !directory.path.hasPrefix("/System/"),
              !directory.path.hasPrefix("/Volumes/"),
              !directory.path.hasPrefix("/Library/") else {
            throw OrbitInstallError.permission("Dossier protégé. Choisis /Applications ou un dossier dans ton compte utilisateur.")
        }
        try fm.createDirectory(at:directory,withIntermediateDirectories:true)
        guard fm.isWritableFile(atPath:directory.path) else {
            throw OrbitInstallError.permission("Pas d'autorisation d'écriture dans \(directory.path). Choisis ~/Applications dans les préférences ou autorise l'accès via macOS.")
        }
        let destination=directory.appendingPathComponent(staged.lastPathComponent,isDirectory:true)
        var backup:String?
        if fm.fileExists(atPath:destination.path) {
            guard let previous=Bundle(url:destination),
                  previous.bundleIdentifier == bundleID else {
                throw OrbitInstallError.unsafe("Une application différente occupe déjà cet emplacement.")
            }
            let existingTeam=teamIdentifier(destination)
            let newTeam=teamIdentifier(staged)
            guard let old=existingTeam, let next=newTeam, old==next else {
                return .manual("Impossible de confirmer le même éditeur entre les deux versions. Mise à jour manuelle requise.")
            }
            let backupRoot=FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/OrbitStore/Backups",isDirectory:true)
            try fm.createDirectory(at:backupRoot,withIntermediateDirectories:true)
            let saved=backupRoot.appendingPathComponent("\(UUID().uuidString)-\(destination.lastPathComponent)")
            try fm.moveItem(at:destination,to:saved)
            backup=saved.path
            do {
                try fm.copyItem(at:staged,to:destination)
            } catch {
                try? fm.moveItem(at:saved,to:destination)
                throw OrbitInstallError.operation("Échec du remplacement ; ancienne version restaurée : \(error.localizedDescription)")
            }
        } else {
            try fm.copyItem(at:staged,to:destination)
        }
        return .installed(destination.path,backup)
    }

    static func teamIdentifier(_ path:URL)->String? {
        guard let result=try? OrbitShell.run("/usr/bin/codesign",
                      ["-dv","--verbose=4",path.path]),result.0 == 0 else { return nil }
        return result.1.components(separatedBy:"\n").first(where:{$0.hasPrefix("TeamIdentifier=")})
            .map { String($0.dropFirst("TeamIdentifier=".count)) }
            .flatMap { $0=="not set" ? nil : $0 }
    }

    static func diagnose(_ app:MacApp)->OrbitDiagnosis {
        let url=URL(fileURLWithPath:app.path)
        let signed=(try? OrbitShell.run("/usr/bin/codesign",["--verify","--deep","--strict",url.path]))
        let secure=(try? OrbitShell.run("/usr/sbin/spctl",["--assess","--type","execute",url.path]))
        var architecture="Inconnue"
        if let executable=Bundle(url:url)?.executableURL,
           let result=try? OrbitShell.run("/usr/bin/lipo",["-archs",executable.path]),
           result.0 == 0 { architecture=result.1.trimmingCharacters(in:.whitespacesAndNewlines) }
        let feed=Bundle(url:url)?.object(forInfoDictionaryKey:"SUFeedURL") as? String
        return OrbitDiagnosis(signature:signed?.0 == 0 ? "Valide" : "Non vérifiée",
                              gatekeeper:secure?.0 == 0 ? "Accepté" : "Non confirmé",
                              architectures:architecture,
                              sparkle:feed,bundleID:app.bundleID)
    }
}

@MainActor
final class OrbitOperations: ObservableObject {
    @Published var destinationChoice:String { didSet { UserDefaults.standard.set(destinationChoice,forKey:"orbit.install.destination") } }
    @Published var customDirectory:String { didSet { UserDefaults.standard.set(customDirectory,forKey:"orbit.install.custom") } }
    @Published var keepPackages:Bool { didSet { UserDefaults.standard.set(keepPackages,forKey:"orbit.install.keep") } }
    @Published var launchAfterInstall:Bool { didSet { UserDefaults.standard.set(launchAfterInstall,forKey:"orbit.install.launch") } }
    @Published var history:[OrbitHistoryEvent]=[]
    @Published var jobs:[OrbitJob]=[]
    @Published var lastFeedback:OrbitActionFeedback?
    func feedback(_ title:String,_ message:String,kind:OrbitActionFeedback.Kind = .information) {
        lastFeedback=OrbitActionFeedback(title:title,message:message,kind:kind)
    }
    func clearFeedback() { lastFeedback=nil }
    @Published var diagnoses:[String:OrbitDiagnosis]=[:]
    @Published var pluginStatus:[String:String]=[:]
    @Published var sources:[String:[OrbitSource]] = [:]
    @Published var ignoredVersions:[String:String] = [:]
    @Published var receipts:[String:OrbitInstallReceipt] = [:]
    @Published var autoInstallManaged:Bool {
        didSet { UserDefaults.standard.set(autoInstallManaged,forKey:"orbit.autoManagedUpdates") }
    }
    @Published var digestEnabled:Bool { didSet { UserDefaults.standard.set(digestEnabled,forKey:"orbit.digest") } }
    @Published var diagnosticStatus=""
    private var processing=false

    init() {
        let d=UserDefaults.standard
        destinationChoice=d.string(forKey:"orbit.install.destination") ?? "/Applications"
        customDirectory=d.string(forKey:"orbit.install.custom") ?? "~/Applications"
        keepPackages=d.bool(forKey:"orbit.install.keep")
        launchAfterInstall=d.bool(forKey:"orbit.install.launch")
        digestEnabled=d.bool(forKey:"orbit.digest")
        autoInstallManaged=d.bool(forKey:"orbit.autoManagedUpdates")
        ignoredVersions=d.dictionary(forKey:"orbit.ignoredVersions") as? [String:String] ?? [:]
        let receiptFile=FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/OrbitStore/receipts.json")
        if let data=try? Data(contentsOf:receiptFile),
           let value=try? JSONDecoder().decode([String:OrbitInstallReceipt].self,from:data) {
            receipts=value
        }
        let file=Self.historyFile
        if let data=try? Data(contentsOf:file),let items=try? JSONDecoder().decode([OrbitHistoryEvent].self,from:data) {
            history=items
        }
    }

    private static var historyFile:URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/OrbitStore/history.json")
    }
    var chosenDirectory:URL {
        let path=destinationChoice=="Personnalisé" ? customDirectory : destinationChoice
        let expanded=(path as NSString).expandingTildeInPath
        return URL(fileURLWithPath:expanded,isDirectory:true)
    }
    func record(_ name:String,action:String,result:String,details:String,path:String?=nil) {
        history.insert(OrbitHistoryEvent(name:name,action:action,result:result,details:details,path:path),at:0)
        history=Array(history.prefix(250))
        let file=Self.historyFile
        try? FileManager.default.createDirectory(at:file.deletingLastPathComponent(),withIntermediateDirectories:true)
        if let data=try? JSONEncoder().encode(history) { try? data.write(to:file,options:.atomic) }
    }
    private func saveReceipts() {
        let path=FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/OrbitStore/receipts.json")
        try? FileManager.default.createDirectory(at:path.deletingLastPathComponent(),
                                                 withIntermediateDirectories:true)
        if let data=try? JSONEncoder().encode(receipts) {
            try? data.write(to:path,options:.atomic)
        }
    }
    func offerManagedUpdates(store:StoreModel) {
        guard autoInstallManaged else { return }
        let eligible=store.catalog.filter { entry in
            guard let receipt=receipts[entry.repo],
                  let app=store.matches(entry).first(where: { $0.bundleID==receipt.bundleID }),
                  app.path==receipt.path,
                  OrbitPackageInstaller.teamIdentifier(URL(fileURLWithPath:app.path))==receipt.teamID,
                  store.updateAvailable(entry),
                  !isIgnored(entry,release:store.releases[entry.repo]?.tag_name) else { return false }
            return true
        }
        if !eligible.isEmpty { enqueue(eligible,store:store) }
    }

    func ignore(_ repo:String,version:String) {
        ignoredVersions[repo]=version
        UserDefaults.standard.set(ignoredVersions,forKey:"orbit.ignoredVersions")
    }
    func isIgnored(_ entry:CatalogApp,release:String?) -> Bool {
        guard let release else { return false }
        return ignoredVersions[entry.repo]==release
    }

    func enqueue(_ entries:[CatalogApp],store:StoreModel) {
        guard !entries.isEmpty else {
            feedback("Sélection vide","Choisis au moins une application.",kind:.warning)
            return
        }
        var added=0
        for entry in entries where !jobs.contains(where:{$0.repo==entry.repo && !$0.finished}) {
            added += 1
            jobs.append(OrbitJob(id:UUID(),repo:entry.repo,name:entry.name,
                                phase:"En attente",detail:"En file d'installation",finished:false))
        }
        if added>0 {
            feedback("Demande enregistrée",
                     added==1 ? "\(entries[0].name) est ajoutée à la file d'installation." :
                          "\(added) applications sont ajoutées à la file d'installation.")
        } else {
            feedback("Déjà en cours","Cette installation figure déjà dans la file.")
        }
        guard !processing else { return }
        processing=true
        Task { await processQueue(store:store) }
    }
    private func updateJob(_ id:UUID,phase:String,detail:String,finished:Bool=false) {
        guard let index=jobs.firstIndex(where:{$0.id==id}) else { return }
        jobs[index].phase=phase
        jobs[index].detail=detail
        jobs[index].finished=finished
    }
    private func processQueue(store:StoreModel) async {
        while let job=jobs.first(where:{!$0.finished}) {
            guard let entry=store.catalog.first(where:{$0.repo==job.repo}) ??
                    CatalogApp.fromRepositoryName(job.repo,name:job.name) else { break }
            updateJob(job.id,phase:"Téléchargement",detail:"Recherche d'un paquet macOS officiel…")
            guard let package=await store.acquirePackage(entry) else {
                let detail=store.errors[entry.repo] ?? "Aucun paquet macOS vérifié trouvé."
                updateJob(job.id,phase:"Échec",detail:detail,finished:true)
                feedback("Installation impossible",detail,kind:.warning)
                record(entry.name,action:"installation",result:"échec",details:detail)
                continue
            }
            updateJob(job.id,phase:"Vérification",detail:"Contrôle de la signature et de Gatekeeper…")
            let root=chosenDirectory
            let running=Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
            let expected=entry.repo.lowercased()=="voirfilm-tv/orbitestore" ? "fr.orbitstore.mac" : nil
            let result:Result<OrbitInstallResult,Error>=await Task.detached(priority:.userInitiated) {
                do {
                    return .success(try OrbitPackageInstaller.install(package:package,targetDirectory:root,
                                           expectedBundleID:expected,runningBundleIDs:running))
                } catch { return .failure(error) }
            }.value
            switch result {
            case .success(.installed(let path,let backup)):
                updateJob(job.id,phase:"Installée",detail:path,finished:true)
                feedback("Installation terminée","\(entry.name) est installée.",kind:.success)
                record(entry.name,action:backup == nil ? "installation":"mise à jour",
                       result:"succès",details:"Vérification macOS réussie",path:path)
                let appURL=URL(fileURLWithPath:path)
                if let bundleID=Bundle(url:appURL)?.bundleIdentifier,
                   let team=OrbitPackageInstaller.teamIdentifier(appURL) {
                    receipts[entry.repo]=OrbitInstallReceipt(
                        repo:entry.repo,bundleID:bundleID,teamID:team,
                        path:path,approvedAt:Date())
                    saveReceipts()
                }
                if !keepPackages { try? FileManager.default.removeItem(at:package) }
                store.scan()
                if launchAfterInstall { NSWorkspace.shared.open(URL(fileURLWithPath:path)) }
            case .success(.manual(let message)):
                // The user explicitly requested installation. Opening the DMG
                // does not execute untrusted code or bypass Gatekeeper.
                let ext=package.pathExtension.lowercased()
                let opened=["dmg","zip","pkg"].contains(ext) && NSWorkspace.shared.open(package)
                if !opened { NSWorkspace.shared.activateFileViewerSelecting([package]) }
                updateJob(job.id,phase:"Action requise",
                          detail:(opened ? "Paquet ouvert automatiquement. " : "Paquet affiché dans Finder. ")+message,
                          finished:true)
                feedback("Installation manuelle nécessaire",
                         (opened ? "Le paquet a été ouvert. " : "Retrouve le paquet dans Finder. ")+message,
                         kind:.warning)
                record(entry.name,action:"installation",result:"manuelle",details:message,path:package.path)
            case .failure(let error):
                updateJob(job.id,phase:"Échec",detail:error.localizedDescription,finished:true)
                feedback("Installation interrompue",error.localizedDescription,kind:.warning)
                record(entry.name,action:"installation",result:"échec",details:error.localizedDescription)
            }
        }
        processing=false
    }

    func diagnose(_ app:MacApp) {
        diagnosticStatus="Analyse en cours…"
        Task {
            let value=await Task.detached(priority:.utility) {
                OrbitPackageInstaller.diagnose(app)
            }.value
            diagnoses[app.path]=value
            diagnosticStatus="Analyse terminée"
        }
    }

    func uninstall(_ app:MacApp,store:StoreModel) {
        let file=URL(fileURLWithPath:app.path)
        guard (file.path.hasPrefix("/Applications/") ||
               file.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path + "/")),
              !file.path.hasPrefix("/System/"),app.bundleID != "fr.orbitstore.mac" else {
            diagnosticStatus="Cette application système, externe ou OrbitStore ne peut pas être supprimée ici."
            return
        }
        if NSWorkspace.shared.runningApplications.contains(where:{$0.bundleIdentifier==app.bundleID}) {
            diagnosticStatus="Ferme l'application avant de la désinstaller."
            return
        }
        Task {
            let result:Result<Void,Error>=await Task.detached {
                do {
                    var trash: NSURL?
                    try FileManager.default.trashItem(at:file,resultingItemURL:&trash)
                    return .success(())
                } catch { return .failure(error) }
            }.value
            switch result {
            case .success:
                record(app.name,action:"désinstallation",result:"corbeille",
                       details:"Application déplacée dans la Corbeille ; données utilisateur conservées.",path:app.path)
                store.scan()
                if let key=receipts.first(where:{$0.value.bundleID==app.bundleID})?.key {
                    receipts.removeValue(forKey:key)
                    saveReceipts()
                }
                diagnosticStatus="Déplacée dans la Corbeille."
            case .failure(let error):
                diagnosticStatus="Désinstallation impossible : \(error.localizedDescription)"
            }
        }
    }
    func residualPaths(for app:MacApp)->[String] {
        guard !app.bundleID.isEmpty else { return [] }
        let home=FileManager.default.homeDirectoryForCurrentUser
        let candidates=[
            "Library/Preferences/\(app.bundleID).plist",
            "Library/Caches/\(app.bundleID)",
            "Library/Containers/\(app.bundleID)"
        ]
        return candidates.map{home.appendingPathComponent($0).path}
            .filter{FileManager.default.fileExists(atPath:$0)}
    }
    func availableBackup(for app:MacApp)->URL? {
        let root=FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/OrbitStore/Backups")
        let options=(try? FileManager.default.contentsOfDirectory(at:root,
                    includingPropertiesForKeys:[.contentModificationDateKey])) ?? []
        return options.filter{$0.lastPathComponent.hasSuffix("-"+URL(fileURLWithPath:app.path).lastPathComponent)}
            .sorted{
                ((try? $0.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast) >
                ((try? $1.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
            }.first
    }
    func rollback(_ app:MacApp,store:StoreModel) {
        guard let backup=availableBackup(for:app) else {
            diagnosticStatus="Aucune sauvegarde OrbitStore disponible."
            return
        }
        if NSWorkspace.shared.runningApplications.contains(where:{$0.bundleIdentifier==app.bundleID}) {
            diagnosticStatus="Ferme l'application pour revenir à une version précédente."
            return
        }
        Task {
            let current=URL(fileURLWithPath:app.path)
            let outcome:Result<Void,Error>=await Task.detached {
                do {
                    guard let old=Bundle(url:backup),old.bundleIdentifier==app.bundleID else {
                        throw OrbitInstallError.unsafe("L'identifiant de la sauvegarde ne correspond pas.")
                    }
                    let a=OrbitPackageInstaller.teamIdentifier(current)
                    let b=OrbitPackageInstaller.teamIdentifier(backup)
                    guard a != nil && a==b else {
                        throw OrbitInstallError.unsafe("Éditeurs non concordants.")
                    }
                    let (verified,_)=try OrbitShell.run("/usr/bin/codesign",
                                ["--verify","--deep","--strict",backup.path])
                    guard verified==0 else {
                        throw OrbitInstallError.unsafe("Signature de la sauvegarde invalide.")
                    }
                    let recovery=current.deletingLastPathComponent()
                        .appendingPathComponent(".orbitstore-recovery-\(UUID().uuidString).app")
                    try FileManager.default.moveItem(at:current,to:recovery)
                    do { try FileManager.default.copyItem(at:backup,to:current) }
                    catch {
                        try? FileManager.default.moveItem(at:recovery,to:current)
                        throw error
                    }
                    try? FileManager.default.removeItem(at:recovery)
                    return .success(())
                } catch { return .failure(error) }
            }.value
            switch outcome {
            case .success:
                record(app.name,action:"retour arrière",result:"succès",
                       details:"Ancienne application restaurée. Données utilisateur non restaurées.",path:app.path)
                store.scan()
                diagnosticStatus="Ancienne version restaurée."
            case .failure(let error):
                diagnosticStatus=error.localizedDescription
            }
        }
    }

    func checkSources(for entry:CatalogApp,installed:MacApp?) async {
        var rows=[OrbitSource(name:"GitHub",description:"Code source, publications et suivi",url:entry.url)]
        if let homepage=URL(string:entry.url.absoluteString) { _=homepage }
        // Homebrew metadata is looked up by a curated slug to avoid false matches.
        let slugs:[String:String]=[
            "obsproject/obs-studio":"obs", "handbrake/handbrake":"handbrake",
            "iina/iina":"iina","blender/blender":"blender",
            "microsoft/vscode":"visual-studio-code","utmapp/utm":"utm",
            "voirfilm-tv/orbitestore":""
        ]
        if let slug=slugs[entry.repo.lowercased()], !slug.isEmpty,
           let url=URL(string:"https://formulae.brew.sh/api/cask/\(slug).json") {
            if let (data,response)=try? await URLSession.shared.data(from:url),
               (response as? HTTPURLResponse)?.statusCode==200,
               let object=try? JSONSerialization.jsonObject(with:data) as? [String:Any],
               let token=object["token"] as? String,token==slug {
                rows.append(OrbitSource(name:"Homebrew Cask",description:"Fiche externe vérifiée : \(slug)",
                                        url:URL(string:"https://formulae.brew.sh/cask/\(slug)")!))
            }
        }
        if let app=installed,
           let feed=Bundle(url:URL(fileURLWithPath:app.path))?.object(forInfoDictionaryKey:"SUFeedURL") as? String,
           let url=URL(string:feed),url.scheme=="https" {
            rows.append(OrbitSource(name:"Sparkle",description:"Flux de mise à jour déclaré par le logiciel installé",
                                    url:url))
        }
        sources[entry.repo]=rows
    }

    func notifyDigest(store:StoreModel) {
        guard digestEnabled else { return }
        let current=store.catalog.filter{!store.matches($0).isEmpty}
        let available=current.filter{store.updateAvailable($0) && !isIgnored($0,release:store.releases[$0.repo]?.tag_name)}
        guard !available.isEmpty else { return }
        let today=Calendar.current.startOfDay(for:Date()).timeIntervalSince1970
        guard UserDefaults.standard.double(forKey:"orbit.digest.last") < today else { return }
        let content=UNMutableNotificationContent()
        content.title="OrbitStore · Mises à jour"
        content.body="\(available.count) nouvelles versions à examiner. Ouvre OrbitStore pour les vérifier."
        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier:"orbit-digest-\(Int(today))",content:content,trigger:nil))
        UserDefaults.standard.set(today,forKey:"orbit.digest.last")
    }
}

extension CatalogApp {
    static func fromRepositoryName(_ repo:String,name:String)->CatalogApp? {
        guard repo.split(separator:"/").count==2 else { return nil }
        return CatalogApp(repo:repo,name:name,category:"GitHub",icon:"shippingbox",aliases:[])
    }
}
