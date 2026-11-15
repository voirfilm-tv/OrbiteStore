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
        .init(repo:"sindresorhus/Plash",name:"Plash",category:"Personnalisation",icon:"desktopcomputer",aliases:[])
    ]
    static let categories = ["Tout", "Jeux", "Création", "Graphisme", "Audio & musique", "Multimédia", "Productivité", "Bureautique", "Éducation", "Développement", "Sécurité", "Réseau", "Internet", "Utilitaires", "Personnalisation", "Accessibilité"]
}

struct RepositoryInfo: Codable {
    let stargazers_count: Int
    let description: String?
    let html_url: String
    let default_branch: String?
    let archived: Bool?
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
    var errorDescription: String? {
        switch self {
        case .badResponse: return "Réponse réseau invalide"
        case .missingMacAsset: return "Aucun paquet macOS adapté n'a été identifié"
        case .integrityCheck: return "L'empreinte du fichier téléchargé ne correspond pas"
        }
    }
}

@MainActor
final class StoreModel: ObservableObject {
    @Published var installed: [MacApp] = []
    @Published var info: [String: RepositoryInfo] = [:]
    @Published var releases: [String: ReleaseInfo] = [:]
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

    func scan() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let roots = [URL(fileURLWithPath:"/Applications"),home.appendingPathComponent("Applications"),URL(fileURLWithPath:"/System/Applications")]
        var found: [MacApp] = []
        func walk(_ folder:URL, depth:Int) {
            guard let paths = try? fm.contentsOfDirectory(at:folder, includingPropertiesForKeys:[.isDirectoryKey], options:[.skipsHiddenFiles]) else { return }
            for path in paths {
                if path.pathExtension.lowercased() == "app" {
                    let bundle = Bundle(url:path)
                    let name = (bundle?.object(forInfoDictionaryKey:"CFBundleDisplayName") as? String)
                        ?? (bundle?.object(forInfoDictionaryKey:"CFBundleName") as? String)
                        ?? path.deletingPathExtension().lastPathComponent
                    let version = (bundle?.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String)
                        ?? (bundle?.object(forInfoDictionaryKey:"CFBundleVersion") as? String) ?? "?"
                    found.append(MacApp(path:path.path,name:name,version:version,bundleID:bundle?.bundleIdentifier ?? ""))
                } else if depth > 0 {
                    walk(path,depth:depth-1)
                }
            }
        }
        roots.forEach { walk($0,depth:1) }
        let unique = Dictionary(grouping:found,by:\.path).compactMap { $0.value.first }
        let current = unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let added = current.filter { !seen.contains($0.path) }
        seen = Set(current.map(\.path))
        installed = current
        if hasInitialInventory && notificationsEnabled {
            for app in added {
                let ecosystem = Ecosystems.matches(app.name)
                if let first = ecosystem.first, let count = extensionCount[first.id], count > 0 {
                    notify("Extensions disponibles pour \(app.name)",body:"\(count) ressources recensées dans le catalogue \(first.name). Vérifie leur compatibilité avant installation.")
                }
            }
        }
        hasInitialInventory = true
    }

    func matches(_ entry:CatalogApp) -> [MacApp] {
        installed.filter { installedApp in
            [entry.name] + entry.aliases == [] ? false :
            ([entry.name] + entry.aliases).contains { alias in
                installedApp.name.caseInsensitiveCompare(alias) == .orderedSame
            }
        }
    }

    func refresh() async {
        guard !busy else { return }
        busy = true
        defer { busy = false; status = "Catalogue actualisé" }
        status = "Actualisation GitHub…"
        for entry in Inventory.catalog {
            do {
                let key = entry.repo.replacingOccurrences(of:"/",with:"_")
                if let cache = UserDefaults.standard.data(forKey:"repo." + key),
                   let date = UserDefaults.standard.object(forKey:"repoDate." + key) as? Date,
                   Date().timeIntervalSince(date) < 7200,
                   let cached = try? decoder.decode(RepositoryInfo.self,from:cache) {
                    info[entry.repo] = cached
                } else {
                    let (data, response) = try await github("repos/" + entry.repo)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
                    let decoded = try decoder.decode(RepositoryInfo.self,from:data)
                    info[entry.repo] = decoded
                    UserDefaults.standard.set(data,forKey:"repo." + key)
                    UserDefaults.standard.set(Date(),forKey:"repoDate." + key)
                }
            } catch { errors[entry.repo] = error.localizedDescription }
        }
        await checkUpdates()
    }

    func checkUpdates() async {
        status = "Recherche des mises à jour…"
        let active = Inventory.catalog.filter { !matches($0).isEmpty }
        for entry in active {
            do {
                let (data, response) = try await github("repos/" + entry.repo + "/releases/latest")
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
                let release = try decoder.decode(ReleaseInfo.self,from:data)
                releases[entry.repo] = release
                if autoDownload && isNewer(release.tag_name,than:matches(entry).first?.version ?? "?") {
                    await download(entry,release:release)
                }
            } catch { errors[entry.repo] = error.localizedDescription }
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

    func installCandidate(_ entry:CatalogApp) async {
        status = "Vérification de la version…"
        do {
            let release: ReleaseInfo
            if let existing = releases[entry.repo] { release = existing }
            else {
                let (data,response) = try await github("repos/" + entry.repo + "/releases/latest")
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw StoreError.badResponse }
                release = try decoder.decode(ReleaseInfo.self,from:data)
                releases[entry.repo] = release
            }
            await download(entry,release:release)
        } catch {
            errors[entry.repo] = error.localizedDescription
            status = "Téléchargement impossible"
        }
    }

    private func download(_ app:CatalogApp,release:ReleaseInfo) async {
        let candidates = release.assets.filter {
            let n = $0.name.lowercased()
            return (n.hasSuffix(".dmg") || n.hasSuffix(".zip") || n.hasSuffix(".pkg"))
                && !n.contains("windows") && !n.contains("win32") && !n.contains("linux")
        }
        let isArm = ProcessInfo.processInfo.machineHardwareName.contains("arm")
        let matching = candidates.filter { asset in
            let n = asset.name.lowercased()
            if isArm { return !n.contains("x86_64") && !n.contains("intel") && !n.contains("amd64") }
            return !n.contains("arm64") && !n.contains("aarch64")
        }
        guard let chosen = matching.first(where:{ $0.name.lowercased().hasSuffix(".dmg") }) ?? matching.first,
              let url = URL(string:chosen.browser_download_url),
              url.scheme == "https", url.host == "github.com" else {
            errors[app.repo] = StoreError.missingMacAsset.localizedDescription
            return
        }
        do {
            status = "Téléchargement de \(app.name)…"
            let (temporary,response) = try await URLSession.shared.download(from:url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw StoreError.badResponse }
            if let digest = chosen.digest, digest.hasPrefix("sha256:") {
                let data = try Data(contentsOf:temporary)
                let actual = SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()
                guard actual.lowercased() == String(digest.dropFirst(7)).lowercased() else { throw StoreError.integrityCheck }
            }
            let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/OrbitStore",isDirectory:true)
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let target = folder.appendingPathComponent(chosen.name)
            if FileManager.default.fileExists(atPath:target.path) { try FileManager.default.removeItem(at:target) }
            try FileManager.default.moveItem(at:temporary,to:target)
            downloaded[app.repo] = target.path
            status = "Fichier enregistré dans Téléchargements/OrbitStore"
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
