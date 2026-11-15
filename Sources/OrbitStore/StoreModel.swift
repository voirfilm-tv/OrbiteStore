import Foundation
import AppKit
import Combine
import UserNotifications
import CryptoKit

struct CatalogApp: Identifiable, Hashable {
    let repo: String
    let name: String
    let category: String
    let icon: String
    let aliases: [String]
    var id: String { repo }
    var url: URL { URL(string: "https://github.com/" + repo)! }
}

enum Inventory {
    static let catalog: [CatalogApp] = [
        .init(repo:"obsproject/obs-studio",name:"OBS Studio",category:"Création",icon:"video.fill",aliases:["OBS"]),
        .init(repo:"iina/iina",name:"IINA",category:"Multimédia",icon:"play.rectangle.fill",aliases:[]),
        .init(repo:"HandBrake/HandBrake",name:"HandBrake",category:"Multimédia",icon:"film",aliases:[]),
        .init(repo:"blender/blender",name:"Blender",category:"Création",icon:"cube.transparent",aliases:[]),
        .init(repo:"microsoft/vscode",name:"Visual Studio Code",category:"Développement",icon:"chevron.left.forwardslash.chevron.right",aliases:["Code","VS Code"]),
        .init(repo:"VSCodium/vscodium",name:"VSCodium",category:"Développement",icon:"curlybraces",aliases:[]),
        .init(repo:"utmapp/UTM",name:"UTM",category:"Utilitaires",icon:"desktopcomputer",aliases:[]),
        .init(repo:"qBittorrent/qBittorrent",name:"qBittorrent",category:"Réseau",icon:"arrow.down.circle.fill",aliases:[]),
        .init(repo:"localsend/localsend",name:"LocalSend",category:"Réseau",icon:"paperplane.fill",aliases:[]),
        .init(repo:"jellyfin/jellyfin-media-player",name:"Jellyfin Media Player",category:"Multimédia",icon:"play.tv.fill",aliases:["Jellyfin"]),
        .init(repo:"jellyfin/jellyfin",name:"Jellyfin Server",category:"Réseau",icon:"server.rack",aliases:["Jellyfin"]),
        .init(repo:"bitwarden/clients",name:"Bitwarden",category:"Sécurité",icon:"lock.shield.fill",aliases:[]),
        .init(repo:"musescore/MuseScore",name:"MuseScore",category:"Création",icon:"music.note",aliases:[]),
        .init(repo:"sindresorhus/Velja",name:"Velja",category:"Utilitaires",icon:"safari",aliases:[]),
        .init(repo:"raycast/extensions",name:"Raycast Extensions",category:"Productivité",icon:"bolt.fill",aliases:["Raycast"]),
        .init(repo:"obsidianmd/obsidian-releases",name:"Obsidian",category:"Productivité",icon:"book.closed.fill",aliases:[]),
        .init(repo:"ProtonVPN/mac-app",name:"Proton VPN",category:"Sécurité",icon:"network.badge.shield.half.filled",aliases:["ProtonVPN"]),
        .init(repo:"OpenRA/OpenRA",name:"OpenRA",category:"Jeux",icon:"gamecontroller",aliases:[]),
        .init(repo:"endless-sky/endless-sky",name:"Endless Sky",category:"Jeux",icon:"gamecontroller",aliases:[]),
        .init(repo:"SuperTux/supertux",name:"SuperTux",category:"Jeux",icon:"gamecontroller",aliases:[]),
        .init(repo:"SuperTuxKart/stk-code",name:"SuperTuxKart",category:"Jeux",icon:"gamecontroller",aliases:[]),
        .init(repo:"wesnoth/wesnoth",name:"Battle for Wesnoth",category:"Jeux",icon:"gamecontroller",aliases:["Wesnoth"]),
        .init(repo:"warzone2100/warzone2100",name:"Warzone 2100",category:"Jeux",icon:"gamecontroller",aliases:[]),
        .init(repo:"ppy/osu",name:"osu!",category:"Jeux",icon:"gamecontroller",aliases:["osu"]),
        .init(repo:"PrismLauncher/PrismLauncher",name:"Prism Launcher",category:"Jeux",icon:"gamecontroller",aliases:[]),
        .init(repo:"godotengine/godot",name:"Godot Engine",category:"Jeux",icon:"gamecontroller",aliases:["Godot"]),
        .init(repo:"audacity/audacity",name:"Audacity",category:"Audio & musique",icon:"music.note",aliases:[]),
        .init(repo:"mixxxdj/mixxx",name:"Mixxx",category:"Audio & musique",icon:"music.note",aliases:[]),
        .init(repo:"LMMS/lmms",name:"LMMS",category:"Audio & musique",icon:"music.note",aliases:[]),
        .init(repo:"ankitects/anki",name:"Anki",category:"Éducation",icon:"book",aliases:[]),
        .init(repo:"zotero/zotero",name:"Zotero",category:"Éducation",icon:"book",aliases:[]),
        .init(repo:"KDE/krita",name:"Krita",category:"Graphisme",icon:"paintbrush",aliases:[]),
        .init(repo:"inkscape/inkscape",name:"Inkscape",category:"Graphisme",icon:"paintbrush",aliases:[]),
        .init(repo:"darktable-org/darktable",name:"darktable",category:"Graphisme",icon:"photo",aliases:[]),
        .init(repo:"brave/brave-browser",name:"Brave",category:"Internet",icon:"globe",aliases:["Brave Browser"]),
        .init(repo:"minbrowser/min",name:"Min Browser",category:"Internet",icon:"globe",aliases:["Min"]),
        .init(repo:"zen-browser/desktop",name:"Zen Browser",category:"Internet",icon:"globe",aliases:[]),
        .init(repo:"AppFlowy-IO/AppFlowy",name:"AppFlowy",category:"Bureautique",icon:"doc.text",aliases:[]),
        .init(repo:"laurent22/joplin",name:"Joplin",category:"Bureautique",icon:"doc.text",aliases:[]),
        .init(repo:"keepassxreboot/keepassxc",name:"KeePassXC",category:"Sécurité",icon:"lock",aliases:[]),
        .init(repo:"cryptomator/cryptomator",name:"Cryptomator",category:"Sécurité",icon:"lock",aliases:[]),
        .init(repo:"alt-tab-macos/alt-tab-macos",name:"AltTab",category:"Personnalisation",icon:"square.grid.2x2",aliases:[]),
        .init(repo:"pqrs-org/Karabiner-Elements",name:"Karabiner-Elements",category:"Personnalisation",icon:"keyboard",aliases:[]),
        .init(repo:"mac-mouse-fix/mac-mouse-fix",name:"Mac Mouse Fix",category:"Accessibilité",icon:"computermouse",aliases:[]),
        .init(repo:"dbeaver/dbeaver",name:"DBeaver",category:"Développement",icon:"externaldrive",aliases:[]),
        .init(repo:"sindresorhus/Plash",name:"Plash",category:"Personnalisation",icon:"desktopcomputer",aliases:[]),
        .init(repo:"voirfilm-tv/OrbiteStore",name:"OrbitStore",category:"Utilitaires",icon:"square.stack.3d.up.fill",aliases:["OrbiteStore"])
    ]
    static let categories = ["Tout", "Jeux", "Création", "Graphisme", "Audio & musique", "Multimédia", "Productivité", "Bureautique", "Éducation", "Développement", "Sécurité", "Réseau", "Internet", "Utilitaires", "Personnalisation", "Accessibilité"]
}

