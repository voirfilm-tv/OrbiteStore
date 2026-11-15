import SwiftUI
import AppKit

@main
struct OrbitStoreApp: App {
    @StateObject private var store = StoreModel()
    @StateObject private var operations = OrbitOperations()
    @StateObject private var updater = OrbitSelfUpdater()
    var body: some Scene {
        WindowGroup {
            StoreWindow()
                .environmentObject(store)
                .environmentObject(operations)
                .environmentObject(updater)
                .frame(minWidth:760,minHeight:520)
                .background(OrbitWindowBoundsGuard())
                .onAppear { store.start() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width:1180,height:780)
        Settings {
            PreferencesPanel().environmentObject(store).environmentObject(operations)
                .environmentObject(updater).frame(width:680)
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
    @EnvironmentObject private var operations: OrbitOperations
    @EnvironmentObject private var updater: OrbitSelfUpdater
    @State private var section = ScreenshotLaunchArguments.value("--screenshot-section", fallback: "Découvrir")
    @State private var search = ScreenshotLaunchArguments.value("--screenshot-search", fallback: "")
    @State private var selected: CatalogApp? = Inventory.catalog.first {
        $0.name == ScreenshotLaunchArguments.value("--screenshot-app",fallback:"")
    }
    @State private var selectedInstalled: MacApp?
    @State private var showingHelp = false
    @StateObject private var discovery = GitHubDiscovery()
    @State private var selectedEcosystem: Ecosystem?
    @State private var catalogPresence = "Toutes"
    @State private var catalogSort = "Recommandé"
    @State private var catalogMacFilter = "Paquets macOS"
    @State private var catalogPageSize = 60
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
        store.developerMode && !["Installées","Écosystèmes","Mises à jour","Installations","Historique","Préférences","Alternatives","Auto-hébergé"].contains(section)
    }
    private var searchPrompt: String {
        switch section {
        case "Installées": return "Rechercher une application installée"
        case "Écosystèmes": return "Rechercher un écosystème"
        case "Mises à jour": return "Rechercher une mise à jour"
        case "Alternatives": return "Chercher une alternative"
        case "Auto-hébergé": return "Chercher un service auto-hébergé"
        default: return store.developerMode ? "Chercher des apps et dépôts GitHub" : "Rechercher une application macOS"
        }
    }
    private var filtered: [CatalogApp] {
        var items=store.catalog.filter { item in
            (search.isEmpty ? (section == "Découvrir" || section == "Tout" || section == item.category) : true)
            && (search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
                || item.repo.localizedCaseInsensitiveContains(search))
        }
        if catalogMacFilter == "Paquets macOS" && !store.indexedApps.isEmpty {
            items=items.filter { store.catalogIsVerifiedMac($0) }
        }
        if catalogPresence == "Installées" {
            items=items.filter { !store.matches($0).isEmpty }
        } else if catalogPresence == "Non installées" {
            items=items.filter { store.matches($0).isEmpty }
        }
        if catalogSort == "Recommandé" {
            items.sort { store.catalogDiscoveryScore($0) > store.catalogDiscoveryScore($1) }
        } else if catalogSort == "Nom A–Z" {
            items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } else if catalogSort == "Popularité" {
            items.sort { store.catalogStars($0) > store.catalogStars($1) }
        } else if catalogSort == "Activité récente" {
            items.sort { store.catalogUpdatedAt($0) > store.catalogUpdatedAt($1) }
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
        var items=store.catalog.filter {
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
                    Label("Alternatives",systemImage:"arrow.triangle.branch").tag("Alternatives")
                    Label("Auto-hébergé",systemImage:"server.rack").tag("Auto-hébergé")
                    Label("Installées",systemImage:"square.stack.3d.up").tag("Installées")
                    Label("Écosystèmes",systemImage:"puzzlepiece.extension").tag("Écosystèmes")
                    Label("Mises à jour",systemImage:"arrow.triangle.2.circlepath").tag("Mises à jour")
                    Label("Installations",systemImage:"shippingbox.fill").tag("Installations")
                    Label("Historique",systemImage:"clock.arrow.circlepath").tag("Historique")
                }
                Section("Catégories") {
                    ForEach(Inventory.categories.filter {
                        store.developerMode || !["Développement","Lanceurs & émulation"].contains($0)
                    },id:\.self) { cat in
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
                        case "Installations": OrbitQueuePage().environmentObject(store).environmentObject(operations)
                        case "Historique": OrbitHistoryPage().environmentObject(operations)
                        case "Préférences": PreferencesPanel()
                        case "Alternatives": OrbitEditorialPage(kind:.alternatives,query:$search)
                            .environmentObject(store).environmentObject(operations)
                        case "Auto-hébergé": OrbitEditorialPage(kind:.hosted,query:$search)
                            .environmentObject(store).environmentObject(operations)
                        default: catalogPage
                        }
                    }
                    HStack {
                        Image(systemName:"shield.checkered").foregroundStyle(.secondary)
                        Text("Paquets contrôlés lors de l'installation")
                            .foregroundStyle(.secondary).font(.caption2)
                        Spacer()
                        Text(store.status).foregroundStyle(.secondary).font(.caption2)
                    }
                    .padding(.top,8)
                }
                .frame(maxWidth:1180,alignment:.leading)
                .padding(28)
                .frame(maxWidth:.infinity)
            }
            .background(Color(nsColor:.windowBackgroundColor))
            .safeAreaInset(edge:.bottom,spacing:0) {
                OrbitActivityBar(showQueue:{ section="Installations" })
                    .environmentObject(operations)
            }
            .searchable(text:$search,placement:.toolbar,prompt:searchPrompt)
            .toolbar {
                ToolbarItemGroup(placement:.primaryAction) {
                    if store.busy { ProgressView().controlSize(.small) }
                    Button {
                        store.scan()
                        operations.feedback("Inventaire actualisé","Les applications installées ont été réanalysées.",kind:.success)
                    } label: { Image(systemName:"arrow.clockwise") }
                        .help("Réanalyser le Mac")
                    Button {
                        operations.feedback("Actualisation demandée","Le catalogue est en cours de vérification.")
                        Task {
                            await store.refresh()
                            operations.feedback("Catalogue actualisé",store.indexStatus,kind:.success)
                        }
                    } label: { Image(systemName:"arrow.triangle.2.circlepath") }
                        .help("Actualiser GitHub")
                }
            }
        }
        .sheet(item:$selected) { entry in
            CatalogDetails(entry:entry).environmentObject(store).environmentObject(operations)
        }
        .sheet(item:$selectedInstalled) { app in
            InstalledDetails(app:app).environmentObject(store).environmentObject(operations)
        }
        .sheet(item:$selectedEcosystem) { ecosystem in
            ExtensionBrowser(ecosystem:ecosystem)
        }
        .onReceive(store.$releases) { _ in
            operations.notifyDigest(store:store)
            operations.offerManagedUpdates(store:store)
        }
        .onChange(of:section) { _ in catalogPageSize=60; search="" }
        .task { await updater.check() }
        .onChange(of:store.developerMode) { newValue in
            if !newValue && ["Développement","Lanceurs & émulation"].contains(section) {
                section="Découvrir"
            }
            if !newValue { catalogMacFilter="Paquets macOS" }
        }
        .task(id:section + "|" + search + "|" + String(store.developerMode)) {
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
        case "Lanceurs & émulation": return "arcade.stick"
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
                Text(section == "Jeux"
                     ? "Des jeux Mac prêts à télécharger, sans moteurs ou projets techniques."
                     : store.developerMode
                         ? "Mode développeur : logiciels, dépôts et outils techniques GitHub."
                         : "Une sélection d'applications macOS prêtes à télécharger, pour tous.")
                    .foregroundStyle(.secondary)
            }
            if section == "Découvrir" || section == "Tout" {
                banner
                LazyVGrid(columns:[GridItem(.adaptive(minimum:205),spacing:12)],spacing:12) {
                    OrbitCategoryShortcut(title:"Alternatives",subtitle:"Libres, sans abonnement",
                                          icon:"arrow.triangle.branch",color:.purple) { section="Alternatives" }
                    OrbitCategoryShortcut(title:"Auto-hébergé",subtitle:"Tes services, tes données",
                                          icon:"server.rack",color:.teal) { section="Auto-hébergé" }
                    OrbitCategoryShortcut(title:"Jeux",subtitle:"Jouer sur ton Mac",
                                          icon:"gamecontroller.fill",color:.orange) { section="Jeux" }
                    OrbitCategoryShortcut(title:"Multimédia",subtitle:"Films, vidéo et musique",
                                          icon:"play.rectangle.fill",color:.blue) { section="Multimédia" }
                }
                OrbitFeaturedStrip(
                    entries:OrbitCollections.featured.compactMap { repo in
                        store.catalog.first(where:{$0.repo.caseInsensitiveCompare(repo) == .orderedSame})
                    },
                    store:store,
                    open:{ selected=$0 })
            }
            if section == "Jeux" {
                HStack(spacing:14) {
                    Image(systemName:"gamecontroller.fill").font(.title).foregroundStyle(.indigo)
                    VStack(alignment:.leading,spacing:5) {
                        Text("Jeux jouables sur Mac").font(.headline)
                        Text("Les émulateurs et lanceurs sont classés à part. La compatibilité et la sécurité sont vérifiées avant installation.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.developerMode {
                        Button("Voir les lanceurs") { section="Lanceurs & émulation" }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(15).background(Color.indigo.opacity(0.07),in:RoundedRectangle(cornerRadius:14))
            }
            HStack {
                OrbitStatusPill(text:store.developerMode ? "Mode développeur" : "Grand public",
                                icon:store.developerMode ? "chevron.left.forwardslash.chevron.right" : "app.badge",
                                tint:store.developerMode ? .orange : .green)
                Label(store.indexStatus,systemImage:"externaldrive.badge.wifi")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                if store.indexLoading { ProgressView().controlSize(.small) }
                Button("Actualiser") {
                    operations.feedback("Actualisation lancée","Récupération de l'index compact.")
                    Task {
                        await store.refresh()
                        operations.feedback("Catalogue synchronisé",store.indexStatus,kind:.success)
                    }
                }
                    .buttonStyle(.bordered)
                    .disabled(store.busy || store.indexLoading)
            }
            HStack {
                Label(section == "Jeux" ? "Jeux à découvrir" : "Explorer le catalogue",systemImage:"square.grid.2x2.fill").font(.title2.bold())
                Spacer()
                Text("\(filtered.count) applications").font(.subheadline).foregroundStyle(.secondary)
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
                    Text("Pour vous").tag("Recommandé")
                    Text("★ Popularité").tag("Popularité")
                    Text("Activité récente").tag("Activité récente")
                    Text("Nom A–Z").tag("Nom A–Z")
                    Text("Sélection initiale").tag("Sélection")
                }.pickerStyle(.menu).frame(width:170)
                if store.developerMode {
                    Picker("Disponibilité",selection:$catalogMacFilter) {
                        Text("Paquets macOS").tag("Paquets macOS")
                        Text("Tous les dépôts").tag("Tous")
                    }.pickerStyle(.menu).frame(width:155)
                }
                Spacer()
            }
            if store.indexLoading && store.indexedApps.isEmpty {
                ProgressView("Recherche des applications Mac…")
                    .frame(maxWidth:.infinity,minHeight:140)
            } else if filtered.isEmpty {
                VStack(spacing:9) {
                    Image(systemName:"app.badge").font(.system(size:35))
                        .foregroundStyle(.secondary)
                    Text(store.indexedApps.isEmpty ? "Catalogue indisponible" :
                         "Aucune application correspondant aux critères")
                        .font(.headline)
                    Text(store.indexedApps.isEmpty
                         ? "Connexion nécessaire pour charger les applications avec des paquets macOS vérifiés."
                         : "Modifie la recherche ou le filtre pour afficher d'autres applications.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }.frame(maxWidth:.infinity,minHeight:180)
            }
            LazyVGrid(columns:columns,alignment:.leading,spacing:14) {
                ForEach(Array(filtered.prefix(catalogPageSize))) { entry in
                    Button { selected=entry } label: { appTile(entry) }
                        .buttonStyle(.plain)
                }
            }
            if filtered.count > catalogPageSize {
                HStack {
                    Spacer()
                    Button("Afficher plus (\(filtered.count - catalogPageSize) restants)") {
                        catalogPageSize += 60
                    }.buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            Text("Un fichier macOS dans une release ne certifie ni sa sécurité ni sa compatibilité. OrbitStore vérifie les protections macOS au moment de l'installation.")
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
                if discovery.canLoadMore {
                    HStack {
                        Spacer()
                        Button(discovery.loadingMore ? "Chargement…" : "Charger davantage de dépôts (\(discovery.results.count) / \(discovery.totalCount))") {
                            Task { await discovery.loadMore() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(discovery.loadingMore)
                        Spacer()
                    }.padding(.top,8)
                }
                Text("La recherche GitHub inclut du code source et des bibliothèques. Les applications Mac réellement indexées apparaissent dans la sélection OrbitStore.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var banner: some View {
        ZStack(alignment:.leading) {
            LinearGradient(colors:[Color(red:0.08,green:0.10,blue:0.23),
                                   Color(red:0.22,green:0.18,blue:0.44),
                                   Color(red:0.37,green:0.24,blue:0.46)],
                           startPoint:.topLeading,endPoint:.bottomTrailing)
            Circle().stroke(.white.opacity(0.12),lineWidth:1)
                .frame(width:330,height:330).offset(x:660,y:-65)
            Circle().stroke(.white.opacity(0.08),lineWidth:1)
                .frame(width:460,height:460).offset(x:590,y:-112)
            HStack(spacing:20) {
                VStack(alignment:.leading,spacing:13) {
                    Label("DÉCOUVERTE MAC · LOGICIELS LIBRES",systemImage:"sparkles")
                        .tracking(1.0).font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.80))
                    Text("Des apps qui donnent\nenvie d'explorer.")
                        .font(.system(size:34,weight:.bold,design:.rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal:false,vertical:true)
                    Text("Des alternatives, des jeux et des pépites à installer.\nUn catalogue pensé pour les vrais utilisateurs.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.80))
                        .fixedSize(horizontal:false,vertical:true)
                    HStack(spacing:9) {
                        Button("Voir les alternatives") { section="Alternatives" }
                            .buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                        Button("Explorer les jeux") { section="Jeux" }
                            .buttonStyle(.bordered).tint(.white)
                    }
                }
                Spacer(minLength:0)
                VStack(alignment:.trailing,spacing:-21) {
                    HStack(spacing:-14) {
                        heroIcon("iina/iina","IINA",69)
                        heroIcon("HandBrake/HandBrake","HandBrake",65)
                    }
                    HStack(spacing:-12) {
                        heroIcon("storytold/photocraft","PhotoCraft",69)
                        heroIcon("OpenRCT2/OpenRCT2","OpenRCT2",72)
                    }
                }
                .frame(maxWidth:175)
                .padding(.trailing,8)
            }.padding(28)
        }
        .frame(minHeight:276)
        .clipShape(RoundedRectangle(cornerRadius:23))
    }

    private func heroIcon(_ repo:String,_ name:String,_ size:CGFloat)->some View {
        AuthenticAppIcon(repo:repo,name:name,size:size)
            .padding(8)
            .background(.regularMaterial,in:RoundedRectangle(cornerRadius:19))
            .rotationEffect(.degrees(repo.contains("OpenRCT2") ? 7 : -5))
            .shadow(color:.black.opacity(0.26),radius:13,y:8)
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
            Text(store.catalogDescription(entry))
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                .frame(height:32,alignment:.topLeading)
            HStack {
                Text(entry.category).font(.caption2).foregroundStyle(.secondary)
                if store.catalogIsVerifiedMac(entry) {
                    Image(systemName:"macbook").foregroundStyle(.green)
                        .help("Une release GitHub contient un fichier macOS ; sécurité non auditée.")
                }
                Spacer()
                if store.catalogStars(entry)>0 {
                    Label(store.catalogStars(entry).formatted(),systemImage:"star.fill").font(.caption2)
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
                Button("Vérifier") {
                    operations.feedback("Recherche lancée","Vérification des versions des logiciels reconnus.")
                    Task {
                        await store.checkUpdates(force:true)
                        operations.feedback("Vérification terminée",store.status,kind:.success)
                    }
                }
                    .buttonStyle(.borderedProminent)
            }
            OrbitSelfUpdateCard()
                .environmentObject(updater)
            Divider()
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
                                Button("Installer") { operations.enqueue([entry],store:store) }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button("Installer") { operations.enqueue([entry],store:store) }
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

struct LegacyCatalogDetails: View {
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
                    Text(store.catalogDescription(entry)).foregroundStyle(.secondary)
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
    @EnvironmentObject private var operations: OrbitOperations
    @State private var chosenEcosystem: Ecosystem?
    @State private var related: [PluginRecord] = []
    @State private var searchingRelated = true
    let app: MacApp
    var body: some View {
        ScrollView {
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
            Divider()
            OrbitDiagnosisPanel(app:app)
                .environmentObject(store)
                .environmentObject(operations)
            HStack {
                Button("Afficher dans le Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath:app.path)])
                }
                Spacer()
                Button("Ouvrir l'application") {
                    NSWorkspace.shared.open(URL(fileURLWithPath:app.path))
                }.buttonStyle(.borderedProminent)
            }
        }
        .padding(26)
        .frame(maxWidth:.infinity,alignment:.leading)
        }
        .frame(width:760,height:690)
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
    @EnvironmentObject private var operations: OrbitOperations
    @EnvironmentObject private var updater: OrbitSelfUpdater
    var body: some View {
        Form {
            Section("Expérience OrbitStore") {
                Toggle(isOn:$store.developerMode) {
                    Label("Mode développeur",systemImage:"chevron.left.forwardslash.chevron.right")
                }
                Text(store.developerMode
                     ? "Catalogue avancé : dépôts techniques, outils de programmation et recherche GitHub complète. Les dépôts sans paquet n'affichent pas de bouton Installer."
                     : "Catalogue grand public : uniquement les applications indexées avec un paquet macOS identifié. Les outils techniques et les dépôts de code sont masqués.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            OrbitInstallPreferences()
                .environmentObject(operations)
            Section("Surveillance") {
                Toggle("Détecter de nouvelles applications et suggérer des extensions",
                    isOn:Binding(get:{store.notificationsEnabled},set:{store.setNotifications($0)}))
                Text("L'inventaire et les alertes fonctionnent uniquement lorsque OrbitStore est ouvert. Des noms d'applications peuvent être utilisés dans des recherches GitHub.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Mise à jour d'OrbitStore") {
                OrbitSelfUpdateCard(compact:true)
                    .environmentObject(updater)
                Toggle("Inclure les préversions d'OrbitStore",
                       isOn:$updater.includePrereleases)
            }
            Section("Mises à jour") {
                Toggle("Installer automatiquement les mises à jour des applications gérées et vérifiées",
                       isOn:$operations.autoInstallManaged)
                Text("Seulement pour les apps déjà installées par OrbitStore : même bundle ID, même éditeur signé, validation Gatekeeper et permissions disponibles. Une application ouverte, non notarisée ou non vérifiée reste manuelle.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Sécurité") {
                Label("Les étoiles GitHub indiquent la popularité, pas la fiabilité.",systemImage:"star")
                Label("Aucun contournement de Gatekeeper, aucune installation forcée de PKG.",systemImage:"shield")
                Label("Une application non reconnue est dirigée vers une installation manuelle.",systemImage:"hand.raised")
            }
        }
        .formStyle(.grouped)
        .padding(18)
    }
}
