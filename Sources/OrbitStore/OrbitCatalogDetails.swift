import SwiftUI
import AppKit

/// Native editorial app sheet: real app identity, capabilities, version details,
/// host extensions and a single clear lifecycle action. No fake screenshots.
struct CatalogDetails: View {
    let entry:CatalogApp
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store:StoreModel
    @EnvironmentObject private var operations:OrbitOperations
    @State private var tab="Présentation"
    @State private var ecosystemToOpen:Ecosystem?
    @State private var alternateToOpen:CatalogApp?

    private var repoInfo:RepositoryInfo? { store.info[entry.repo] }
    private var installed:MacApp? { store.matches(entry).first }
    private var release:ReleaseInfo? { store.releases[entry.repo] }
    private var ecosystem:Ecosystem? { Ecosystems.matches(entry.name).first }
    private var lastJob:OrbitJob? { operations.jobs.last(where:{$0.repo==entry.repo}) }

    private var appIcon:some View {
        AuthenticAppIcon(repo:entry.repo,name:entry.name,installedPath:installed?.path,
                         branch:repoInfo?.default_branch,homepage:repoInfo?.homepage,
                         iconURL:store.catalogIconURL(entry),size:100)
            .padding(10)
            .background(.white.opacity(0.16),in:RoundedRectangle(cornerRadius:25))
    }

