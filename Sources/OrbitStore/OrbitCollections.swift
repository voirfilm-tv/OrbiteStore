import SwiftUI
import AppKit

struct OrbitEditorial:Identifiable {
    let repo:String
    let name:String
    let alternativeTo:String
    let subtitle:String
    let symbol:String
    let advanced:Bool
    let notice:String
    var id:String {repo.lowercased()}
    var url:URL {URL(string:"https://github.com/"+repo)!}
}

enum OrbitCollections {
    static let alternatives:[OrbitEditorial]=[
        .init(repo:"storytold/photocraft",name:"PhotoCraft",alternativeTo:"Photoshop",subtitle:"Retouche photo et calques",symbol:"photo",advanced:false,notice:"ArtCraft en alpha, fonctionnalités expérimentales"),
        .init(repo:"storytold/vectorcraft",name:"VectorCraft",alternativeTo:"Illustrator",subtitle:"Illustration vectorielle",symbol:"scribble",advanced:false,notice:"ArtCraft en développement"),
        .init(repo:"storytold/filmcraft",name:"FilmCraft",alternativeTo:"Premiere Pro",subtitle:"Montage vidéo libre",symbol:"film",advanced:false,notice:"ArtCraft en alpha"),
        .init(repo:"storytold/pdfcraft",name:"PdfCraft",alternativeTo:"Acrobat",subtitle:"Documents PDF sans abonnement",symbol:"doc.richtext",advanced:false,notice:"ArtCraft en alpha"),
        .init(repo:"SimoHypers/limusic",name:"Limusic",alternativeTo:"YouTube Music",subtitle:"Client musical non officiel",symbol:"music.note",advanced:false,notice:"Apple Silicon et macOS 15+ ; DMG non signé"),
        .init(repo:"darktable-org/darktable",name:"darktable",alternativeTo:"Lightroom",subtitle:"Retouche de photos RAW",symbol:"camera",advanced:false,notice:""),
        .init(repo:"mifi/lossless-cut",name:"LosslessCut",alternativeTo:"Media Encoder",subtitle:"Découper sans réencodage",symbol:"scissors",advanced:false,notice:""),
        .init(repo:"actualbudget/actual",name:"Actual Budget",alternativeTo:"YNAB",subtitle:"Budget personnel",symbol:"chart.pie",advanced:false,notice:""),
        .init(repo:"standardnotes/app",name:"Standard Notes",alternativeTo:"Evernote",subtitle:"Notes et confidentialité",symbol:"note.text",advanced:false,notice:""),
        .init(repo:"VSCodium/vscodium",name:"VSCodium",alternativeTo:"VS Code",subtitle:"Éditeur de code libre",symbol:"chevron.left.forwardslash.chevron.right",advanced:true,notice:"")
    ]
    static let hosted:[OrbitEditorial]=[
        .init(repo:"immich-app/immich",name:"Immich",alternativeTo:"Google Photos",subtitle:"Photos et souvenirs de famille",symbol:"photo.on.rectangle.angled",advanced:false,notice:"Serveur ou NAS nécessaire"),
        .init(repo:"jellyfin/jellyfin",name:"Jellyfin",alternativeTo:"Plex",subtitle:"Films et séries depuis son serveur",symbol:"play.rectangle",advanced:false,notice:"Serveur et client de lecture nécessaires"),
        .init(repo:"paperless-ngx/paperless-ngx",name:"Paperless-ngx",alternativeTo:"Gestion documentaire",subtitle:"Archiver ses factures et papiers",symbol:"doc.on.doc",advanced:false,notice:"Application web auto-hébergée"),
        .init(repo:"home-assistant/core",name:"Home Assistant",alternativeTo:"Cloud domotique",subtitle:"Maison connectée locale",symbol:"house.fill",advanced:false,notice:"Serveur ou box dédiée"),
        .init(repo:"navidrome/navidrome",name:"Navidrome",alternativeTo:"Serveur musical",subtitle:"Écouter sa musique personnelle",symbol:"music.note.house",advanced:false,notice:"N'inclut pas les catalogues commerciaux"),
        .init(repo:"mealie-recipes/mealie",name:"Mealie",alternativeTo:"Applications de recettes",subtitle:"Recettes et menus de famille",symbol:"fork.knife",advanced:false,notice:"Application web"),
        .init(repo:"actualbudget/actual",name:"Actual Budget",alternativeTo:"YNAB",subtitle:"Budget local ou auto-hébergé",symbol:"creditcard",advanced:false,notice:"Serveur facultatif"),
        .init(repo:"dani-garcia/vaultwarden",name:"Vaultwarden",alternativeTo:"Bitwarden serveur",subtitle:"Coffre-fort personnel",symbol:"key",advanced:true,notice:"TLS, mises à jour et sauvegardes obligatoires"),
        .init(repo:"coollabsio/coolify",name:"Coolify",alternativeTo:"Vercel",subtitle:"Déployer applications et bases de données",symbol:"server.rack",advanced:true,notice:"Administration serveur avancée"),
        .init(repo:"NginxProxyManager/nginx-proxy-manager",name:"Nginx Proxy Manager",alternativeTo:"Reverse proxy",subtitle:"Domaines et certificats TLS",symbol:"network",advanced:true,notice:"Administration réseau"),
        .init(repo:"portainer/portainer",name:"Portainer",alternativeTo:"Gestion Docker",subtitle:"Administration de conteneurs",symbol:"square.stack.3d.up",advanced:true,notice:"Pour développeurs et administrateurs"),
        .init(repo:"searxng/searxng",name:"SearXNG",alternativeTo:"Recherche web",subtitle:"Métamoteur de recherche privé",symbol:"magnifyingglass",advanced:true,notice:"Résultats tributaires des sources externes")
    ]
    static let featured=[
        "iina/iina","HandBrake/HandBrake","localsend/localsend",
        "storytold/photocraft","storytold/vectorcraft","SimoHypers/limusic",
        "mifi/lossless-cut","darktable-org/darktable",
        "OpenRCT2/OpenRCT2","ppy/osu","supertuxkart/stk-code",
        "rustdesk/rustdesk","actualbudget/actual","exelban/stats"
    ]
}

