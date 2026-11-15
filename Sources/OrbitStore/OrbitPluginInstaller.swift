import Foundation
import AppKit

// An explicit host adapter, not a promise to install arbitrary plugins.
// Obsidian's official community registry is the only source enabled here.
// Plugins contain executable JavaScript, so permission is always interactive.
enum OrbitPluginAdapterError: LocalizedError {
    case invalid(String)
    var errorDescription:String? {
        switch self { case .invalid(let detail): return detail }
    }
}

struct ObsidianPluginManifest: Decodable {
    let id:String
    let name:String?
    let version:String
    let minAppVersion:String?
}

enum OrbitVersion {
    static func isAtLeast(_ installed:String,_ required:String)->Bool {
        func parts(_ value:String)->[Int] {
            value.split(separator:".").prefix(4).compactMap{Int($0)}
        }
        let a=parts(installed), b=parts(required)
        guard !a.isEmpty && !b.isEmpty else { return false }
        for i in 0..<max(a.count,b.count) {
            let x=i<a.count ? a[i] : 0
            let y=i<b.count ? b[i] : 0
            if x != y { return x>y }
        }
        return true
    }
}

enum OrbitObsidianInstaller {
    static func install(_ plugin:PluginRecord,vault:URL,appVersion:String) async throws -> String {
        guard plugin.source=="Registre officiel Obsidian",
              plugin.url.hasPrefix("https://github.com/") else {
            throw OrbitPluginAdapterError.invalid("Source non autorisée : registre officiel Obsidian requis.")
        }
        let id=plugin.id
        let charset=CharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyz0123456789-_")
        guard !id.isEmpty,id.unicodeScalars.allSatisfy({charset.contains($0)}) else {
            throw OrbitPluginAdapterError.invalid("Identifiant de plugin invalide.")
        }
        guard vault.isFileURL,FileManager.default.fileExists(atPath:vault.appendingPathComponent(".obsidian").path) else {
            throw OrbitPluginAdapterError.invalid("Le dossier sélectionné n'est pas un coffre Obsidian (dossier .obsidian absent).")
        }
        let segments=URL(string:plugin.url)!.path.split(separator:"/")
        guard segments.count==2 else { throw OrbitPluginAdapterError.invalid("Dépôt GitHub non reconnu.") }
        let repo=segments.map(String.init).joined(separator:"/")
        let url=URL(string:"https://api.github.com/repos/\(repo)/releases/latest")!
        let data=try await MarketplaceHTTP.fetch(url)
        struct Release:Decodable {
            struct Asset:Decodable { let name:String; let browser_download_url:String }
            let assets:[Asset]
        }
        let release=try JSONDecoder().decode(Release.self,from:data)
        var binary:[String:Data]=[:]
        for name in ["manifest.json","main.js","styles.css"] {
            if let asset=release.assets.first(where:{$0.name==name}),
               let link=URL(string:asset.browser_download_url),
               link.scheme=="https",link.host=="github.com" {
                let file=try await MarketplaceHTTP.fetch(link,accept:"application/octet-stream")
                guard file.count<15_000_000 else {
                    throw OrbitPluginAdapterError.invalid("Fichier de plugin anormalement volumineux.")
                }
                binary[name]=file
            } else if name != "styles.css" {
                throw OrbitPluginAdapterError.invalid("Cette release ne fournit pas \(name) : installation manuelle requise.")
            }
        }
        guard let manifestData=binary["manifest.json"] else {
            throw OrbitPluginAdapterError.invalid("Manifest absent.")
        }
        let manifest=try JSONDecoder().decode(ObsidianPluginManifest.self,from:manifestData)
        guard manifest.id==id else {
            throw OrbitPluginAdapterError.invalid("L'identifiant du manifeste ne correspond pas à celui du registre.")
        }
        if let minimum=manifest.minAppVersion,
           !OrbitVersion.isAtLeast(appVersion,minimum) {
            throw OrbitPluginAdapterError.invalid("Cette extension exige Obsidian \(minimum) ou plus récent.")
        }
        let pluginsRoot=vault.appendingPathComponent(".obsidian/plugins",isDirectory:true)
        try FileManager.default.createDirectory(at:pluginsRoot,withIntermediateDirectories:true)
        let target=pluginsRoot.appendingPathComponent(id,isDirectory:true)
        let staging=pluginsRoot.appendingPathComponent(".orbitstore-\(UUID().uuidString)",isDirectory:true)
        try FileManager.default.createDirectory(at:staging,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:staging) }
        for (name,bytes) in binary { try bytes.write(to:staging.appendingPathComponent(name),options:.atomic) }
        var backup:URL?
        if FileManager.default.fileExists(atPath:target.path) {
            let save=pluginsRoot.appendingPathComponent("\(id).orbitstore-backup-\(UUID().uuidString)",isDirectory:true)
            try FileManager.default.moveItem(at:target,to:save)
            backup=save
        }
        do {
            try FileManager.default.moveItem(at:staging,to:target)
        } catch {
            if let backup { try? FileManager.default.moveItem(at:backup,to:target) }
            throw error
        }
        return "Plugin \(manifest.version) copié dans le coffre. Active-le manuellement dans Obsidian après avoir examiné les autorisations. Les scripts JavaScript de l'extension ne sont pas signés par Apple."
    }
}

@MainActor
extension OrbitOperations {
    func installObsidianPlugin(_ plugin:PluginRecord,vault:URL,installedVersion:String) {
        let key="obsidian:\(plugin.id)"
        pluginStatus[key]="Vérification du registre et de la release…"
        Task {
            do {
                let result=try await OrbitObsidianInstaller.install(
                    plugin,vault:vault,appVersion:installedVersion)
                pluginStatus[key]=result
                record(plugin.name,action:"plugin Obsidian",result:"succès",
                       details:result,path:vault.path)
            } catch {
                pluginStatus[key]=error.localizedDescription
                record(plugin.name,action:"plugin Obsidian",result:"échec",
                       details:error.localizedDescription)
            }
        }
    }
}
