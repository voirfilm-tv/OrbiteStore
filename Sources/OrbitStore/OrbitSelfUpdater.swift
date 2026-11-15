import Foundation
import AppKit
import Combine
import CryptoKit

/// Checks GitHub releases of OrbitStore, independently of the marketplace
/// inventory. Ad-hoc-signed builds are not notarized: safe self-replacement
/// must remain user-assisted; no Gatekeeper bypass, privileged helper or
/// auto-execution of a downloaded app is performed.
@MainActor
final class OrbitSelfUpdater: ObservableObject {
    struct GitHubRelease: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: String
            let digest: String?
        }
        let tag_name: String
        let html_url: String
        let body: String?
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]
    }

    @Published private(set) var isChecking = false
    @Published private(set) var isDownloading = false
    @Published private(set) var availableVersion: String?
    @Published private(set) var notes: String = ""
    @Published private(set) var releasePage: URL?
    @Published private(set) var downloadedDMG: URL?
    @Published private(set) var status = "Mises à jour non vérifiées"
    @Published private(set) var error: String?
    @Published var includePrereleases = true {
        didSet { UserDefaults.standard.set(includePrereleases, forKey:"orbit.selfUpdater.prerelease") }
    }

    private var asset:GitHubRelease.Asset?
    private var checksumAsset:GitHubRelease.Asset?
    private let repository = "voirfilm-tv/OrbiteStore"
    var currentVersion:String {
        Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    init() {
        includePrereleases = UserDefaults.standard.object(forKey:"orbit.selfUpdater.prerelease") == nil ||
                             UserDefaults.standard.bool(forKey:"orbit.selfUpdater.prerelease")
    }

    nonisolated static func isNewer(_ remote:String,than local:String)->Bool {
        func components(_ value:String)->[Int] {
            let base=value.trimmingCharacters(in:.whitespacesAndNewlines)
                .replacingOccurrences(of:"^v",with:"",options:.regularExpression)
                .split(separator:"-").first.map(String.init) ?? value
            return base.split(separator:".").compactMap { Int($0) }
        }
        let lhs=components(remote),rhs=components(local)
        guard !lhs.isEmpty,!rhs.isEmpty else { return false }
        for index in 0..<max(lhs.count,rhs.count) {
            let a=index<lhs.count ? lhs[index] : 0
            let b=index<rhs.count ? rhs[index] : 0
            if a != b { return a>b }
        }
        return false
    }

    func check(force:Bool=false) async {
        guard !isChecking && !isDownloading else { return }
        if !force,let last=UserDefaults.standard.object(forKey:"orbit.selfUpdater.lastChecked") as? Date,
           Date().timeIntervalSince(last)<3600,availableVersion != nil { return }
        isChecking=true
        defer { isChecking=false }
        error=nil
        status="Recherche de mises à jour OrbitStore…"
        do {
            let url=URL(string:"https://api.github.com/repos/\(repository)/releases?per_page=25")!
            var request=URLRequest(url:url)
            request.setValue("application/vnd.github+json",forHTTPHeaderField:"Accept")
            request.setValue("OrbitStore-Updater/\(currentVersion)",forHTTPHeaderField:"User-Agent")
            request.timeoutInterval=20
            let (data,response)=try await URLSession.shared.data(for:request)
            guard let http=response as? HTTPURLResponse else {
                throw OrbitSelfUpdateError.network("Réponse GitHub invalide.")
            }
            if http.statusCode==403 || http.statusCode==429 {
                throw OrbitSelfUpdateError.network("GitHub limite temporairement les requêtes.")
            }
            guard http.statusCode==200 else {
                throw OrbitSelfUpdateError.network("Erreur GitHub HTTP \(http.statusCode).")
            }
            let releases=try JSONDecoder().decode([GitHubRelease].self,from:data)
            let candidates=releases.filter { !$0.draft && (includePrereleases || !$0.prerelease) }
                .sorted { Self.isNewer($0.tag_name,than:$1.tag_name) }
            let suitable=candidates.compactMap { release -> (GitHubRelease,GitHubRelease.Asset)? in
                guard let dmg=release.assets.first(where: {
                    $0.name.lowercased().hasPrefix("orbitstore-") &&
                    $0.name.lowercased().hasSuffix(".dmg") &&
                    URL(string:$0.browser_download_url)?.host=="github.com"
                }) else { return nil }
                return (release,dmg)
            }
            guard let newest=suitable.first else {
                availableVersion=nil
                asset=nil
                checksumAsset=nil
                status="Aucune version distribuable trouvée."
                return
            }
            releasePage=URL(string:newest.0.html_url)
            if Self.isNewer(newest.0.tag_name,than:currentVersion) {
                asset=newest.1
                checksumAsset=newest.0.assets.first(where:{$0.name=="SHA256SUMS.txt"})
                availableVersion=newest.0.tag_name
                notes=String((newest.0.body ?? "").prefix(3500))
                status="Mise à jour \(newest.0.tag_name) disponible"
            } else {
                asset=nil
                checksumAsset=nil
                availableVersion=nil
                status="OrbitStore \(currentVersion) est à jour"
            }
            UserDefaults.standard.set(Date(),forKey:"orbit.selfUpdater.lastChecked")
        } catch {
            self.error=error.localizedDescription
            status="Vérification impossible"
        }
    }

    private func expectedChecksum(for chosen:GitHubRelease.Asset) async throws -> String {
        if let digest=chosen.digest,digest.hasPrefix("sha256:") {
            let value=String(digest.dropFirst(7)).lowercased()
            if value.count==64 && value.allSatisfy({$0.isHexDigit}) { return value }
        }
        guard let manifest=checksumAsset,
              let url=URL(string:manifest.browser_download_url),
              url.scheme=="https",url.host=="github.com" else {
            throw OrbitSelfUpdateError.integrity("Aucune empreinte SHA-256 fournie pour cette release.")
        }
        let (data,response)=try await URLSession.shared.data(from:url)
        guard (response as? HTTPURLResponse)?.statusCode==200,
              let content=String(data:data,encoding:.utf8) else {
            throw OrbitSelfUpdateError.integrity("Empreintes de release indisponibles.")
        }
        for line in content.components(separatedBy:.newlines) {
            let trimmed=line.trimmingCharacters(in:.whitespacesAndNewlines)
            let fields=trimmed.split(whereSeparator:{$0==" " || $0=="\t"})
            if fields.count>=2 && String(fields[1]).trimmingCharacters(in:CharacterSet(charactersIn:"*"))==chosen.name {
                let hash=String(fields[0]).lowercased()
                if hash.count==64 && hash.allSatisfy({$0.isHexDigit}) {return hash}
            }
        }
        throw OrbitSelfUpdateError.integrity("Le fichier DMG est absent de la liste SHA-256.")
    }

    func downloadAndOpen() async {
        guard !isDownloading,let asset,
              let url=URL(string:asset.browser_download_url),
              url.scheme=="https",url.host=="github.com" else { return }
        isDownloading=true
        defer { isDownloading=false }
        error=nil
        status="Téléchargement de la mise à jour…"
        do {
            let expected=try await expectedChecksum(for:asset)
            let (temporary,response)=try await URLSession.shared.download(from:url)
            guard (response as? HTTPURLResponse)?.statusCode==200 else {
                throw OrbitSelfUpdateError.network("Le téléchargement du DMG a échoué.")
            }
            let data=try Data(contentsOf:temporary)
            let actual=SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
            guard actual.lowercased()==expected else {
                throw OrbitSelfUpdateError.integrity("Empreinte SHA-256 incorrecte. Téléchargement rejeté.")
            }
            let folder=FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/OrbitStore",isDirectory:true)
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let target=folder.appendingPathComponent(asset.name)
            if FileManager.default.fileExists(atPath:target.path) {
                try FileManager.default.removeItem(at:target)
            }
            try FileManager.default.moveItem(at:temporary,to:target)
            downloadedDMG=target
            status="DMG vérifié. Remplace l'ancienne application dans Applications."
            // A regular user-initiated Finder workflow is required for unsigned
            // and unnotarized builds. Do not bypass macOS security protections.
            if !NSWorkspace.shared.open(target) {
                NSWorkspace.shared.activateFileViewerSelecting([target])
            }
        } catch {
            self.error=error.localizedDescription
            status="Mise à jour non téléchargée"
        }
    }

    func revealDownloaded() {
        guard let target=downloadedDMG else { return }
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }
}

enum OrbitSelfUpdateError: LocalizedError {
    case network(String),integrity(String)
    var errorDescription:String? {
        switch self {
        case .network(let detail),.integrity(let detail): return detail
        }
    }
}
