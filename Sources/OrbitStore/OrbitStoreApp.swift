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

struct StoreWindow: View {
    @EnvironmentObject private var store: StoreModel
    @State private var section = "Découvrir"
    @State private var search = ""
    @State private var selected: CatalogApp?
    @State private var selectedInstalled: MacApp?
    @State private var showingHelp = false
    private let columns = [GridItem(.adaptive(minimum:218,maximum:300),spacing:14)]
    private var filtered: [CatalogApp] {
        Inventory.catalog.filter { item in
            (section == "Découvrir" || section == "Tout" || section == item.category)
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
                    switch section {
                    case "Installées": installedPage
                    case "Écosystèmes": ecosystemsPage
                    case "Mises à jour": updatesPage
                    case "Préférences": PreferencesPanel()
                    default: catalogPage
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
            .searchable(text:$search,placement:.toolbar,prompt:"Rechercher un logiciel")
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
                Image(systemName:entry.icon)
                    .font(.system(size:28,weight:.medium))
                    .frame(width:59,height:59)
                    .background(LinearGradient(colors:[.indigo.opacity(0.26),.purple.opacity(0.16)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:15))
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
                        Button("Voir le catalogue") {
                            if let url=URL(string:ecosystem.url) { NSWorkspace.shared.open(url) }
                        }.buttonStyle(.bordered)
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
                ContentUnavailableView("Aucune application GitHub reconnue",systemImage:"checkmark.circle",
                    description:Text("Les applications installées apparaîtront ici lorsqu'une correspondance fiable sera identifiée."))
            } else {
                ForEach(entries) { entry in
                    HStack(spacing:15) {
                        Image(systemName:entry.icon).font(.title2).frame(width:44,height:44)
                            .background(.indigo.opacity(0.12),in:RoundedRectangle(cornerRadius:11))
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
    let entry: CatalogApp
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack(alignment:.top,spacing:18) {
                Image(systemName:entry.icon).font(.system(size:40))
                    .frame(width:94,height:94)
                    .background(.indigo.opacity(0.16),in:RoundedRectangle(cornerRadius:21))
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
            HStack {
                Label(entry.category,systemImage:"square.grid.2x2")
                Spacer()
                if !store.matches(entry).isEmpty {
                    Label("Installée",systemImage:"checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            if let rel=store.releases[entry.repo] {
                Text("Dernière version GitHub : \(rel.tag_name)").font(.headline)
            }
            if let path=store.downloaded[entry.repo] {
                Label("Téléchargé : \(path)",systemImage:"checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
            }
            if let error=store.errors[entry.repo] {
                Text(error).foregroundStyle(.orange).font(.caption)
            }
            Text("Le téléchargement ne lance aucune installation automatiquement. Les paquets conservent les protections de macOS.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            HStack {
                Button("Ouvrir sur GitHub") { NSWorkspace.shared.open(entry.url) }
                Spacer()
                Button("Télécharger la version Mac") {
                    Task { await store.installCandidate(entry) }
                }.buttonStyle(.borderedProminent)
            }
        }
        .padding(27)
        .frame(width:680,height:400)
    }
}

struct InstalledDetails: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreModel
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
                ContentUnavailableView("Aucune ressource recensée",systemImage:"puzzlepiece",
                    description:Text("OrbitStore ne connaît pas encore d'écosystème pour cette application."))
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
                        Button("Explorer") {
                            if let url=URL(string:e.url) { NSWorkspace.shared.open(url) }
                        }.buttonStyle(.borderedProminent)
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
        .frame(width:650,height:440)
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