// Small pre-indexed GitHub catalog built by a scheduled server-side Action.
// An indexed item confirms the existence of a macOS *asset name* in an
// upstream release. It does not establish executable signature or trust.
struct IndexedMacApp: Decodable, Identifiable {
    let repo:String
    let name:String
    let category:String
    let summary:String
    let stars:Int
    let language:String?
    let license:String?
    let homepage:String?
    let updated_at:String?
    let release_tag:String
    let asset_name:String
    let verified_at:String
    var id:String { repo.lowercased() }
}
private struct MacCatalogIndex: Decodable {
    let schema:Int
    let generated_at:String?
    let count:Int
    let entries:[IndexedMacApp]
}

struct RepositoryInfo: Codable {
    let stargazers_count: Int
    let description: String?
    let html_url: String
    let default_branch: String?
    let homepage: String?
    let archived: Bool?
    let forks_count: Int?
    let language: String?
    let updated_at: String?
    let open_issues_count: Int?
    let license: LicenseInfo?
    struct LicenseInfo: Codable {
        let spdx_id: String?
        let name: String?
    }
}

struct ReleaseAsset: Decodable, Identifiable {
    let id: Int
    let name: String
    let browser_download_url: String
    let digest: String?
}
struct ReleaseInfo: Decodable {
    let tag_name: String
    let html_url: String
    let assets: [ReleaseAsset]
    let prerelease: Bool?
    let draft: Bool?
    let body: String?
    let published_at: String?
}

