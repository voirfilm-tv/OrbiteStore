import SwiftUI
import AppKit

// Compact native surfaces for the application's expanding lifecycle features.

struct OrbitStatusPill: View {
    let text:String
    let icon:String
    var tint:Color = .secondary
    var body:some View {
        Label(text,systemImage:icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal,11)
            .padding(.vertical,7)
            .background(tint.opacity(0.09),in:Capsule())
    }
}

struct OrbitHistoryPage: View {
    @EnvironmentObject private var operations:OrbitOperations
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            HStack {
                VStack(alignment:.leading,spacing:5) {
                    Text("Historique").font(.system(size:34,weight:.bold,design:.rounded))
                    Text("Journal local des installations, vérifications et opérations réalisées par OrbitStore.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                OrbitStatusPill(text:"\(operations.history.count) opérations",icon:"clock")
            }
            if operations.history.isEmpty {
                VStack(spacing:10) {
                    Image(systemName:"clock.arrow.circlepath").font(.system(size:40)).foregroundStyle(.secondary)
                    Text("Aucune opération enregistrée").font(.headline)
                    Text("Les prochaines installations et modifications réalisées depuis OrbitStore apparaîtront ici.")
                        .font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth:.infinity,minHeight:190)
            }
            LazyVStack(spacing:9) {
                ForEach(operations.history) { event in
                    HStack(alignment:.top,spacing:14) {
                        Image(systemName:event.result=="succès" ? "checkmark.circle.fill" :
                                (event.result=="échec" ? "exclamationmark.triangle.fill" : "info.circle.fill"))
                            .foregroundStyle(event.result=="succès" ? Color.green : Color.orange)
                            .frame(width:30,height:30)
                        VStack(alignment:.leading,spacing:4) {
                            Text(event.name).font(.headline)
                            Text("\(event.action.capitalized) · \(event.result)").font(.subheadline)
                            Text(event.details).font(.caption).foregroundStyle(.secondary)
                            if let path=event.path { Text(path).font(.caption2).foregroundStyle(.tertiary).lineLimit(1) }
                        }
                        Spacer()
                        Text(event.date,style:.date).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(15)
                    .frame(maxWidth:.infinity,alignment:.leading)
                    .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:15))
                }
            }
        }
    }
}

