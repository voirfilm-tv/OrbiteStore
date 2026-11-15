import SwiftUI
import AppKit

@main
struct OrbitStoreApp: App {
    @StateObject private var store = StoreModel()
    var body: some Scene {
        WindowGroup {
            StoreWindow()
                .environmentObject(store)
                .frame(minWidth:960,minHeight:620)
                .onAppear { store.start() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        Settings {
            PreferencesPanel().environmentObject(store).frame(width:520)
        }
        MenuBarExtra("OrbitStore", systemImage:"square.stack.3d.up.fill") {
            Button("Analyser les applications") { store.scan() }
            Button("Vérifier les mises à jour") { Task { await store.checkUpdates() } }
            Divider()
            Button("Quitter") { NSApp.terminate(nil) }
        }
    }
}

// Only used for genuine screenshot CI navigation. Regular app launches are unchanged.
private enum ScreenshotLaunchArguments {
    static func value(_ key: String, fallback: String) -> String {
        guard let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(key + "=") }) else { return fallback }
        return String(arg.dropFirst(key.count + 1))
    }
}

struct StoreWindow: View {
    @EnvironmentObject private var store: StoreModel
    @State private var section = ScreenshotLaunchArguments.value("--screenshot-section", fallback: "Découvrir")
    @State private var search = ScreenshotLaunchArguments.value("--screenshot-search", fallback: "")
    @State private var selected: CatalogApp?
    @State private var selectedInstalled: MacApp?
    @State private var showingHelp = false
    @StateObject private var discovery = GitHubDiscovery()
    @State private var selectedEcosystem: Ecosystem?
    private let columns = [GridItem(.adaptive(minimum:218,maximum:300),spacing:14)]
    private var filtered: [CatalogApp] {
        Inventory.catalog.filter { item in
            (search.isEmpty ? (section == "Découvrir" || section == "Tout" || section == item.category) : true)
            && (search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
                || item.repo.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationSplitView {
            List(selection:$section) {
                Section("Bibliothèque") {
                    Label("Découvrir",systemImage:"sparkles.rectangle.stack").tag("Découvrir")
                    Label("Installées",systemImage:"square.stack.3d.up").tag("Installées")
                    Label("Écosystèmes",systemImage:"puzzlepiece.extension").tag("Écosystèmes")
                    Label("Mises à jour",systemImage:"arrow.triangle.2.circlepath").tag("Mises à jour")
                }
                Section("Catégories") {
                    ForEach(Inventory.categories,id:\.self) { cat in
                        Label(cat,systemImage:icon(for:cat)).tag(cat)
                    }
                }
                Section {
                    Label("Préférences",systemImage:"gearshape").tag("Préférences")
                }
            }
            .navigationSplitViewColumnWidth(min:200,ideal:235,max:300)
            .listStyle(.sidebar)
            .safeAreaInset(edge:.bottom) {
                HStack(spacing:8) {
                    Image(systemName:"square.stack.3d.up.fill")
                        .foregroundStyle(.indigo)
                    VStack(alignment:.leading,spacing:2) {
                        Text("ORBITSTORE").font(.caption.bold()).tracking(1.1)
                        Text("GitHub × macOS").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }.padding(14).background(.ultraThinMaterial)
            }
        } detail: {
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        searchPage
                    } else {
                        switch section {
                        case "Installées": installedPage
                        case "Écosystèmes": ecosystemsPage
                        case "Mises à jour": updatesPage
                        case "Préférences": PreferencesPanel()
                        default: catalogPage
                        }
                    }
                    HStack {
                        Text(store.status).foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        Text("★ = étoiles GitHub, pas des notes clients").font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.top,8)
                }
                .frame(maxWidth:1180,alignment:.leading)
                .padding(28)
                .frame(maxWidth:.infinity)
            }
            .background(Color(nsColor:.windowBackgroundColor))
            .searchable(text:$search,placement:.toolbar,prompt:"Rechercher sur GitHub et OrbitStore")
            .toolbar {
                ToolbarItemGroup(placement:.primaryAction) {
                    if store.busy { ProgressView().controlSize(.small) }
                    Button { store.scan() } label: { Image(systemName:"arrow.clockwise") }
                        .help("Réanalyser le Mac")
                    Button { Task { await store.refresh() } } label: { Image(systemName:"arrow.triangle.2.circlepath") }
                        .help("Actualiser GitHub")
                }
            }
        }
        .sheet(item:$selected) { entry in
            CatalogDetails(entry:entry).environmentObject(store)
        }
        .sheet(item:$selectedInstalled) { app in
            InstalledDetails(app:app).environmentObject(store)
        }
        .sheet(item:$selectedEcosystem) { ecosystem in
            ExtensionBrowser(ecosystem:ecosystem)
        }
        .task(id:search) {
            try? await Task.sleep(nanoseconds: 550_000_000)
            guard !Task.isCancelled else { return }
            await discovery.search(search)
        }
    }