struct MacApp: Identifiable, Hashable {
    let path: String
    let name: String
    let version: String
    let bundleID: String
    var id: String { path }
}

struct Ecosystem: Identifiable {
    let id: String
    let name: String
    let keyword: [String]
    let url: String
    let description: String
}

enum Ecosystems {
    static let all: [Ecosystem] = [
        .init(id:"obsidian",name:"Obsidian",keyword:["obsidian"],url:"https://obsidian.md/plugins",description:"Plugins communautaires et thèmes"),
        .init(id:"obs",name:"OBS Studio",keyword:["obs studio","obs"],url:"https://obsproject.com/forum/resources/",description:"Plugins, sources et effets"),
        .init(id:"jellyfin",name:"Jellyfin",keyword:["jellyfin"],url:"https://jellyfin.org/docs/general/server/plugins/",description:"Plugins de serveur, clients et outils"),
        .init(id:"blender",name:"Blender",keyword:["blender"],url:"https://extensions.blender.org/",description:"Extensions et thèmes"),
        .init(id:"vscode",name:"Visual Studio Code",keyword:["visual studio code","code","vscodium"],url:"https://marketplace.visualstudio.com/vscode",description:"Extensions de développement"),
        .init(id:"firefox",name:"Firefox",keyword:["firefox"],url:"https://addons.mozilla.org/firefox/",description:"Extensions du navigateur"),
        .init(id:"chrome",name:"Google Chrome",keyword:["google chrome","chrome"],url:"https://chromewebstore.google.com/",description:"Extensions du navigateur"),
        .init(id:"figma",name:"Figma",keyword:["figma"],url:"https://www.figma.com/community/plugins",description:"Plugins et ressources"),
        .init(id:"photoshop",name:"Adobe Photoshop",keyword:["photoshop"],url:"https://exchange.adobe.com/",description:"Plugins Adobe")
    ]
    static func matches(_ appName: String) -> [Ecosystem] {
        let normalized = appName.lowercased()
        return all.filter { ecosystem in
            ecosystem.keyword.contains { term in
                normalized == term || (term.count >= 5 && normalized.contains(term))
            }
        }
    }
}

enum StoreError: LocalizedError {
    case badResponse
    case missingMacAsset
    case integrityCheck
    case rateLimited
    case httpStatus(Int)
    var errorDescription: String? {
        switch self {
        case .badResponse: return "La réponse du serveur est illisible."
        case .missingMacAsset: return "Ce dépôt ne fournit pas de paquet macOS identifié pour ce Mac."
        case .integrityCheck: return "Le fichier téléchargé ne correspond pas à son empreinte SHA-256."
        case .rateLimited: return "GitHub limite temporairement les requêtes. Réessaie plus tard."
        case .httpStatus(let code): return "Impossible de consulter les releases GitHub (HTTP \(code))."
        }
    }
}

enum MacReleaseAvailability {
    case checking
    case ready(tag: String, prerelease: Bool)
    case unavailable(String)
    case failed(String)
}

@MainActor
final class StoreModel: ObservableObject {
    @Published var installed: [MacApp] = []
    @Published private(set) var indexedApps:[IndexedMacApp] = []
    @Published private(set) var indexStatus = "Catalogue intégré"
    @Published private(set) var indexGeneratedAt:String?
    @Published private(set) var indexLoading = false
    private var indexByRepo:[String:IndexedMacApp] = [:]
    private let indexURL=URL(string:"https://raw.githubusercontent.com/voirfilm-tv/OrbiteStore/main/data/catalog-index.json")!

