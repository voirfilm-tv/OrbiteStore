import SwiftUI
import AppKit
import Foundation

// GitHub is a discovery source, not a guarantee that a repository ships a macOS application.
struct GitHubHit: Decodable, Identifiable {
    let id: Int
    let full_name: String
    let name: String
    let description: String?
    let stargazers_count: Int
    let html_url: String
    let archived: Bool
    let default_branch: String?
    let homepage: String?
    let language: String?
    let license: LicenseInfo?
    struct LicenseInfo: Decodable { let spdx_id: String? }
}
private struct SearchPayload: Decodable {
    let total_count: Int
    let items: [GitHubHit]
}

enum MarketplaceNetworkError: LocalizedError {
    case status(Int), limited, malformed, missing
    var errorDescription: String? {
        switch self {
        case .status(let code): return "GitHub a répondu avec le code HTTP \(code)."
        case .limited: return "Limite de requêtes GitHub atteinte. Réessaie dans quelques minutes."
        case .malformed: return "Données du catalogue impossibles à lire."
        case .missing: return "Ressource introuvable."
        }
    }
}

enum MarketplaceHTTP {
    static func fetch(_ url: URL, accept: String = "application/vnd.github+json") async throws -> Data {
        guard url.scheme == "https" else { throw MarketplaceNetworkError.malformed }
        var request = URLRequest(url: url)
        request.setValue("OrbitStore/0.2 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.timeoutInterval = 18
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MarketplaceNetworkError.malformed }
        if http.statusCode == 403 || http.statusCode == 429 { throw MarketplaceNetworkError.limited }
        guard (200..<300).contains(http.statusCode) else { throw MarketplaceNetworkError.status(http.statusCode) }
        return data
    }

    static func search(_ query: String, limit: Int = 30) async throws -> [GitHubHit] {
        var parts = URLComponents(string: "https://api.github.com/search/repositories")!
        parts.queryItems = [
            URLQueryItem(name: "q", value: "\(query) in:name,description,readme archived:false"),
            URLQueryItem(name: "per_page", value: String(limit))
        ]
        guard let url = parts.url else { throw MarketplaceNetworkError.malformed }
        return try JSONDecoder().decode(SearchPayload.self, from: try await fetch(url)).items
    }

    static func pluginSearch(_ q: String) async throws -> [PluginRecord] {
        var parts = URLComponents(string: "https://api.github.com/search/repositories")!
        parts.queryItems = [
            URLQueryItem(name: "q", value: "\(q) archived:false"),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "40")
        ]
        guard let url = parts.url else { throw MarketplaceNetworkError.malformed }
        let hits = try JSONDecoder().decode(SearchPayload.self, from: try await fetch(url)).items
        return hits.map {
            PluginRecord(id: $0.full_name, name: $0.name, summary: $0.description ?? "Dépôt GitHub communautaire",
                         url: $0.html_url, compatibility: "Non vérifiée", source: "Projet GitHub associé",
                         stars: $0.stargazers_count)
        }
    }
}

@MainActor
final class GitHubDiscovery: ObservableObject {
    @Published var results: [GitHubHit] = []
    @Published var loading = false
    @Published var error: String?
    @Published var lastQuery = ""
    private var cached: [String: [GitHubHit]] = [:]

