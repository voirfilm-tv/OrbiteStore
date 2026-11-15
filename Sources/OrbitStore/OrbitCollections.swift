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
        .init(repo:"nextcloud/server",name:"Nextcloud",alternativeTo:"Google Drive",subtitle:"Fichiers, photos et outils collaboratifs",symbol:"cloud.fill",advanced:false,notice:"Nécessite un serveur et des sauvegardes"),
        .init(repo:"syncthing/syncthing",name:"Syncthing",alternativeTo:"Synchronisation cloud",subtitle:"Synchroniser des dossiers entre ordinateurs",symbol:"arrow.triangle.2.circlepath",advanced:false,notice:"Réplication locale ou par Internet, pas une sauvegarde"),
        .init(repo:"photoprism/photoprism",name:"PhotoPrism",alternativeTo:"Google Photos",subtitle:"Gérer et explorer une photothèque personnelle",symbol:"photo.stack",advanced:false,notice:"Serveur et stockage nécessaires"),
        .init(repo:"audiobookshelf/audiobookshelf",name:"Audiobookshelf",alternativeTo:"Applications de livres audio",subtitle:"Livres audio et podcasts personnels",symbol:"headphones",advanced:false,notice:"Fichiers audio non inclus"),
        .init(repo:"stirlingtools/Stirling-PDF",name:"Stirling PDF",alternativeTo:"Adobe Acrobat (outils PDF)",subtitle:"Fusionner, découper et traiter les PDF",symbol:"doc.richtext",advanced:false,notice:"Service web auto-hébergé"),
        .init(repo:"linkding/linkding",name:"Linkding",alternativeTo:"Pocket / favoris web",subtitle:"Enregistrer et retrouver ses liens",symbol:"bookmark.fill",advanced:false,notice:"Application web"),
        .init(repo:"FreshRSS/FreshRSS",name:"FreshRSS",alternativeTo:"Feedly",subtitle:"Suivre ses sites et flux RSS",symbol:"dot.radiowaves.left.and.right",advanced:false,notice:"Service web"),
        .init(repo:"memos/memos",name:"Memos",alternativeTo:"Notes en ligne",subtitle:"Notes rapides hébergées chez soi",symbol:"note.text",advanced:false,notice:"Service web"),
        .init(repo:"readeck/readeck",name:"Readeck",alternativeTo:"Pocket",subtitle:"Sauvegarder des pages à lire plus tard",symbol:"text.book.closed",advanced:false,notice:"Service web"),
        .init(repo:"gethomepage/homepage",name:"Homepage",alternativeTo:"Page d'accueil personnalisée",subtitle:"Tableau de bord pour ses services",symbol:"square.grid.2x2.fill",advanced:false,notice:"Accès interne et configuration nécessaires"),
        .init(repo:"bastienwirtz/homer",name:"Homer",alternativeTo:"Page de démarrage",subtitle:"Portail élégant vers ses applications",symbol:"house",advanced:false,notice:"Application web"),
        .init(repo:"filebrowser/filebrowser",name:"File Browser",alternativeTo:"Gestionnaire de fichiers web",subtitle:"Parcourir ses fichiers depuis le navigateur",symbol:"folder",advanced:false,notice:"Protéger les accès et les répertoires"),
        .init(repo:"Kareadita/Kavita",name:"Kavita",alternativeTo:"Bibliothèques de BD",subtitle:"Lire des BD et ebooks depuis chez soi",symbol:"books.vertical",advanced:false,notice:"Service web ; fichiers non inclus"),
        .init(repo:"calcom/cal.com",name:"Cal.com",alternativeTo:"Calendly",subtitle:"Réservations et prises de rendez-vous",symbol:"calendar",advanced:false,notice:"Déploiement plus avancé"),
        .init(repo:"BookStackApp/BookStack",name:"BookStack",alternativeTo:"Confluence",subtitle:"Documenter projets et connaissances",symbol:"books.vertical",advanced:false,notice:"Service web"),
        .init(repo:"kanboard/kanboard",name:"Kanboard",alternativeTo:"Trello",subtitle:"Tableaux de suivi de tâches",symbol:"rectangle.3.group",advanced:false,notice:"Application web"),
        .init(repo:"open-webui/open-webui",name:"Open WebUI",alternativeTo:"ChatGPT (interface)",subtitle:"Interface IA pour modèles et services configurés",symbol:"bubble.left.and.text.bubble.right",advanced:false,notice:"Modèle IA ou API nécessaire"),
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
        .init(repo:"searxng/searxng",name:"SearXNG",alternativeTo:"Recherche web",subtitle:"Métamoteur de recherche privé",symbol:"magnifyingglass",advanced:true,notice:"Résultats tributaires des sources externes"),
        .init(repo:"firefly-iii/firefly-iii",name:"Firefly III",alternativeTo:"Suivi financier",subtitle:"Analyser ses transactions et budgets",symbol:"chart.bar",advanced:true,notice:"Maintenance, confidentialité et sauvegardes"),
        .init(repo:"Forgejo/forgejo",name:"Forgejo",alternativeTo:"GitHub",subtitle:"Dépôts Git et gestion de tickets",symbol:"chevron.left.forwardslash.chevron.right",advanced:true,notice:"Administration et sauvegardes nécessaires"),
        .init(repo:"louislam/uptime-kuma",name:"Uptime Kuma",alternativeTo:"Pingdom",subtitle:"Surveiller la disponibilité de ses services",symbol:"waveform.path.ecg",advanced:true,notice:"Doit rester en fonctionnement"),
        .init(repo:"AdguardTeam/AdGuardHome",name:"AdGuard Home",alternativeTo:"DNS filtrant",subtitle:"Filtrage DNS pour un réseau local",symbol:"shield.fill",advanced:true,notice:"Impact possible sur la connectivité"),
        .init(repo:"pi-hole/pi-hole",name:"Pi-hole",alternativeTo:"Blocage publicitaire DNS",subtitle:"Réduire le pistage dans un réseau",symbol:"network.badge.shield.half.filled",advanced:true,notice:"Administration réseau"),
        .init(repo:"NocoDB/NocoDB",name:"NocoDB",alternativeTo:"Airtable",subtitle:"Interface web pour ses bases de données",symbol:"tablecells",advanced:true,notice:"Gestion des droits et bases"),
        .init(repo:"dgtlmoon/changedetection.io",name:"Changedetection.io",alternativeTo:"Surveillance de pages web",subtitle:"Être alerté lors de changements sur un site",symbol:"eye",advanced:true,notice:"Respecter les conditions des sites surveillés"),
        .init(repo:"CorentinTh/it-tools",name:"IT-Tools",alternativeTo:"Boîte à outils web",subtitle:"Convertisseurs, encodage et outils locaux",symbol:"wrench.and.screwdriver",advanced:true,notice:"Outils pour utilisateurs avancés"),
        .init(repo:"getumbrel/umbrel",name:"Umbrel",alternativeTo:"Serveur personnel",subtitle:"Découvrir des services à installer chez soi",symbol:"server.rack",advanced:true,notice:"Environnement dédié et sauvegardes"),
        .init(repo:"Lissy93/dashy",name:"Dashy",alternativeTo:"Tableau de bord cloud",subtitle:"Portail personnalisable vers ses services",symbol:"square.grid.3x2.fill",advanced:true,notice:"Application web"),
        .init(repo:"frigate-nvr/frigate",name:"Frigate",alternativeTo:"NVR cloud",subtitle:"Surveillance vidéo locale avec détection",symbol:"video",advanced:true,notice:"Matériel compatible et respect de la vie privée")
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