struct OrbitQueuePage: View {
    @EnvironmentObject private var operations:OrbitOperations
    @EnvironmentObject private var store:StoreModel
    @State private var selectedApps:Set<String>=[]
    private var bundles:[(String,String,[String])] {
        [
            ("Création & vidéo","Montage, capture et graphisme",["obsproject/obs-studio","HandBrake/HandBrake","iina/iina","blender/blender"]),
            ("Développement","Outils pour coder et tester",["microsoft/vscode","utmapp/UTM","dbeaver/dbeaver","VSCodium/vscodium"]),
            ("Multimédia","Lecteurs et utilitaires multimédias",["iina/iina","HandBrake/HandBrake","jellyfin/jellyfin-media-player"]),
            ("Vie privée","Sécurité et transferts",["keepassxreboot/keepassxc","cryptomator/cryptomator","localsend/localsend"])
        ]
    }
    var body:some View {
        VStack(alignment:.leading,spacing:20) {
            VStack(alignment:.leading,spacing:5) {
                Text("Gestion des installations").font(.system(size:34,weight:.bold,design:.rounded))
                Text("Installer plusieurs logiciels à la suite, contrôler les échecs et reprendre les opérations.")
                    .foregroundStyle(.secondary)
            }
            HStack {
                OrbitStatusPill(text:"\(operations.jobs.filter{!$0.finished}.count) en attente",icon:"list.bullet")
                OrbitStatusPill(text:"\(operations.jobs.filter{$0.phase=="Installée"}.count) réussies",icon:"checkmark.circle",tint:.green)
                Spacer()

            }
            if !operations.jobs.isEmpty {
                VStack(alignment:.leading,spacing:12) {
                    Text("File d'attente").font(.title2.bold())
                    ForEach(operations.jobs.reversed()) { job in
                        HStack(spacing:13) {
                            Image(systemName:job.phase=="Installée" ? "checkmark.circle.fill" :
                                    job.finished ? "exclamationmark.circle" : "arrow.down.circle")
                                .foregroundStyle(job.phase=="Installée" ? Color.green : Color.secondary)
                                .font(.title2)
                            VStack(alignment:.leading,spacing:4) {
                                Text(job.name).font(.headline)
                                Text("\(job.phase) · \(job.detail)")
                                    .font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            Spacer()
                        }
                        .padding(13).background(Color(nsColor:.controlBackgroundColor),
                                                in:RoundedRectangle(cornerRadius:13))
                    }
                }
            }
            Divider()
            Text("Collections installables").font(.title2.bold())
            Text("Chaque application du pack est vérifiée individuellement. Un logiciel incompatible ou non signé n'est pas installé silencieusement.")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns:[GridItem(.adaptive(minimum:260),spacing:14)],spacing:14) {
                ForEach(bundles,id:\.0) { pack in
                    VStack(alignment:.leading,spacing:12) {
                        Image(systemName:"square.stack.3d.up.fill").font(.title).foregroundStyle(.indigo)
                        Text(pack.0).font(.headline)
                        Text(pack.1).font(.caption).foregroundStyle(.secondary)
                        Text("\(pack.2.count) applications").font(.caption2).foregroundStyle(.secondary)
                        Button("Ajouter à la file") {
                            operations.enqueue(Inventory.catalog.filter{pack.2.contains($0.repo)},store:store)
                        }.buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth:.infinity,alignment:.leading)
                    .padding(18).background(Color(nsColor:.controlBackgroundColor),
                                            in:RoundedRectangle(cornerRadius:17))
                }
            }
            Divider()
            Text("Sélection personnalisée").font(.title2.bold())
            LazyVGrid(columns:[GridItem(.adaptive(minimum:180),spacing:8)],spacing:8) {
                ForEach(Inventory.catalog.prefix(30)) { entry in
                    Toggle(entry.name,isOn:Binding(
                        get:{selectedApps.contains(entry.repo)},
                        set:{enabled in if enabled {selectedApps.insert(entry.repo)} else {selectedApps.remove(entry.repo)} }
                    )).toggleStyle(.checkbox)
                }
            }
            HStack {
                Text("\(selectedApps.count) sélectionnées").foregroundStyle(.secondary)
                Spacer()
                Button("Installer la sélection") {
                    operations.enqueue(Inventory.catalog.filter{selectedApps.contains($0.repo)},store:store)
                    selectedApps=[]
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedApps.isEmpty)
            }
        }
    }
}