    // Single catalog for every native view, search match and update check.
    // Keep curated entries when the remote index is unavailable.
    var catalog:[CatalogApp] {
        let verified=Set(indexedApps.map{$0.repo.lowercased()})
        var curated=Inventory.catalog.filter { entry in
            let key=entry.repo.lowercased()
            // When a populated index is available, don't pretend that
            // unverified games are installable Mac games.
            if !indexedApps.isEmpty && entry.category=="Jeux" && !verified.contains(key) {
                return false
            }
            return true
        }
        let existing=Set(curated.map{$0.repo.lowercased()})
        for item in indexedApps where !existing.contains(item.repo.lowercased()) {
            let symbol=item.category=="Jeux" ? "gamecontroller.fill" :
                       (item.category=="Lanceurs & émulation" ? "arcade.stick" : "square.stack.3d.up")
            curated.append(CatalogApp(repo:item.repo,name:item.name,
                                      category:item.category,icon:symbol,aliases:[]))
        }
        // Override stale, manually categorized entries using indexed metadata.
        return curated.map { entry in
            guard let indexed=indexByRepo[entry.repo.lowercased()] else { return entry }
            if entry.category==indexed.category { return entry }
            return CatalogApp(repo:entry.repo,name:entry.name,category:indexed.category,
                              icon:entry.icon,aliases:entry.aliases)
        }
    }

    func catalogDescription(_ entry:CatalogApp)->String {
        let value=indexByRepo[entry.repo.lowercased()]?.summary
        return info[entry.repo]?.description ?? ((value?.isEmpty == false) ? value! : entry.repo)
    }
    func catalogStars(_ entry:CatalogApp)->Int {
        info[entry.repo]?.stargazers_count ?? indexByRepo[entry.repo.lowercased()]?.stars ?? 0
    }
    func catalogUpdatedAt(_ entry:CatalogApp)->String {
        indexByRepo[entry.repo.lowercased()]?.updated_at ?? ""
    }
    func catalogIsVerifiedMac(_ entry:CatalogApp)->Bool {
        indexByRepo[entry.repo.lowercased()] != nil
    }
    func catalogReleaseTag(_ entry:CatalogApp)->String? {
        indexByRepo[entry.repo.lowercased()]?.release_tag
    }
    func catalogLanguage(_ entry:CatalogApp)->String? {
        indexByRepo[entry.repo.lowercased()]?.language
    }
    func catalogIndexedLicense(_ entry:CatalogApp)->String? {
        indexByRepo[entry.repo.lowercased()]?.license
    }

    func loadIndexedCatalog(force:Bool=false) async {
        guard !indexLoading else { return }
        indexLoading=true
        defer { indexLoading=false }
        let cache=FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/OrbitStore/catalog-index.json")
        func accept(_ data:Data)->Bool {
            guard let value=try? JSONDecoder().decode(MacCatalogIndex.self,from:data),
                  value.schema==1,value.count==value.entries.count,
                  !value.entries.isEmpty,value.entries.count<=2500 else { return false }
            // Do not blindly trust malformed external repository identifiers.
            let items=value.entries.filter { entry in
                let parts=entry.repo.split(separator:"/")
                return parts.count==2 && !entry.name.isEmpty &&
                    entry.name.count<160 && entry.summary.count<=320 &&
                    !entry.asset_name.isEmpty && !entry.release_tag.isEmpty
            }
            guard !items.isEmpty else { return false }
            indexedApps=items
            indexByRepo=Dictionary(items.map{($0.repo.lowercased(),$0)},
                                   uniquingKeysWith:{old,_ in old})
            indexGeneratedAt=value.generated_at
            indexStatus="Catalogue indexé : \(items.count) logiciels macOS"
            return true
        }
        if let saved=try? Data(contentsOf:cache) { _=accept(saved) }
        let timestamp=UserDefaults.standard.object(forKey:"orbit.catalog.checkedAt") as? Date
        if !force, !indexedApps.isEmpty, let timestamp,
           Date().timeIntervalSince(timestamp)<6*3600 { return }
        do {
            var request=URLRequest(url:indexURL)
            request.setValue("OrbitStore/0.3 (macOS)",forHTTPHeaderField:"User-Agent")
            request.timeoutInterval=18
            let (data,response)=try await URLSession.shared.data(for:request)
            guard (response as? HTTPURLResponse)?.statusCode==200,accept(data) else {
                throw StoreError.badResponse
            }
            try FileManager.default.createDirectory(at:cache.deletingLastPathComponent(),
                                                    withIntermediateDirectories:true)
            try data.write(to:cache,options:.atomic)
            UserDefaults.standard.set(Date(),forKey:"orbit.catalog.checkedAt")
        } catch {
            indexStatus=indexedApps.isEmpty ?
                "Catalogue initial uniquement (index distant indisponible)" :
                "Index en cache · rafraîchissement indisponible"
        }
    }

