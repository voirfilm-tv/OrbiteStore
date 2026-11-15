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
    @State private var catalogPresence = "Toutes"
    @State private var catalogSort = "Sélection"
    @State private var remoteFilter = "Tous"
    @State private var remoteSort = "Pertinence"
    @State private var installedScope = "Toutes"
    @State private var installedSort = "A–Z"
    @State private var ecosystemScope = "Tous"
    @State private var ecosystemSort = "A–Z"
    @State private var updatesScope = "Toutes"
    @State private var updatesSort = "A–Z"
    private let columns = [GridItem(.adaptive(minimum:218,maximum:300),spacing:14)]
    private var remoteSearchSection: Bool {
        !["Installées","Écosystèmes","Mises à jour","Préférences"].contains(section)
    }
    private var searchPrompt: String {
        switch section {
        case "Installées": return "Rechercher une application installée"
        case "Écosystèmes": return "Rechercher un écosystème"
        case "Mises à jour": return "Rechercher une mise à jour"
        default: return "Rechercher sur GitHub et OrbitStore"
        }
    }
    private var filtered: [CatalogApp] {
        var items=Inventory.catalog.filter { item in
            (search.isEmpty ? (section == "Découvrir" || section == "Tout" || section == item.category) : true)
            && (search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
                || item.repo.localizedCaseInsensitiveContains(search))
        }
        if catalogPresence == "Installées" {
            items=items.filter { !store.matches($0).isEmpty }
        } else if catalogPresence == "Non installées" {
            items=items.filter { store.matches($0).isEmpty }
        }
        if catalogSort == "Nom A–Z" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } else if catalogSort == "★ GitHub" {
            items.sort { (store.info[$0.repo]?.stargazers_count ?? -1) >
                         (store.info[$1.repo]?.stargazers_count ?? -1) }
        }
        return items
    }

    private var visibleGitHubHits: [GitHubHit] {
        var items=discovery.results
        if remoteFilter == "Avec licence" {
            items=items.filter {
                guard let license=$0.license?.spdx_id else { return false }
                return license != "NOASSERTION"
            }
        } else if remoteFilter == "≥ 100 étoiles" {
            items=items.filter { $0.stargazers_count >= 100 }
        } else if remoteFilter == "≥ 1 000 étoiles" {
            items=items.filter { $0.stargazers_count >= 1000 }
        } else if remoteFilter == "Installées" {
            items=items.filter {
                !store.matches(CatalogApp(repo:$0.full_name,name:$0.name,
                    category:"GitHub",icon:"shippingbox",aliases:[])).isEmpty
            }
        }
        if remoteSort == "★ GitHub" {
            items.sort { $0.stargazers_count > $1.stargazers_count }
        } else if remoteSort == "Nom A–Z" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return items
    }

    private var visibleInstalled: [MacApp] {
        var items=store.installed.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
                $0.bundleID.localizedCaseInsensitiveContains(search)
        }
        if installedScope == "Extensions connues" {
            items=items.filter { !Ecosystems.matches($0.name).isEmpty }
        } else if installedScope == "Autres applications" {
            items=items.filter { Ecosystems.matches($0.name).isEmpty }
        } else if installedScope == "Système" {
            items=items.filter { $0.path.hasPrefix("/System/Applications") }
        }
        if installedSort == "Z–A" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        } else {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return items
    }

    private var visibleEcosystems: [Ecosystem] {
        var items=Ecosystems.all.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
                $0.description.localizedCaseInsensitiveContains(search)
        }
        if ecosystemScope == "Logiciels installés" {
            items=items.filter { item in
                store.installed.contains { app in Ecosystems.matches(app.name).contains(where: { $0.id == item.id }) }
            }
        } else if ecosystemScope == "Registres officiels" {
            items=items.filter { $0.id == "obsidian" || $0.id == "jellyfin" }
        } else if ecosystemScope == "Découverte GitHub" {
            items=items.filter { $0.id != "obsidian" && $0.id != "jellyfin" }
        }
        if ecosystemSort == "A–Z" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } else if ecosystemSort == "Nombre recensé" {
            items.sort { (store.extensionCount[$0.id] ?? -1) > (store.extensionCount[$1.id] ?? -1) }
        }
        return items
    }

    private var visibleUpdates: [CatalogApp] {
        var items=Inventory.catalog.filter {
            !store.matches($0).isEmpty &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
             $0.repo.localizedCaseInsensitiveContains(search))
        }
        if updatesScope == "Disponibles" {
            items=items.filter { store.updateAvailable($0) }
        } else if updatesScope == "Non vérifiées" {
            items=items.filter { store.releases[$0.repo] == nil }
        }
        if updatesSort == "A–Z" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } else if updatesSort == "★ GitHub" {
            items.sort { (store.info[$0.repo]?.stargazers_count ?? 0) >
                         (store.info[$1.repo]?.stargazers_count ?? 0) }
        }
        return items
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
                    if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       remoteSearchSection {
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
            .searchable(text:$search,placement:.toolbar,prompt:searchPrompt)
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
        .task(id:section + "|" + search) {
            guard remoteSearchSection else { return }
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
            HStack(spacing:10) {
                Label("Filtres",systemImage:"line.3.horizontal.decrease")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Présence",selection:$catalogPresence) {
                    Text("Toutes").tag("Toutes")
                    Text("Installées").tag("Installées")
                    Text("Non installées").tag("Non installées")
                }.pickerStyle(.menu).frame(width:160)
                Picker("Trier",selection:$catalogSort) {
                    Text("Sélection").tag("Sélection")
                    Text("Nom A–Z").tag("Nom A–Z")
                    Text("★ GitHub").tag("★ GitHub")
                }.pickerStyle(.menu).frame(width:155)
                Spacer()
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
                Text("\(visibleGitHubHits.count) / \(discovery.results.count) dépôts affichés")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing:10) {
                Label("Filtres",systemImage:"line.3.horizontal.decrease")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Afficher",selection:$remoteFilter) {
                    Text("Tous").tag("Tous")
                    Text("Avec licence").tag("Avec licence")
                    Text("≥ 100 étoiles").tag("≥ 100 étoiles")
                    Text("≥ 1 000 étoiles").tag("≥ 1 000 étoiles")
                    Text("Installées").tag("Installées")
                }.pickerStyle(.menu).frame(width:165)
                Picker("Trier",selection:$remoteSort) {
                    Text("Pertinence").tag("Pertinence")
                    Text("★ GitHub").tag("★ GitHub")
                    Text("Nom A–Z").tag("Nom A–Z")
                }.pickerStyle(.menu).frame(width:150)
                Spacer()
            }
            if let error=discovery.error {
                Label(error,systemImage:"exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("GitHub limite les recherches anonymes. Patiente quelques minutes si nécessaire.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !discovery.loading && visibleGitHubHits.isEmpty {
                Text(discovery.results.isEmpty
                     ? "Aucun dépôt trouvé pour cette recherche."
                     : "Aucun dépôt ne correspond à ces filtres.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing:10) {
                    ForEach(visibleGitHubHits) { hit in
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
            HStack(spacing:10) {
                Label("Filtres",systemImage:"line.3.horizontal.decrease")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Afficher",selection:$installedScope) {
                    Text("Toutes").tag("Toutes")
                    Text("Extensions connues").tag("Extensions connues")
                    Text("Autres applications").tag("Autres applications")
                    Text("Système").tag("Système")
                }.pickerStyle(.menu).frame(width:190)
                Picker("Trier",selection:$installedSort) {
                    Text("Nom A–Z").tag("A–Z")
                    Text("Nom Z–A").tag("Z–A")
                }.pickerStyle(.menu).frame(width:125)
                Spacer()
                Text("\(visibleInstalled.count) affichées")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if visibleInstalled.isEmpty {
                Text("Aucune application ne correspond à ces filtres.")
                    .foregroundStyle(.secondary).frame(maxWidth:.infinity,minHeight:100)
            }
            ForEach(visibleInstalled) { app in
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
            HStack(spacing:10) {
                Label("Filtres",systemImage:"line.3.horizontal.decrease")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Afficher",selection:$ecosystemScope) {
                    Text("Tous").tag("Tous")
                    Text("Logiciels installés").tag("Logiciels installés")
                    Text("Registres officiels").tag("Registres officiels")
                    Text("Découverte GitHub").tag("Découverte GitHub")
                }.pickerStyle(.menu).frame(width:190)
                Picker("Trier",selection:$ecosystemSort) {
                    Text("Nom A–Z").tag("A–Z")
                    Text("Nombre recensé").tag("Nombre recensé")
                }.pickerStyle(.menu).frame(width:160)
                Spacer()
            }
            if visibleEcosystems.isEmpty {
                Text("Aucun écosystème ne correspond à ces filtres.")
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns:columns,spacing:15) {
                ForEach(visibleEcosystems) { ecosystem in
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
            HStack(spacing:10) {
                Label("Filtres",systemImage:"line.3.horizontal.decrease")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Afficher",selection:$updatesScope) {
                    Text("Toutes").tag("Toutes")
                    Text("Disponibles").tag("Disponibles")
                    Text("Non vérifiées").tag("Non vérifiées")
                }.pickerStyle(.menu).frame(width:165)
                Picker("Trier",selection:$updatesSort) {
                    Text("Nom A–Z").tag("A–Z")
                    Text("★ GitHub").tag("★ GitHub")
                }.pickerStyle(.menu).frame(width:140)
                Spacer()
            }
            let entries=visibleUpdates
            if entries.isEmpty {
                VStack(spacing:12) {
                    Image(systemName:"checkmark.circle").font(.largeTitle).foregroundStyle(.secondary)
                    Text(updatesScope == "Toutes" ? "Aucune application GitHub reconnue" : "Aucun résultat pour ce filtre").font(.headline)
                    Text("Les vérifications concernent uniquement les projets identifiés et leurs releases macOS.")
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
                            if store.downloadedFile(for:entry) != nil {
                                Button("Ouvrir le paquet") { store.openDownloaded(entry) }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button("Télécharger et ouvrir") { Task { await store.installCandidate(entry) } }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(store.downloading.contains(entry.repo))
                            }
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
            if let file=store.downloadedFile(for:entry) {
                VStack(alignment:.leading,spacing:9) {
                    Label("Téléchargement terminé : \(file.lastPathComponent)",
                          systemImage:"checkmark.circle.fill")
                        .font(.subheadline).foregroundStyle(.green)
                    Text(file.pathExtension.lowercased() == "dmg"
                         ? "Étape suivante : ouvre le disque dans le Finder, glisse l'application dans Applications, puis vérifie sa détection."
                         : "Étape suivante : vérifie la provenance et les protections Apple du fichier avant de poursuivre son installation.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                    HStack(spacing:10) {
                        Button(file.pathExtension.lowercased() == "dmg" ? "Ouvrir le DMG" : "Voir le paquet dans Finder") {
                            store.openDownloaded(entry)
                        }.buttonStyle(.borderedProminent)
                        Button("Afficher dans Finder") { store.revealDownloaded(entry) }
                            .buttonStyle(.bordered)
                        Button("Vérifier l'installation") { store.scan() }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(13)
                .frame(maxWidth:.infinity,alignment:.leading)
                .background(Color.green.opacity(0.075),in:RoundedRectangle(cornerRadius:13))
            }
            if let error=store.errors[entry.repo] {
                Text(error).foregroundStyle(.orange).font(.caption)
            }
            if let app=store.matches(entry).first {
                Label("Présente sur ce Mac : version \(app.version)",systemImage:"checkmark.seal.fill")
                    .font(.caption).foregroundStyle(.green)
            }
            Text("OrbitStore ouvre le disque DMG après un téléchargement demandé. Tu dois encore déplacer l'application vers Applications ; aucun installateur n'est exécuté silencieusement.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            HStack {
                Button("Ouvrir sur GitHub") { NSWorkspace.shared.open(entry.url) }
                Spacer()
                switch store.releaseAvailability[entry.repo] {
                case .some(.ready(_, let preview)):
                    if store.downloadedFile(for:entry) != nil {
                        Button("Télécharger à nouveau") {
                            Task { await store.installCandidate(entry) }
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.downloading.contains(entry.repo))
                    } else {
                        Button(store.downloading.contains(entry.repo) ? "Téléchargement…" :
                               (preview ? "Télécharger et ouvrir le DMG" : "Télécharger pour Mac")) {
                            Task { await store.installCandidate(entry) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.downloading.contains(entry.repo))
                    }
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
        .frame(width:720,height:525)
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
                Toggle("Télécharger automatiquement si l'identité de l'application est vérifiée",
                    isOn:Binding(get:{store.autoDownload},set:{store.setAutoDownload($0)}))
                Text("Seuls les logiciels dont le bundle ID est explicitement vérifié peuvent être téléchargés sans nouvelle action. Aucune installation ou exécution automatique.")
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