    func search(_ raw: String) async {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.count < 2 {
            loading = false; results = []; error = nil; lastQuery = ""
            return
        }
        if let previous = cached[term.lowercased()] {
            results = previous; lastQuery = term; error = nil; loading = false
            return
        }
        loading = true; error = nil; lastQuery = term
        do {
            let hits = try await MarketplaceHTTP.search(term)
            guard !Task.isCancelled else { return }
            results = hits
            cached[term.lowercased()] = hits
            error = nil
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct PluginRecord: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let url: String
    let compatibility: String
    let source: String
    let stars: Int?
}

enum PluginDirectory {
    static func relatedToUnknownApp(_ appName: String) async throws -> [PluginRecord] {
        let cleaned = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 3 && cleaned.count <= 60 else { return [] }
        return try await MarketplaceHTTP.pluginSearch("\"\(cleaned)\" plugin in:name,description")
    }
    static func load(_ ecosystem: Ecosystem) async throws -> [PluginRecord] {
        switch ecosystem.id {
        case "obsidian":
            let url = URL(string: "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/community-plugins.json")!
            struct Item: Decodable { let id: String; let name: String; let author: String?; let description: String?; let repo: String }
            let items = try JSONDecoder().decode([Item].self, from: try await MarketplaceHTTP.fetch(url))
            return items.map {
                PluginRecord(id: $0.id, name: $0.name, summary: $0.description ?? "Par \($0.author ?? "la communauté")",
                             url: "https://github.com/\($0.repo)", compatibility: "Vérifier la version installée", source: "Registre officiel Obsidian", stars: nil)
            }
        case "jellyfin":
            let url = URL(string: "https://repo.jellyfin.org/files/plugin/manifest.json")!
            struct Version: Decodable { let version: String?; let targetAbi: String? }
            struct Item: Decodable {
                let name: String
                let guid: String?
                let overview: String?
                let description: String?
                let owner: String?
                let versions: [Version]?
            }
            let items = try JSONDecoder().decode([Item].self, from: try await MarketplaceHTTP.fetch(url))
            return items.map {
                let abi = $0.versions?.compactMap(\.targetAbi).first
                let compatibility = abi.map { "API serveur Jellyfin \($0)" } ?? "Version serveur à confirmer"
                let website = $0.owner?.hasPrefix("https://") == true ? $0.owner! : "https://jellyfin.org/docs/general/server/plugins/"
                return PluginRecord(id: $0.guid ?? $0.name, name: $0.name,
                                    summary: $0.overview ?? $0.description ?? "Extension pour Jellyfin Server",
                                    url: website, compatibility: compatibility,
                                    source: "Registre Jellyfin Server", stars: nil)
            }
        case "obs":
            return try await MarketplaceHTTP.pluginSearch("obs-studio plugin in:name,description")
        case "blender":
            return try await MarketplaceHTTP.pluginSearch("blender addon in:name,description")
        case "vscode":
            return try await MarketplaceHTTP.pluginSearch("vscode extension in:name,description")
        case "firefox":
            return try await MarketplaceHTTP.pluginSearch("firefox addon in:name,description")
        case "chrome":
            return try await MarketplaceHTTP.pluginSearch("chrome extension in:name,description")
        case "figma":
            return try await MarketplaceHTTP.pluginSearch("figma plugin in:name,description")
        case "photoshop":
            return try await MarketplaceHTTP.pluginSearch("photoshop plugin in:name,description")
        default:
            return []
        }
    }
}

// Authentic icons: installed .app icons first, then imagery referenced by the
// project's README. We never replace unknown branding with a made-up app icon.
actor RepositoryLogoService {
    static let shared = RepositoryLogoService()
    private var cache: [String: Data] = [:]
    private var unavailable = Set<String>()

    func imageData(repo: String, branch: String?, homepage: String?) async -> Data? {
        if let existing = cache[repo] { return existing }
        let lookupKey = repo + "|" + (homepage ?? "")
        if unavailable.contains(lookupKey) { return nil }
        guard repo.split(separator: "/").count == 2 else { return nil }
        let bases = [branch ?? "main", "main", "master"]
        for base in Array(Set(bases)) {
            let readmeURL = URL(string: "https://raw.githubusercontent.com/\(repo)/\(base)/README.md")!
            guard let markdownData = try? await MarketplaceHTTP.fetch(readmeURL, accept: "text/plain"),
                  let markdown = String(data: markdownData, encoding: .utf8) else { continue }
            let candidates = Self.logoCandidates(markdown: markdown, repo: repo, branch: base)
            for url in candidates.prefix(5) {
                guard let imageData = try? await MarketplaceHTTP.fetch(url, accept: "image/*"),
                      imageData.count < 4_000_000,
                      NSImage(data: imageData) != nil else { continue }
                cache[repo] = imageData
                return imageData
            }
        }
        if let homepageURL = URL(string: homepage ?? ""), homepageURL.scheme == "https",
           let host = homepageURL.host, host != "github.com",
           !host.hasSuffix(".github.com") {
            var parts = URLComponents()
            parts.scheme = "https"
            parts.host = host
            for iconPath in ["/apple-touch-icon.png", "/favicon.png", "/favicon.ico"] {
                parts.path = iconPath
                guard let iconURL = parts.url,
                      let data = try? await MarketplaceHTTP.fetch(iconURL, accept: "image/*"),
                      data.count < 2_000_000,
                      NSImage(data: data) != nil else { continue }
                cache[repo] = data
                return data
            }
        }
        unavailable.insert(lookupKey)
        return nil
    }

    private static func logoCandidates(markdown: String, repo: String, branch: String) -> [URL] {
        let pattern = #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+[^)]*)?\)|<img[^>]*src=["']([^"']+)["'][^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        let matches = regex.matches(in: markdown, range: range).prefix(100)
        var scored: [(URL, Int)] = []
        for match in matches {
            let entire = String(markdown[Range(match.range, in: markdown)!])
            let candidate = [2, 3].compactMap { i -> String? in
                guard match.range(at: i).location != NSNotFound,
                      let r = Range(match.range(at: i), in: markdown) else { return nil }
                return String(markdown[r])
            }.first
            guard let candidate, !candidate.lowercased().hasPrefix("data:") else { continue }
            let lower = (entire + candidate).lowercased()
            guard lower.contains("logo") || lower.contains("icon") || lower.contains("appicon") || lower.contains("brand") else { continue }
            guard !lower.contains("badge") && !lower.contains("shields.io") && !lower.contains("screenshot") else { continue }
            let url: URL?
            if let direct = URL(string: candidate), direct.scheme == "https" {
                url = direct
            } else {
                let cleaned = candidate.replacingOccurrences(of: "./", with: "", options: [.anchored])
                url = URL(string: "https://raw.githubusercontent.com/\(repo)/\(branch)/\(cleaned)")
            }
            guard let url, url.scheme == "https" else { continue }
            let file = url.path.lowercased()
            guard [".png",".jpg",".jpeg",".webp",".gif",".ico",".icns"].contains(where: file.hasSuffix) else { continue }
            let score = (lower.contains("appicon") ? 10 : 0) + (lower.contains("logo") ? 5 : 0)
            scored.append((url,score))
        }
        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }
}

struct AuthenticAppIcon: View {
    let repo: String
    let name: String
    var installedPath: String? = nil
    var branch: String? = nil
    var homepage: String? = nil
    var size: CGFloat = 60
    @State private var remote: NSImage?

    private var lookupKey: String {
        [repo, branch ?? "", homepage ?? ""].joined(separator: "|")
    }

    @ViewBuilder
    private var graphic: some View {
        if let path = installedPath {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .scaledToFit()
        } else if let image = remote {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        graphic
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.10))
            )
            .task(id: lookupKey) {
                guard installedPath == nil else { return }
                let data = await RepositoryLogoService.shared.imageData(
                    repo: repo, branch: branch, homepage: homepage
                )
                if let data { remote = NSImage(data: data) }
            }
    }
}