    private func icon(for category:String)->String {
        switch category {
        case "Création": return "paintpalette"
        case "Multimédia": return "play.rectangle"
        case "Productivité": return "checkmark.circle"
        case "Développement": return "chevron.left.forwardslash.chevron.right"
        case "Sécurité": return "lock.shield"
        case "Réseau": return "network"
        case "Utilitaires": return "wrench.and.screwdriver"
        case "Jeux": return "gamecontroller"
        case "Audio & musique": return "music.note"
        case "Éducation": return "graduationcap"
        case "Graphisme": return "paintbrush"
        case "Internet": return "globe"
        case "Bureautique": return "doc.text"
        case "Accessibilité": return "accessibility"
        case "Personnalisation": return "slider.horizontal.3"
        default: return "square.grid.2x2"
        }
    }

    private var catalogPage: some View {
        VStack(alignment:.leading,spacing:22) {
            VStack(alignment:.leading,spacing:5) {
                Text(section == "Découvrir" ? "Découvrir" : section)
                    .font(.system(size:34,weight:.bold,design:.rounded))
                Text("Applications, dépôts GitHub et écosystèmes réunis dans une seule bibliothèque.")
                    .foregroundStyle(.secondary)
            }
            banner
            HStack {
                Label("Sélection GitHub",systemImage:"star.fill").font(.title2.bold())
                Spacer()
                Text("\(filtered.count) projets").font(.subheadline).foregroundStyle(.secondary)
            }
            LazyVGrid(columns:columns,alignment:.leading,spacing:14) {
                ForEach(filtered) { entry in
                    Button { selected=entry } label: { appTile(entry) }
                        .buttonStyle(.plain)
                }
            }
            Text("Les dépôts répertoriés ne sont pas tous des applications natives macOS. La disponibilité des binaires est vérifiée avant le téléchargement.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var searchPage: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack(alignment:.center) {
                VStack(alignment:.leading,spacing:5) {
                    Text("Recherche GitHub").font(.system(size:33,weight:.bold,design:.rounded))
                    Text("Résultats directs de GitHub et applications sélectionnées par OrbitStore.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if discovery.loading { ProgressView().controlSize(.small) }
                Button("Relancer") { Task { await discovery.search(search) } }
            }
            if !filtered.isEmpty {
                HStack {
                    Text("Dans OrbitStore").font(.title2.bold())
                    Spacer()
                    Text("\(filtered.count) applications").foregroundStyle(.secondary)
                }
                LazyVGrid(columns:columns,spacing:14) {
                    ForEach(filtered) { entry in
                        Button { selected=entry } label: { appTile(entry) }.buttonStyle(.plain)
                    }
                }
            }
            Divider()
            HStack {
                Text("Sur GitHub").font(.title2.bold())
                Spacer()
                Text("\(discovery.results.count) dépôts reçus")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error=discovery.error {
                Label(error,systemImage:"exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("GitHub limite les recherches anonymes. Patiente quelques minutes si nécessaire.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !discovery.loading && discovery.results.isEmpty {
                Text("Aucun dépôt trouvé pour cette recherche.").foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing:10) {
                    ForEach(discovery.results) { hit in
                        Button {
                            selected=CatalogApp(repo:hit.full_name,name:hit.name,
                                category:"Dépôts GitHub",icon:"shippingbox",aliases:[])
                        } label: {
                            HStack(spacing:13) {
                                AuthenticAppIcon(repo:hit.full_name,name:hit.name,
                                    branch:hit.default_branch,homepage:hit.homepage,size:48)
                                VStack(alignment:.leading,spacing:3) {
                                    Text(hit.name).font(.headline).foregroundStyle(.primary)
                                    Text(hit.full_name).font(.caption2).foregroundStyle(.secondary)
                                    Text(hit.description ?? "Description non fournie")
                                        .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                                Spacer(minLength:12)
                                Label(hit.stargazers_count.formatted(),systemImage:"star.fill")
                                    .font(.caption).foregroundStyle(.secondary)
                                Image(systemName:"chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(13)
                            .background(Color(nsColor:.controlBackgroundColor),
                                        in:RoundedRectangle(cornerRadius:14))
                        }.buttonStyle(.plain)
                    }
                }
                Text("GitHub contient aussi des bibliothèques et des dépôts sans application macOS. Aucun paquet n'est supposé compatible sans vérification.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var banner: some View {
        ZStack(alignment:.leading) {
            LinearGradient(
                colors:[Color(red:0.10,green:0.16,blue:0.38),Color(red:0.35,green:0.24,blue:0.61),Color(red:0.10,green:0.11,blue:0.28)],
                startPoint:.topLeading,endPoint:.bottomTrailing)
            HStack {
                VStack(alignment:.leading,spacing:13) {
                    Text("L'UNIVERS DES APPLICATIONS").tracking(1.5)
                        .font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
                    Text("Découvre les logiciels.\nExplore leurs extensions.")
                        .font(.system(size:30,weight:.bold,design:.rounded))
                        .foregroundStyle(.white)
                    Text("Une bibliothèque conçue pour ton Mac.")
                        .foregroundStyle(.white.opacity(0.8))
                    Button("Explorer les écosystèmes") { section = "Écosystèmes" }
                        .buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                }
                Spacer()
                ZStack {
                    Circle().stroke(.white.opacity(0.14),lineWidth:1).frame(width:220,height:220)
                    Circle().stroke(.white.opacity(0.23),lineWidth:1).frame(width:164,height:164)
                    Image(systemName:"square.stack.3d.up.fill")
                        .font(.system(size:95)).foregroundStyle(.white.opacity(0.87))
                    Image(systemName:"puzzlepiece.extension.fill")
                        .font(.system(size:34)).foregroundStyle(.white).offset(x:81,y:-61)
                }.frame(width:230)
            }.padding(28)
        }
        .frame(height:245)
        .clipShape(RoundedRectangle(cornerRadius:22))
    }

    private func appTile(_ entry:CatalogApp)->some View {
        VStack(alignment:.leading,spacing:12) {
            HStack(alignment:.top) {
                AuthenticAppIcon(repo:entry.repo,name:entry.name,
                    installedPath:store.matches(entry).first?.path,
                    branch:store.info[entry.repo]?.default_branch,
                    homepage:store.info[entry.repo]?.homepage,size:59)
                Spacer()
                if !store.matches(entry).isEmpty {
                    Image(systemName:"checkmark.circle.fill").foregroundStyle(.green)
                        .help("Installée sur ce Mac")
                }
            }
            Text(entry.name).font(.headline).lineLimit(1)
            Text(store.info[entry.repo]?.description ?? entry.repo)
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                .frame(height:32,alignment:.topLeading)
            HStack {
                Text(entry.category).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                if let stars=store.info[entry.repo]?.stargazers_count {
                    Label(stars.formatted(),systemImage:"star.fill").font(.caption2)
                } else {
                    Text("GitHub").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(17)
        .frame(maxWidth:.infinity,minHeight:191,alignment:.topLeading)
        .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:19))
        .overlay(RoundedRectangle(cornerRadius:19).stroke(.primary.opacity(0.055)))
    }

    private var installedPage: some View {
        VStack(alignment:.leading,spacing:16) {
            HStack {
                VStack(alignment:.leading,spacing:6) {
                    Text("Applications installées").font(.system(size:33,weight:.bold,design:.rounded))
                    Text("\(store.installed.count) applications détectées, y compris les logiciels propriétaires.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Réanalyser") { store.scan() }
            }
            ForEach(store.installed.filter{search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)}) { app in
                Button { selectedInstalled=app } label: {
                    HStack(spacing:13) {
                        Image(nsImage:NSWorkspace.shared.icon(forFile:app.path))
                            .resizable().frame(width:45,height:45)
                        VStack(alignment:.leading,spacing:3) {
                            Text(app.name).font(.headline)
                            Text("Version \(app.version)").foregroundStyle(.secondary).font(.caption)
                        }
                        Spacer()
                        let ecosystems=Ecosystems.matches(app.name)
                        if ecosystems.isEmpty {
                            Text("Aucune extension recensée")
                                .font(.caption).foregroundStyle(.tertiary)
                        } else {
                            Label("Extensions et ressources",systemImage:"puzzlepiece.extension")
                                .font(.caption).foregroundStyle(.indigo)
                        }
                        Image(systemName:"chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding(13)
                    .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:14))
                }.buttonStyle(.plain)
            }
        }
    }

    private var ecosystemsPage: some View {
        VStack(alignment:.leading,spacing:18) {
            Text("Écosystèmes").font(.system(size:33,weight:.bold,design:.rounded))
            Text("Plugins, thèmes et applications complémentaires. La compatibilité dépend de chaque version du logiciel hôte.")
                .foregroundStyle(.secondary)
            LazyVGrid(columns:columns,spacing:15) {
                ForEach(Ecosystems.all) { ecosystem in
                    VStack(alignment:.leading,spacing:13) {
                        HStack {
                            Image(systemName:"puzzlepiece.extension.fill")
                                .font(.title2).foregroundStyle(.indigo)
                            Spacer()
                            if let count=store.extensionCount[ecosystem.id] {
                                Text("\(count) recensés").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Text(ecosystem.name).font(.headline)
                        Text(ecosystem.description).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("Explorer les extensions") { selectedEcosystem=ecosystem }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth:.infinity,minHeight:155,alignment:.topLeading)
                    .padding(17)
                    .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:17))
                }
            }
            Text("Les nombres ne sont affichés que lorsqu'un registre officiel a été interrogé. Une ressource listée n'est pas forcément compatible avec ton installation.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var updatesPage: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text("Mises à jour").font(.system(size:33,weight:.bold,design:.rounded))
                    Text("Versions GitHub reconnues pour les applications installées.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Vérifier") { Task { await store.checkUpdates() } }
                    .buttonStyle(.borderedProminent)
            }
            let entries=Inventory.catalog.filter { !store.matches($0).isEmpty }
            if entries.isEmpty {
                VStack(spacing:12) {
                    Image(systemName:"checkmark.circle").font(.largeTitle).foregroundStyle(.secondary)
                    Text("Aucune application GitHub reconnue").font(.headline)
                    Text("Les applications installées apparaîtront ici lorsqu'une correspondance fiable sera identifiée.")
                        .font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth:.infinity,minHeight:170)
            } else {
                ForEach(entries) { entry in
                    HStack(spacing:15) {
                        AuthenticAppIcon(repo:entry.repo,name:entry.name,
                            installedPath:store.matches(entry).first?.path,
                            branch:store.info[entry.repo]?.default_branch,
                    homepage:store.info[entry.repo]?.homepage,size:44)
                        VStack(alignment:.leading,spacing:4) {
                            Text(entry.name).font(.headline)
                            Text("Installée : \(store.matches(entry).first?.version ?? "?")  ·  GitHub : \(store.releases[entry.repo]?.tag_name ?? "non vérifiée")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.updateAvailable(entry) {
                            Button("Télécharger") { Task { await store.installCandidate(entry) } }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Text("Aucune mise à jour confirmée").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(13)
                    .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:14))
                }
            }
        }
    }
}

struct CatalogDetails: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreModel
    @State private var chosenEcosystem: Ecosystem?
    let entry: CatalogApp

    @ViewBuilder
    private var releaseStatus: some View {
        switch store.releaseAvailability[entry.repo] {
        case .none, .some(.checking):
            HStack(spacing:8) {
                ProgressView().controlSize(.small)
                Text("Vérification des versions macOS publiées sur GitHub…")
                    .foregroundStyle(.secondary)
            }
        case .some(.ready(let tag, let prerelease)):
            Label("Paquet macOS détecté : \(tag)",systemImage:"checkmark.circle.fill")
                .foregroundStyle(.green)
            if prerelease {
                Label("Préversion GitHub : téléchargement expérimental, non garanti stable.",
                      systemImage:"exclamationmark.triangle")
                    .foregroundStyle(.orange).font(.caption)
            }
        case .some(.unavailable(let reason)):
            Label(reason,systemImage:"info.circle")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal:false,vertical:true)
        case .some(.failed(let reason)):
            Label(reason,systemImage:"exclamationmark.triangle")
                .foregroundStyle(.orange)
                .fixedSize(horizontal:false,vertical:true)
        }
    }

    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack(alignment:.top,spacing:18) {
                AuthenticAppIcon(repo:entry.repo,name:entry.name,
                    installedPath:store.matches(entry).first?.path,
                    branch:store.info[entry.repo]?.default_branch,
                    homepage:store.info[entry.repo]?.homepage,size:94)
                VStack(alignment:.leading,spacing:6) {
                    Text(entry.name).font(.largeTitle.bold())
                    Text(store.info[entry.repo]?.description ?? entry.repo).foregroundStyle(.secondary)
                    if let stars=store.info[entry.repo]?.stargazers_count {
                        Text("★ \(stars.formatted()) étoiles GitHub")
                    }
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName:"xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            Divider()
            if let ecosystem=Ecosystems.matches(entry.name).first {
                HStack {
                    Image(systemName:"puzzlepiece.extension.fill").foregroundStyle(.indigo)
                    Text("Extensions pour \(ecosystem.name)").font(.headline)
                    Spacer()
                    Button("Explorer dans OrbitStore") { chosenEcosystem=ecosystem }
                        .buttonStyle(.borderedProminent)
                }
            }
            HStack {
                Label(entry.category,systemImage:"square.grid.2x2")
                Spacer()
                if !store.matches(entry).isEmpty {
                    Label("Installée",systemImage:"checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            releaseStatus
            if let path=store.downloaded[entry.repo] {
                Label("Téléchargé : \(path)",systemImage:"checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
            }
            if let error=store.errors[entry.repo] {
                Text(error).foregroundStyle(.orange).font(.caption)
            }
            Text("Seuls les paquets identifiés comme macOS sont proposés. Le téléchargement n'installe ni n'exécute le logiciel.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            HStack {
                Button("Ouvrir sur GitHub") { NSWorkspace.shared.open(entry.url) }
                Spacer()
                switch store.releaseAvailability[entry.repo] {
                case .some(.ready(_, let preview)):
                    Button(preview ? "Télécharger la préversion Mac" : "Télécharger la version Mac") {
                        Task { await store.installCandidate(entry) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.downloading.contains(entry.repo))
                case .some(.failed(_)):
                    Button("Réessayer") {
                        Task { await store.checkDownloadAvailability(entry,force:true) }
                    }
                    .buttonStyle(.bordered)
                default:
                    EmptyView()
                }
            }
        }
        .padding(27)
        .frame(width:680,height:450)
        .sheet(item:$chosenEcosystem) { ExtensionBrowser(ecosystem:$0) }
        .task(id:entry.repo) { await store.checkDownloadAvailability(entry) }
    }
}

struct InstalledDetails: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreModel
    @State private var chosenEcosystem: Ecosystem?
    @State private var related: [PluginRecord] = []
    @State private var searchingRelated = true
    let app: MacApp
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack(spacing:16) {
                Image(nsImage:NSWorkspace.shared.icon(forFile:app.path))
                    .resizable().frame(width:72,height:72)
                VStack(alignment:.leading,spacing:5) {
                    Text(app.name).font(.largeTitle.bold())
                    Text("Version \(app.version)").foregroundStyle(.secondary)
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName:"xmark.circle.fill") }
                    .buttonStyle(.plain)
            }
            Divider()
            Text("Extensions et outils compatibles").font(.title2.bold())
            let ecosystems=Ecosystems.matches(app.name)
            if ecosystems.isEmpty {
                if searchingRelated {
                    ProgressView("Recherche de projets associés sur GitHub…")
                        .frame(maxWidth:.infinity,minHeight:130)
                } else if related.isEmpty {
                    VStack(spacing:12) {
                        Image(systemName:"puzzlepiece").font(.largeTitle).foregroundStyle(.secondary)
                        Text("Aucune extension à proposer").font(.headline)
                        Text("OrbitStore n'a pas trouvé de projet associé. Cette recherche n'est pas exhaustive.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth:.infinity,minHeight:130)
                } else {
                    Text("Pistes GitHub · compatibilité non vérifiée")
                        .font(.caption).foregroundStyle(.secondary)
                    ScrollView {
                        LazyVStack(spacing:8) {
                            ForEach(related.prefix(30)) { item in
                                HStack {
                                    VStack(alignment:.leading,spacing:3) {
                                        Text(item.name).font(.headline)
                                        Text(item.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    if let url=URL(string:item.url),url.scheme=="https" {
                                        Button("Source") { NSWorkspace.shared.open(url) }.buttonStyle(.bordered)
                                    }
                                }
                                .padding(10)
                                .background(.quaternary.opacity(0.3),in:RoundedRectangle(cornerRadius:10))
                            }
                        }
                    }.frame(maxHeight:180)
                }
            } else {
                ForEach(ecosystems) { e in
                    HStack {
                        VStack(alignment:.leading) {
                            Text(e.name).font(.headline)
                            Text(e.description).font(.caption).foregroundStyle(.secondary)
                            if let count=store.extensionCount[e.id] {
                                Text("\(count) extensions référencées").font(.caption).foregroundStyle(.indigo)
                            }
                        }
                        Spacer()
                        Button("Explorer dans OrbitStore") { chosenEcosystem=e }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(14)
                    .background(.quaternary.opacity(0.3),in:RoundedRectangle(cornerRadius:12))
                }
                Text("La compatibilité de chaque extension doit être confirmée auprès de son éditeur.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Afficher dans le Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath:app.path)])
            }
        }
        .padding(26)
        .frame(width:650,height:480)
        .sheet(item:$chosenEcosystem) { ExtensionBrowser(ecosystem:$0) }
        .task {
            if Ecosystems.matches(app.name).isEmpty {
                related = (try? await PluginDirectory.relatedToUnknownApp(app.name)) ?? []
            }
            searchingRelated = false
        }
    }
}

struct PreferencesPanel: View {
    @EnvironmentObject private var store: StoreModel
    var body: some View {
        Form {
            Section("Surveillance") {
                Toggle("Notifications d'extensions pour les nouvelles applications",
                    isOn:Binding(get:{store.notificationsEnabled},set:{store.setNotifications($0)}))
                Text("La surveillance fonctionne lorsque OrbitStore est lancé. Seuls les décomptes provenant d'un registre connu déclenchent une notification chiffrée.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Mises à jour") {
                Toggle("Télécharger automatiquement les nouvelles versions reconnues",
                    isOn:Binding(get:{store.autoDownload},set:{store.setAutoDownload($0)}))
                Text("Les téléchargements sont conservés dans ~/Downloads/OrbitStore. Aucune installation ou exécution automatique.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Sécurité") {
                Label("Les étoiles GitHub indiquent la popularité, pas la fiabilité.",systemImage:"star")
                Label("Les binaires restent soumis à Gatekeeper.",systemImage:"shield")
            }
        }
        .formStyle(.grouped)
        .padding(18)
    }
}