struct OrbitSourcesView: View {
    let entry:CatalogApp
    let installed:MacApp?
    @EnvironmentObject private var operations:OrbitOperations
    var body:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Sources de distribution").font(.headline)
            if let results=operations.sources[entry.repo] {
                ForEach(results,id:\.name) { result in
                    HStack {
                        Image(systemName:result.name=="GitHub" ? "chevron.left.forwardslash.chevron.right" :
                              "link.circle").foregroundStyle(.indigo)
                        VStack(alignment:.leading,spacing:3) {
                            Text(result.name).font(.subheadline.weight(.medium))
                            Text(result.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Consulter") { NSWorkspace.shared.open(result.url) }
                            .buttonStyle(.bordered)
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.23),in:RoundedRectangle(cornerRadius:10))
                }
            } else {
                ProgressView("Identification des sources…")
                    .task(id:entry.repo) { await operations.checkSources(for:entry,installed:installed) }
            }
            Text("Aucune source alternative n'est utilisée pour installer automatiquement tant que son identité et sa signature ne sont pas vérifiées.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct OrbitDiagnosisPanel: View {
    let app:MacApp
    @EnvironmentObject private var operations:OrbitOperations
    @EnvironmentObject private var store:StoreModel
    @State private var showUninstall=false
    @State private var showRollback=false
    @State private var showFiles=false
    var body:some View {
        VStack(alignment:.leading,spacing:13) {
            HStack {
                Text("OrbitDoctor").font(.title2.bold())
                Spacer()
                Button("Analyser") { operations.diagnose(app) }.buttonStyle(.bordered)
            }
            if let diagnostic=operations.diagnoses[app.path] {
                Grid(alignment:.leading,verticalSpacing:9) {
                    GridRow {
                        Text("Signature").foregroundStyle(.secondary)
                        Text(diagnostic.signature)
                        Text("Gatekeeper").foregroundStyle(.secondary)
                        Text(diagnostic.gatekeeper)
                    }
                    GridRow {
                        Text("Architecture").foregroundStyle(.secondary)
                        Text(diagnostic.architectures)
                        Text("Bundle ID").foregroundStyle(.secondary)
                        Text(diagnostic.bundleID).lineLimit(1)
                    }
                    if let sparkle=diagnostic.sparkle {
                        GridRow {
                            Text("Sparkle").foregroundStyle(.secondary)
                            Text(sparkle).lineLimit(1)
                            Text("").hidden()
                            Text("").hidden()
                        }
                    }
                }
                .font(.caption)
            } else {
                Text("Vérifie la signature macOS, le statut Gatekeeper, l'architecture et la présence d'un flux Sparkle.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(operations.diagnosticStatus).font(.caption).foregroundStyle(.secondary)
            HStack(spacing:10) {
                Button("Afficher les fichiers liés") { showFiles.toggle() }
                    .buttonStyle(.bordered)
                if operations.availableBackup(for:app) != nil {
                    Button("Version précédente") { showRollback=true }
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button("Désinstaller…",role:.destructive) { showUninstall=true }
                    .buttonStyle(.bordered)
            }
            if showFiles {
                let items=operations.residualPaths(for:app)
                Text(items.isEmpty ? "Aucun élément local standard recensé." : "Éléments personnels conservés lors de la désinstallation :")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(items,id:\.self) { Text($0).font(.caption2).textSelection(.enabled) }
            }
            Text("La désinstallation met l'app dans la Corbeille, sans supprimer tes réglages, documents ou caches.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(15).background(Color(nsColor:.controlBackgroundColor),
                                in:RoundedRectangle(cornerRadius:15))
        .alert("Désinstaller \(app.name) ?",isPresented:$showUninstall) {
            Button("Mettre à la Corbeille",role:.destructive) {
                operations.uninstall(app,store:store)
            }
            Button("Annuler",role:.cancel) {}
        } message: {
            Text("L'application sera mise dans la Corbeille. Ses données utilisateur seront conservées.")
        }
        .alert("Revenir à l'ancienne version ?",isPresented:$showRollback) {
            Button("Restaurer",role:.destructive) {
                operations.rollback(app,store:store)
            }
            Button("Annuler",role:.cancel) {}
        } message: {
            Text("Restaure uniquement le logiciel sauvegardé ; les données utilisateur ne seront pas restaurées.")
        }
        .task(id:app.path) { operations.diagnose(app) }
    }
}

struct OrbitInstallPreferences: View {
    @EnvironmentObject private var operations:OrbitOperations
    var body:some View {
        Section("Installation") {
            Picker("Dossier par défaut",selection:$operations.destinationChoice) {
                Text("Applications — /Applications").tag("/Applications")
                Text("Applications utilisateur — ~/Applications").tag("~/Applications")
                Text("Personnalisé").tag("Personnalisé")
            }
            if operations.destinationChoice=="Personnalisé" {
                HStack {
                    TextField("Dossier d'installation",text:$operations.customDirectory)
                    Button("Choisir…") {
                        let panel=NSOpenPanel()
                        panel.canChooseDirectories=true
                        panel.canChooseFiles=false
                        panel.canCreateDirectories=true
                        panel.prompt="Utiliser ce dossier"
                        if panel.runModal() == NSApplication.ModalResponse.OK, let selected=panel.url {
                            operations.customDirectory=selected.path
                        }
                    }
                }
            }
            Text("Les .app vérifiées sont copiées sans ouvrir le Finder lorsque macOS autorise l'écriture dans ce dossier. Les PKG et applications rejetées par Gatekeeper restent manuels.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Conserver les DMG et ZIP après l'installation",isOn:$operations.keepPackages)
            Toggle("Lancer le logiciel après l'installation",isOn:$operations.launchAfterInstall)
        }
        Section("Découverte & recommandations") {
            Toggle("Notifier une fois par jour les mises à jour détectées",isOn:$operations.digestEnabled)
            Text("Le récapitulatif fonctionne uniquement pendant qu'OrbitStore est ouvert. Il ne transmet pas la liste complète des logiciels installés.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