struct ExtensionBrowser: View {
    let ecosystem: Ecosystem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreModel
    @EnvironmentObject private var operations: OrbitOperations
    @State private var installPlugin: PluginRecord?
    @State private var installVault: URL?
    @State private var showInstallWarning=false
    @State private var records: [PluginRecord] = []
    @State private var loading = true
    @State private var error: String?
    @State private var query = ""
    @State private var pluginSort = "Nom A–Z"
    @State private var pluginFilter = "Toutes"
    private var filtered: [PluginRecord] {
        var items=records.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) ||
                $0.summary.localizedCaseInsensitiveContains(query)
        }
        if pluginFilter == "Registres officiels" {
            items=items.filter { $0.source.hasPrefix("Registre") }
        } else if pluginFilter == "Projets GitHub" {
            items=items.filter { $0.source.contains("GitHub") }
        } else if pluginFilter == "Avec étoiles" {
            items=items.filter { $0.stars != nil }
        }
        if pluginSort == "★ GitHub" {
            items.sort { ($0.stars ?? -1) > ($1.stars ?? -1) }
        } else if pluginSort == "Nom Z–A" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        } else {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return items
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extensions · \(ecosystem.name)").font(.title.bold())
                    Text("Catalogue intégré · \(records.count) résultats · compatibilité à vérifier pour chaque version")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2) }.buttonStyle(.plain)
            }
            TextField("Rechercher dans les extensions…", text: $query)
                .textFieldStyle(.roundedBorder)
            HStack(spacing:10) {
                Label("Filtres",systemImage:"line.3.horizontal.decrease")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Source",selection:$pluginFilter) {
                    Text("Toutes").tag("Toutes")
                    Text("Registres officiels").tag("Registres officiels")
                    Text("Projets GitHub").tag("Projets GitHub")
                    Text("Avec étoiles").tag("Avec étoiles")
                }.pickerStyle(.menu).frame(width:180)
                Picker("Trier",selection:$pluginSort) {
                    Text("Nom A–Z").tag("Nom A–Z")
                    Text("Nom Z–A").tag("Nom Z–A")
                    Text("★ GitHub").tag("★ GitHub")
                }.pickerStyle(.menu).frame(width:150)
                Spacer()
                Text("\(filtered.count) affichés")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if loading {
                ProgressView("Récupération du catalogue…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                VStack(spacing: 12) {
                    Text(error).foregroundStyle(.orange)
                    Button("Réessayer") { Task { await reload() } }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filtered.isEmpty {
                VStack(spacing: 12) { Image(systemName: "puzzlepiece.extension").font(.largeTitle); Text("Aucun résultat"); Text("Essaie une autre recherche.").font(.caption) }
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(filtered.prefix(180))) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "puzzlepiece.extension")
                                    .frame(width: 40, height: 40)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.headline)
                                    Text(item.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    Text("\(item.source) · \(item.compatibility)").font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer(minLength: 8)
                                if let stars = item.stars {
                                    Label(stars.formatted(), systemImage: "star.fill").font(.caption)
                                }
                                if let url = URL(string: item.url), url.scheme == "https" {
                                    Button("Source") { NSWorkspace.shared.open(url) }.buttonStyle(.bordered)
                                }
                                if ecosystem.id == "obsidian",
                                   item.source == "Registre officiel Obsidian",
                                   let app = store.installed.first(where: { $0.name.localizedCaseInsensitiveContains("Obsidian") }),
                                   app.version != "?" {
                                    Button("Installer…") {
                                        let panel=NSOpenPanel()
                                        panel.canChooseFiles=false
                                        panel.canChooseDirectories=true
                                        panel.prompt="Sélectionner un coffre Obsidian"
                                        if panel.runModal() == NSApplication.ModalResponse.OK,
                                           let url=panel.url {
                                            installVault=url
                                            installPlugin=item
                                            showInstallWarning=true
                                        }
                                    }.buttonStyle(.borderedProminent)
                                    if let status=operations.pluginStatus["obsidian:\(item.id)"] {
                                        Text(status).font(.caption2).foregroundStyle(.secondary)
                                            .frame(maxWidth:190,alignment:.leading)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                        }
                        if filtered.count > 180 {
                            Text("\(filtered.count - 180) autres résultats. Affine ta recherche pour les afficher.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Text(ecosystem.id == "jellyfin" ? "Les plugins Jellyfin concernent le serveur, pas le lecteur macOS." : "Les dépôts GitHub communautaires ne constituent pas des extensions officiellement certifiées.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(24).frame(width: 860, height: 690)
        .alert("Installer une extension communautaire ?",isPresented:$showInstallWarning) {
            Button("Installer dans ce coffre") {
                if let plugin=installPlugin,let vault=installVault,
                   let app=store.installed.first(where:{$0.name.localizedCaseInsensitiveContains("Obsidian")}) {
                    operations.installObsidianPlugin(plugin,vault:vault,installedVersion:app.version)
                }
            }
            Button("Annuler",role:.cancel) {}
        } message: {
            Text("Le code JavaScript de cette extension s'exécutera dans Obsidian une fois activé. OrbitStore vérifie son manifeste et la version minimale, mais n'audite pas sa sécurité. L'activation reste manuelle.")
        }
        .task(id: ecosystem.id) { await reload() }
    }

    private func reload() async {
        loading = true
        error = nil
        do { records = try await PluginDirectory.load(ecosystem) }
        catch { self.error = "Catalogue inaccessible : \(error.localizedDescription)" }
        loading = false
    }
}