struct OrbitEditorialPage:View {
    enum Kind {case alternatives,hosted}
    let kind:Kind
    @EnvironmentObject private var store:StoreModel
    @EnvironmentObject private var operations:OrbitOperations
    @Binding var query:String
    @State private var selected:CatalogApp?
    private var title:String {kind == .alternatives ? "Alternatives" : "Auto-hébergé"}
    private var entries:[OrbitEditorial] {
        (kind == .alternatives ? OrbitCollections.alternatives : OrbitCollections.hosted)
        .filter { e in
            (store.developerMode || !e.advanced) &&
            (query.isEmpty || (e.name+" "+e.alternativeTo+" "+e.subtitle)
                .localizedCaseInsensitiveContains(query)) &&
            (kind == .hosted || store.catalogIsVerifiedMac(
                CatalogApp(repo:e.repo,name:e.name,category:"",icon:"",aliases:[])))
        }
    }
    var body:some View {
        VStack(alignment:.leading,spacing:20) {
            HStack(spacing:15) {
                Image(systemName:kind == .hosted ? "server.rack" : "arrow.triangle.branch")
                    .font(.system(size:30)).foregroundStyle(.indigo)
                    .frame(width:65,height:65)
                    .background(Color.indigo.opacity(0.10),in:RoundedRectangle(cornerRadius:17))
                VStack(alignment:.leading,spacing:5) {
                    Text(title).font(.system(size:34,weight:.bold,design:.rounded))
                    Text(kind == .hosted
                         ? "Les meilleures solutions à déployer sur ton propre serveur ou NAS."
                         : "Des alternatives libres aux applications les plus connues, avec paquets Mac identifiés.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            TextField("Rechercher un logiciel ou son alternative…",text:$query)
                .textFieldStyle(.roundedBorder)
            if kind == .hosted {
                Label("Ce sont des services web. Le bouton ouvre leur documentation, pas un installateur macOS.",
                      systemImage:"info.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns:[GridItem(.adaptive(minimum:280),spacing:14)],spacing:14) {
                ForEach(entries) { entry in
                    VStack(alignment:.leading,spacing:12) {
                        HStack(spacing:12) {
                            if kind == .alternatives {
                                AuthenticAppIcon(repo:entry.repo,name:entry.name,
                                     iconURL:store.catalogIconURL(CatalogApp(
                                         repo:entry.repo,name:entry.name,
                                         category:"",icon:"",aliases:[])),size:59)
                            } else {
                                Image(systemName:entry.symbol)
                                    .font(.title2).foregroundStyle(.indigo)
                                    .frame(width:59,height:59)
                                    .background(.indigo.opacity(0.08),in:RoundedRectangle(cornerRadius:14))
                            }
                            VStack(alignment:.leading,spacing:4) {
                                Text(entry.name).font(.headline).foregroundStyle(.primary)
                                Text("À la place de \(entry.alternativeTo)")
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer()
                        }
                        Text(entry.subtitle).font(.subheadline).foregroundStyle(.secondary)
                        if !entry.notice.isEmpty {
                            Label(entry.notice,systemImage:"info.circle")
                                .font(.caption2).foregroundStyle(.orange).lineLimit(2)
                        }
                        Spacer(minLength:5)
                        HStack {
                            if kind == .alternatives {
                                Button("Découvrir") {
                                    selected=store.catalog.first(where:{$0.repo.lowercased()==entry.repo.lowercased()})
                                        ?? CatalogApp(repo:entry.repo,name:entry.name,category:"Alternatives",icon:entry.symbol,aliases:[])
                                }.buttonStyle(.borderedProminent)
                            } else {
                                Button("Voir le projet") { NSWorkspace.shared.open(entry.url) }
                                    .buttonStyle(.borderedProminent)
                            }
                            Spacer()
                            Image(systemName:kind == .alternatives ? "macbook" : "server.rack")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(18).frame(maxWidth:.infinity,minHeight:196,alignment:.topLeading)
                    .background(Color(nsColor:.controlBackgroundColor),
                                in:RoundedRectangle(cornerRadius:18))
                }
            }
            if entries.isEmpty {
                Text("Aucun résultat disponible pour ce Mac. Un dépôt source seul ne suffit pas.")
                    .foregroundStyle(.secondary).frame(maxWidth:.infinity,minHeight:120)
            }
        }
        .sheet(item:$selected) { entry in
            CatalogDetails(entry:entry).environmentObject(store).environmentObject(operations)
        }
    }
}