    @Published var info: [String: RepositoryInfo] = [:]
    @Published var releases: [String: ReleaseInfo] = [:]
    @Published var releaseAvailability: [String: MacReleaseAvailability] = [:]
    @Published var downloading: Set<String> = []
    @Published var extensionCount: [String:Int] = [:]
    @Published var busy = false
    @Published var status = "Prêt"
    @Published var downloaded: [String:String] = [:]
    @Published var errors: [String:String] = [:]
    @Published var notificationsEnabled = false
    @Published var autoDownload = false

    private var hasInitialInventory = false
    private var timer: Timer?
    private var seen = Set<String>()
    private let decoder = JSONDecoder()

    func start() {
        guard timer == nil else { return }
        notificationsEnabled = UserDefaults.standard.bool(forKey:"orbit.notifications")
        autoDownload = UserDefaults.standard.bool(forKey:"orbit.autoDownloads")
        scan()
        timer = Timer.scheduledTimer(withTimeInterval:35, repeats:true) { [weak self] _ in
            Task { @MainActor in self?.scan() }
        }
        Task {
            await refresh()
            await loadObsidianCount()
        }
    }

    func setNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey:"orbit.notifications")
        if enabled { Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.badge,.sound]) } }
    }

    func setAutoDownload(_ enabled: Bool) {
        autoDownload = enabled
        UserDefaults.standard.set(enabled, forKey:"orbit.autoDownloads")
    }

    // Display names are not stable identifiers. In particular, the GitHub
    // repository "OrbiteStore" intentionally differs from the macOS app's
    // CFBundleDisplayName ("OrbitStore"). Known bundle IDs take priority.
    private let knownBundleIDs = [
        "voirfilm-tv/orbitestore": "fr.orbitstore.mac"
    ]

    func scan() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let roots: [URL] = [
            URL(fileURLWithPath:"/Applications",isDirectory:true),
            home.appendingPathComponent("Applications",isDirectory:true),
            URL(fileURLWithPath:"/System/Applications",isDirectory:true)
        ]
        var found: [MacApp] = []
        func add(_ candidate: URL) {
            let url = candidate.standardizedFileURL.resolvingSymlinksInPath()
            guard url.pathExtension.lowercased() == "app",
                  !url.path.hasPrefix("/Volumes/"),
                  !url.path.hasPrefix("/System/Volumes/"),
                  fm.fileExists(atPath:url.path),
                  let bundle=Bundle(url:url) else { return }
            let name=(bundle.object(forInfoDictionaryKey:"CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey:"CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent
            let version=(bundle.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String)
                ?? (bundle.object(forInfoDictionaryKey:"CFBundleVersion") as? String)
                ?? "?"
            found.append(MacApp(path:url.path,name:name,version:version,bundleID:bundle.bundleIdentifier ?? ""))
        }
        func walk(_ folder: URL, depth: Int) {
            guard let paths=try? fm.contentsOfDirectory(
                at:folder,includingPropertiesForKeys:[.isDirectoryKey],options:[.skipsHiddenFiles]
            ) else { return }
            for url in paths {
                if url.pathExtension.lowercased() == "app" {
                    add(url)
                } else if depth > 0,
                          (try? url.resourceValues(forKeys:[.isDirectoryKey]).isDirectory) == true {
                    walk(url,depth:depth-1)
                }
            }
        }
        // Standard installations and common subfolders (e.g. Setapp).
        roots.forEach { walk($0,depth:2) }

        // LaunchServices can resolve applications that were moved by the user.
        // Running apps may also live in non-standard folders. Exclude mounted
        // disk images: opening a DMG alone does not mean the app is installed.
        if let registered=NSWorkspace.shared.urlForApplication(withBundleIdentifier:"fr.orbitstore.mac") {
            add(registered)
        }
        let ownURL=Bundle.main.bundleURL
        if ownURL.pathExtension.lowercased() == "app" { add(ownURL) }
        for process in NSWorkspace.shared.runningApplications {
            if let url=process.bundleURL { add(url) }
        }

        let unique=Dictionary(grouping:found,by:\.path).compactMap { $0.value.first }
        let current=unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let added=current.filter { !seen.contains($0.path) }
        seen=Set(current.map(\.path))
        installed=current

        if hasInitialInventory && notificationsEnabled {
            // A small batch prevents an API flood after a software update.
            for app in added.prefix(3) {
                Task {
                    if let ecosystem=Ecosystems.matches(app.name).first {
                        if let records=try? await PluginDirectory.load(ecosystem) {
                            extensionCount[ecosystem.id]=records.count
                            if !records.isEmpty {
                                notify("Extensions disponibles pour \(app.name)",
                                       body:"\(records.count) ressources trouvées. Compatibilité à vérifier.")
                            }
                        }
                    } else if let records=try? await PluginDirectory.relatedToUnknownApp(app.name),
                              !records.isEmpty {
                        notify("Projets associés à \(app.name)",
                               body:"\(records.count) projets trouvés sur GitHub. Compatibilité non vérifiée.")
                    }
                }
            }
        }
        hasInitialInventory=true
    }

    private func normalizedAppName(_ value: String) -> String {
        let folded=value.folding(options:[.diacriticInsensitive,.caseInsensitive],locale:Locale(identifier:"en_US_POSIX"))
        return String(folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    func matches(_ entry:CatalogApp) -> [MacApp] {
        let repoKey=entry.repo.lowercased()
        let knownID=knownBundleIDs[repoKey]
        let allowed=Set(([entry.name] + entry.aliases).map(normalizedAppName))
        return installed.filter { app in
            if let id=knownID, app.bundleID.caseInsensitiveCompare(id) == .orderedSame { return true }
            // Exact normalized alias is a discovery hint, not a trusted
            // publisher identity for automatic installation/update.
            return allowed.contains(normalizedAppName(app.name))
        }
    }

    func downloadedFile(for entry:CatalogApp) -> URL? {
        let saved=downloaded[entry.repo] ?? UserDefaults.standard.string(forKey:"download.\(entry.repo)")
        guard let path=saved, FileManager.default.fileExists(atPath:path) else { return nil }
        let file=URL(fileURLWithPath:path)
        // Do not present last month's DMG as the current release.
        if let release=releases[entry.repo],
           let latest=suitableMacAsset(for:release),
           file.lastPathComponent != latest.name { return nil }
        return file
    }

    func revealDownloaded(_ entry:CatalogApp) {
        guard let file=downloadedFile(for:entry) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([file])
    }

    func openDownloaded(_ entry:CatalogApp) {
        guard let file=downloadedFile(for:entry) else { return }
        // Never execute an unverified PKG, script, or binary.
        let suffix=file.pathExtension.lowercased()
        guard suffix == "dmg" || suffix == "zip" else {
            revealDownloaded(entry)
            return
        }
        if NSWorkspace.shared.open(file) {
            status=suffix == "dmg"
                ? "Image disque ouverte : glisse l'application vers Applications, puis vérifie sa détection."
                : "Archive ouverte : vérifie le logiciel avant de l'installer."
        } else {
            errors[entry.repo]="macOS n'a pas pu ouvrir ce fichier. Affiche-le dans le Finder."
        }
    }

    func refresh() async {
        guard !busy else { return }
        busy=true
        defer { busy=false; status="Catalogue actualisé" }
        status="Chargement du catalogue…"
        await loadIndexedCatalog(force:true)
        // The public index already provides stars and descriptions for hundreds
        // of repos. Fetch details only for a small curated fallback, not every
        // app on every startup (unauthenticated GitHub limit: 60 req/hour).
        for entry in Inventory.catalog.prefix(6) where indexByRepo[entry.repo.lowercased()] == nil {
            do {
                let key=entry.repo.replacingOccurrences(of:"/",with:"_")
                if let data=UserDefaults.standard.data(forKey:"repo."+key),
                   let cached=try? decoder.decode(RepositoryInfo.self,from:data) {
                    info[entry.repo]=cached
                } else {
                    let (data,response)=try await github("repos/"+entry.repo)
                    guard (response as? HTTPURLResponse)?.statusCode==200,
                          let decoded=try? decoder.decode(RepositoryInfo.self,from:data) else {continue}
                    info[entry.repo]=decoded
                    UserDefaults.standard.set(data,forKey:"repo."+key)
                }
            } catch {}
        }
        await checkUpdates()
    }

    func checkUpdates() async {
        status = "Recherche des mises à jour…"
        let active=catalog.filter { !matches($0).isEmpty }
        for entry in active {
            await checkDownloadAvailability(entry,force:true)
            guard let release=releases[entry.repo],
                  isNewer(release.tag_name,than:matches(entry).first?.version ?? "?") else { continue }
            // Never auto-download for a display-name-only match. A renamed
            // unrelated app must not be offered a foreign binary automatically.
            if let known=knownBundleIDs[entry.repo.lowercased()],
               matches(entry).contains(where: { $0.bundleID.caseInsensitiveCompare(known) == .orderedSame }),
               autoDownload {
                await download(entry,release:release)
            }
        }
        status = "Vérification terminée"
    }

    private func github(_ path:String) async throws -> (Data,URLResponse) {
        guard let url = URL(string:"https://api.github.com/" + path) else { throw StoreError.badResponse }
        var req = URLRequest(url:url)
        req.setValue("application/vnd.github+json",forHTTPHeaderField:"Accept")
        req.setValue("OrbitStore/0.1 (macOS)",forHTTPHeaderField:"User-Agent")
        req.timeoutInterval = 20
        return try await URLSession.shared.data(for:req)
    }

    func loadObsidianCount() async {
        guard let url = URL(string:"https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json") else { return }
        do {
            let (data,_) = try await URLSession.shared.data(from:url)
            if let items = try JSONSerialization.jsonObject(with:data) as? [[String:Any]] {
                extensionCount["obsidian"] = items.count
            }
        } catch { }
    }

    private func isNewer(_ candidate:String,than installed:String) -> Bool {
        func parts(_ s:String)->[Int] {
            s.split(whereSeparator:{ !$0.isNumber }).prefix(4).compactMap { Int($0) }
        }
        let a = parts(candidate), b = parts(installed)
        guard !a.isEmpty && !b.isEmpty else { return false }
        for i in 0..<max(a.count,b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    func updateAvailable(_ entry:CatalogApp) -> Bool {
        guard let r = releases[entry.repo], let installedVersion = matches(entry).first?.version else { return false }
        return isNewer(r.tag_name,than:installedVersion)
    }

    // GitHub /releases/latest deliberately omits pre-releases. Use the actual
    // release list, find a macOS artifact, and don't promise a download until
    // the package has been identified for this Mac.
    func checkDownloadAvailability(_ entry: CatalogApp, force: Bool = false) async {
        if !force && releaseAvailability[entry.repo] != nil { return }
        releaseAvailability[entry.repo] = .checking
        errors.removeValue(forKey:entry.repo)
        do {
            let (data, response) = try await github("repos/" + entry.repo + "/releases?per_page=15")
            guard let http = response as? HTTPURLResponse else { throw StoreError.badResponse }
            if http.statusCode == 403 || http.statusCode == 429 { throw StoreError.rateLimited }
            guard http.statusCode == 200 else { throw StoreError.httpStatus(http.statusCode) }
            let found = try decoder.decode([ReleaseInfo].self, from:data)
            if let match = found.first(where: { $0.draft != true && suitableMacAsset(for: $0) != nil }) {
                releases[entry.repo] = match
                releaseAvailability[entry.repo] = .ready(tag:match.tag_name,prerelease:match.prerelease == true)
            } else {
                releases.removeValue(forKey:entry.repo)
                releaseAvailability[entry.repo] = .unavailable(
                    "Aucun paquet macOS adapté n'est publié dans les releases GitHub consultées. Ce dépôt peut contenir uniquement du code source."
                )
            }
        } catch {
            releases.removeValue(forKey:entry.repo)
            releaseAvailability[entry.repo] = .failed(error.localizedDescription)
        }
    }

    // A generic .zip can contain sources or another OS binary. Never assume
    // it's a macOS application unless the asset name indicates macOS.
    private func suitableMacAsset(for release: ReleaseInfo) -> ReleaseAsset? {
        let isArm = ProcessInfo.processInfo.machineHardwareName.contains("arm")
        func score(_ asset: ReleaseAsset) -> Int? {
            let n = asset.name.lowercased()
            guard !n.contains("windows"), !n.contains("win32"),
                  !n.contains("linux"), !n.contains("android"),
                  !n.contains("source"), !n.contains("src-"),
                  !n.contains("symbols"), !n.contains("debug") else { return nil }
            let macHint = n.contains("mac") || n.contains("darwin") || n.contains("osx")
            let typeScore: Int
            if n.hasSuffix(".dmg") { typeScore = 80 }
            else if n.hasSuffix(".pkg") { typeScore = 70 }
            else if n.hasSuffix(".zip") && macHint { typeScore = 50 }
            else { return nil }
            if isArm && (n.contains("x86_64") || n.contains("x64") || n.contains("intel") || n.contains("amd64")) &&
               !n.contains("universal") { return nil }
            if !isArm && (n.contains("arm64") || n.contains("aarch64") || n.contains("apple-silicon")) &&
               !n.contains("universal") { return nil }
            let native = isArm ? (n.contains("arm64") || n.contains("aarch64")) :
                                 (n.contains("x86_64") || n.contains("intel"))
            return typeScore + (native ? 20 : 0) + (n.contains("universal") ? 10 : 0) + (macHint ? 5 : 0)
        }
        return release.assets.compactMap { asset -> (ReleaseAsset, Int)? in
            guard let score = score(asset) else { return nil }
            return (asset, score)
        }.sorted { $0.1 > $1.1 }.first?.0
    }

    // Installer service: obtain a package without opening Finder or executing it.
    // The caller must perform macOS validation before placing the .app.
    func acquirePackage(_ entry: CatalogApp) async -> URL? {
        if releaseAvailability[entry.repo] == nil {
            await checkDownloadAvailability(entry)
        }
        guard case .ready = releaseAvailability[entry.repo],
              let release=releases[entry.repo] else {
            errors[entry.repo]=StoreError.missingMacAsset.localizedDescription
            return nil
        }
        if let existing=downloadedFile(for:entry) { return existing }
        await download(entry,release:release,revealAfterDownload:false)
        return downloadedFile(for:entry)
    }

    func installCandidate(_ entry: CatalogApp) async {
        if releaseAvailability[entry.repo] == nil {
            await checkDownloadAvailability(entry)
        }
        guard case .ready = releaseAvailability[entry.repo],
              let release = releases[entry.repo] else {
            status = "Aucun téléchargement macOS vérifié pour ce dépôt."
            return
        }
        await download(entry,release:release,revealAfterDownload:true)
    }

    private func download(_ app: CatalogApp, release: ReleaseInfo, revealAfterDownload: Bool = false) async {
        guard let chosen = suitableMacAsset(for:release),
              let url = URL(string:chosen.browser_download_url),
              url.scheme == "https", url.host == "github.com" else {
            errors[app.repo] = StoreError.missingMacAsset.localizedDescription
            return
        }
        guard !downloading.contains(app.repo) else { return }
        downloading.insert(app.repo)
        defer { downloading.remove(app.repo) }
        errors.removeValue(forKey:app.repo)
        do {
            status = "Téléchargement de \(app.name)…"
            let (temporary,response) = try await URLSession.shared.download(from:url)
            guard let http = response as? HTTPURLResponse else { throw StoreError.badResponse }
            guard http.statusCode == 200 else { throw StoreError.httpStatus(http.statusCode) }
            if let digest = chosen.digest, digest.hasPrefix("sha256:") {
                let data = try Data(contentsOf:temporary)
                let actual = SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()
                guard actual.lowercased() == String(digest.dropFirst(7)).lowercased() else {
                    throw StoreError.integrityCheck
                }
            }
            let folder = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/OrbitStore",isDirectory:true)
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let target = folder.appendingPathComponent(chosen.name)
            if FileManager.default.fileExists(atPath:target.path) {
                try FileManager.default.removeItem(at:target)
            }
            try FileManager.default.moveItem(at:temporary,to:target)
            downloaded[app.repo] = target.path
            UserDefaults.standard.set(target.path,forKey:"download.\(app.repo)")
            if revealAfterDownload && target.pathExtension.lowercased() == "dmg" {
                // Mount the downloaded disk image via Finder, not the .app.
                // No executable, installer, or elevated command is launched.
                if NSWorkspace.shared.open(target) {
                    status = "DMG ouvert : déplace l'application dans Applications, puis relance l'analyse."
                } else {
                    NSWorkspace.shared.activateFileViewerSelecting([target])
                    status = "DMG téléchargé : ouvre-le manuellement depuis le Finder."
                }
            } else {
                if revealAfterDownload {
                    NSWorkspace.shared.activateFileViewerSelecting([target])
                }
                status = "Paquet téléchargé : vérifie son éditeur et installe-le depuis le Finder."
            }
        } catch {
            errors[app.repo] = error.localizedDescription
            status = "Échec du téléchargement"
        }
    }

    private func notify(_ title:String,body:String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        Task { try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier:UUID().uuidString,content:content,trigger:nil)
        ) }
    }
}

private extension ProcessInfo {
    var machineHardwareName:String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to:&sysinfo.machine) { ptr in
            ptr.withMemoryRebound(to:CChar.self,capacity:1) { String(cString:$0) }
        }
    }
}