    private var hero:some View {
        ZStack(alignment:.leading) {
            LinearGradient(colors:[
                Color(red:0.09,green:0.11,blue:0.24),
                Color(red:0.22,green:0.18,blue:0.42),
                Color(red:0.36,green:0.23,blue:0.48)],
                startPoint:.topLeading,endPoint:.bottomTrailing)
            Circle().stroke(.white.opacity(0.13),lineWidth:2)
                .frame(width:280,height:280).offset(x:570,y:-75)
            Circle().stroke(.white.opacity(0.13),lineWidth:2)
                .frame(width:200,height:200).offset(x:630,y:-62)
            VStack(alignment:.leading,spacing:16) {
                HStack(alignment:.top,spacing:20) {
                    appIcon
                    VStack(alignment:.leading,spacing:10) {
                        Text(entry.category.uppercased()).font(.caption.weight(.semibold))
                            .tracking(1.4).foregroundStyle(.white.opacity(0.67))
                        Text(entry.name).font(.system(size:37,weight:.bold,design:.rounded))
                            .foregroundStyle(.white).lineLimit(2)
                        Text(store.catalogDescription(entry))
                            .font(.subheadline).foregroundStyle(.white.opacity(0.77))
                            .lineLimit(3)
                        HStack(spacing:7) {
                            if installed != nil {
                                heroChip("INSTALLÉE",icon:"checkmark.circle.fill")
                            } else {
                                heroChip("GITHUB",icon:"chevron.left.forwardslash.chevron.right")
                            }
                            if release?.prerelease == true {
                                heroChip("BÊTA",icon:"flask")
                            }
                        }
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName:"xmark.circle.fill")
                            .font(.title2).foregroundStyle(.white.opacity(0.8))
                    }.buttonStyle(.plain)
                }
            }.padding(30)
        }
        .frame(height:235)
        .clipShape(RoundedRectangle(cornerRadius:22))
    }
    private func heroChip(_ label:String,icon:String)->some View {
        Label(label,systemImage:icon).font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal,10).padding(.vertical,6)
            .background(.white.opacity(0.13),in:Capsule())
    }

    private func metric(_ title:String,value:String,icon:String)->some View {
        VStack(alignment:.leading,spacing:6) {
            Label(title,systemImage:icon).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline.weight(.semibold)).lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth:.infinity,alignment:.leading)
        .padding(13)
        .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:13))
    }
    private var metrics:some View {
        HStack(spacing:11) {
            metric("ÉTOILES GITHUB",value:store.catalogStars(entry)>0 ? store.catalogStars(entry).formatted() : "—",
                   icon:"star.fill")
            metric("LANGAGE",value:repoInfo?.language ?? store.catalogLanguage(entry) ?? "Non indiqué",icon:"curlybraces")
            metric("LICENCE",value:repoInfo?.license?.spdx_id ?? store.catalogIndexedLicense(entry) ?? "À vérifier",icon:"doc.text")
            metric("DERNIÈRE RELEASE",value:release?.tag_name ?? store.catalogReleaseTag(entry) ?? "À vérifier",icon:"tag")
        }
    }

    @ViewBuilder
    private var availability:some View {
        switch store.releaseAvailability[entry.repo] {
        case .none, .some(.checking):
            Label("Analyse des paquets macOS…",systemImage:"hourglass")
                .foregroundStyle(.secondary)
        case .some(.ready(let version,let beta)):
            HStack(spacing:8) {
                OrbitStatusPill(text:"Paquet macOS \(version)",icon:"checkmark.circle.fill",tint:.green)
                if beta { OrbitStatusPill(text:"Préversion",icon:"flask",tint:.orange) }
            }
        case .some(.unavailable(let reason)):
            Label(reason,systemImage:"info.circle").foregroundStyle(.secondary)
        case .some(.failed(let reason)):
            Label(reason,systemImage:"exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
    }

    private var overview:some View {
        VStack(alignment:.leading,spacing:15) {
            Text("À propos du logiciel").font(.title2.bold())
            Text(store.catalogDescription(entry))
                .foregroundStyle(.secondary)
                .frame(maxWidth:.infinity,alignment:.leading)
            availability
            if let app=installed {
                HStack {
                    Image(systemName:"checkmark.seal.fill").foregroundStyle(.green)
                    VStack(alignment:.leading,spacing:3) {
                        Text("Présente sur ce Mac · v\(app.version)").font(.headline)
                        Text(app.path).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Button("Afficher dans Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath:app.path)])
                    }.buttonStyle(.bordered)
                }
                .padding(15).background(Color.green.opacity(0.06),
                                        in:RoundedRectangle(cornerRadius:12))
            }
            if let job=lastJob {
                HStack(alignment:.top,spacing:11) {
                    Image(systemName:job.phase=="Installée" ? "checkmark.circle.fill" :
                          job.finished ? "info.circle" : "arrow.down.circle")
                        .foregroundStyle(job.phase=="Installée" ? Color.green : Color.indigo)
                    VStack(alignment:.leading,spacing:4) {
                        Text(job.phase).font(.headline)
                        Text(job.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(13)
                .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:12))
            }
            HStack {
                Image(systemName:"shield.lefthalf.filled").foregroundStyle(.indigo)
                VStack(alignment:.leading,spacing:4) {
                    Text("Installation sous contrôle").font(.headline)
                    Text("OrbitStore vérifie la signature et Gatekeeper avant toute copie silencieuse. Si l'éditeur ou la version ne peuvent pas être validés, l'installation reste manuelle.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(14).background(.indigo.opacity(0.06),in:RoundedRectangle(cornerRadius:13))
            if !alternatives.isEmpty {
                Text("Dans la même catégorie").font(.headline)
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:11) {
                        ForEach(alternatives) { other in
                            Button { alternateToOpen=other } label: {
                                HStack(spacing:10) {
                                    AuthenticAppIcon(repo:other.repo,name:other.name,
                                        installedPath:store.matches(other).first?.path,
                                        branch:store.info[other.repo]?.default_branch,
                                        homepage:store.info[other.repo]?.homepage,
                                         iconURL:store.catalogIconURL(other),size:39)
                                    Text(other.name).font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(10).background(Color(nsColor:.controlBackgroundColor),
                                                        in:RoundedRectangle(cornerRadius:10))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    private var alternatives:[CatalogApp] {
        Array(store.catalog.filter{$0.category==entry.category && $0.repo != entry.repo}.sorted{store.catalogStars($0)>store.catalogStars($1)}.prefix(6))
    }
    private var versions:some View {
        VStack(alignment:.leading,spacing:13) {
            HStack {
                Text("Versions et nouveautés").font(.title2.bold())
                Spacer()
                if let link=release?.html_url,let url=URL(string:link) {
                    Button("Voir la release") { NSWorkspace.shared.open(url) }
                        .buttonStyle(.bordered)
                }
            }
            if let release {
                HStack {
                    OrbitStatusPill(text:release.tag_name,icon:"tag",tint:.indigo)
                    if release.prerelease == true {
                        OrbitStatusPill(text:"Bêta",icon:"flask",tint:.orange)
                    }
                    if let published=release.published_at {
                        Text(published.prefix(10)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if operations.isIgnored(entry,release:release.tag_name) {
                        Button("Réactiver cette version") { operations.ignore(entry.repo,version:"") }
                    } else {
                        Button("Ignorer cette version") {
                            operations.ignore(entry.repo,version:release.tag_name)
                        }
                    }
                }
                Text("Notes de publication").font(.headline)
                if let notes=release.body,!notes.isEmpty {
                    ScrollView {
                        Text(String(notes.prefix(7000)))
                            .font(.callout).textSelection(.enabled)
                            .frame(maxWidth:.infinity,alignment:.leading)
                    }.frame(maxHeight:230)
                } else {
                    Text("Aucune note de version publiée.").foregroundStyle(.secondary)
                }
                Text("Le retour arrière est proposé dans la fiche de l'application installée lorsqu'une sauvegarde vérifiée existe.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Aucune release exploitable n'a encore été identifiée.")
                    .foregroundStyle(.secondary)
            }
        }
    }
    private var extensions:some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Extensions et intégrations").font(.title2.bold())
            if let ecosystem {
                HStack(spacing:15) {
                    Image(systemName:"puzzlepiece.extension.fill").font(.system(size:35))
                        .foregroundStyle(.indigo)
                        .frame(width:58,height:58)
                        .background(.indigo.opacity(0.09),in:RoundedRectangle(cornerRadius:14))
                    VStack(alignment:.leading,spacing:5) {
                        Text(ecosystem.name).font(.headline)
                        Text(ecosystem.description).font(.caption).foregroundStyle(.secondary)
                        Text("Compatibilité exacte à vérifier avant installation.")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                    Spacer()
                    Button("Explorer") { ecosystemToOpen=ecosystem }
                        .buttonStyle(.borderedProminent)
                }
                .padding(14)
                .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:16))
            } else {
                Label("Aucun catalogue d'extensions confirmé pour ce logiciel.",
                      systemImage:"puzzlepiece")
                    .foregroundStyle(.secondary)
                Text("Cette absence ne prouve pas qu'il n'existe aucune extension. La découverte GitHub reste possible depuis Installées.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private var sources:some View {
        VStack(alignment:.leading,spacing:14) {
            OrbitSourcesView(entry:entry,installed:installed)
                .environmentObject(operations)
            Divider()
            Text("Éditeur et sécurité").font(.headline)
            Text("Les étoiles GitHub sont une mesure de popularité, pas une évaluation de sûreté. Les dépôts, paquets et auteurs peuvent changer au fil des publications.")
                .font(.caption).foregroundStyle(.secondary)
            if let app=installed {
                OrbitDiagnosisPanel(app:app).environmentObject(operations).environmentObject(store)
            }
        }
    }

    private var bottomBar:some View {
        VStack(alignment:.leading,spacing:10) {
            if let job=lastJob {
                HStack(spacing:10) {
                    if !job.finished { ProgressView().controlSize(.small) }
                    else {
                        Image(systemName:job.phase=="Installée" ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(job.phase=="Installée" ? Color.green : Color.orange)
                    }
                    VStack(alignment:.leading,spacing:3) {
                        Text(job.phase).font(.caption.weight(.semibold))
                        Text(job.detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer()
                }
            }
            HStack(spacing:12) {
            Button("Voir le dépôt") { NSWorkspace.shared.open(entry.url) }
                .buttonStyle(.bordered)
            if let file=store.downloadedFile(for:entry) {
                Button("Afficher le paquet") { store.revealDownloaded(entry) }
                    .buttonStyle(.bordered)
                if file.pathExtension.lowercased()=="dmg" {
                    Button("Ouvrir dans Finder") { store.openDownloaded(entry) }
                        .buttonStyle(.bordered)
                }
            }
            Spacer(minLength:8)
            if let app=installed {
                Button("Ouvrir") { NSWorkspace.shared.open(URL(fileURLWithPath:app.path)) }
                    .buttonStyle(.borderedProminent)
                if store.updateAvailable(entry) && !operations.isIgnored(entry,release:release?.tag_name) {
                    Button("Mettre à jour") { operations.enqueue([entry],store:store) }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                }
            } else {
                switch store.releaseAvailability[entry.repo] {
                case .some(.ready):
                    Button("Installer") { operations.enqueue([entry],store:store) }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                case .some(.failed):
                    Button("Réessayer") {
                        Task { await store.checkDownloadAvailability(entry,force:true) }
                    }.buttonStyle(.bordered)
                default:
                    Button("Non disponible pour Mac") {}.disabled(true)
                }
            }
            }
        }
        .padding(.horizontal,25).padding(.vertical,15)
        .background(.ultraThinMaterial)
    }

    var body:some View {
        VStack(spacing:0) {
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    hero
                    metrics
                    Picker("Informations",selection:$tab) {
                        Text("Présentation").tag("Présentation")
                        Text("Versions").tag("Versions")
                        Text("Extensions").tag("Extensions")
                        Text("Sources & sécurité").tag("Sources")
                    }.pickerStyle(.segmented).labelsHidden()
                    Group {
                        switch tab {
                        case "Versions": versions
                        case "Extensions": extensions
                        case "Sources": sources
                        default: overview
                        }
                    }.padding(.top,5)
                    Spacer(minLength:8)
                }.padding(23)
            }
            Divider()
            bottomBar
        }
        .frame(width:820,height:610)
        .sheet(item:$ecosystemToOpen) { ExtensionBrowser(ecosystem:$0) }
        .sheet(item:$alternateToOpen) { CatalogDetails(entry:$0)
            .environmentObject(store).environmentObject(operations) }
        .task(id:entry.repo) {
            if store.info[entry.repo]==nil,
               let url=URL(string:"https://api.github.com/repos/"+entry.repo),
               let data=try? await MarketplaceHTTP.fetch(url),
               let metadata=try? JSONDecoder().decode(RepositoryInfo.self,from:data) {
                store.info[entry.repo]=metadata
            }
            await store.checkDownloadAvailability(entry)
            await operations.checkSources(for:entry,installed:installed)
        }
    }
}
