import SwiftUI
import AppKit

/// Updater UX for OrbitStore itself. This intentionally does not auto-replace
/// ad-hoc signed builds that macOS Gatekeeper has not authorized.
struct OrbitSelfUpdateCard: View {
    @EnvironmentObject private var updater: OrbitSelfUpdater
    var compact = false

    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            HStack(alignment:.top,spacing:14) {
                Image(systemName:"arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size:compact ? 28 : 38))
                    .foregroundStyle(.indigo)
                VStack(alignment:.leading,spacing:5) {
                    Text("Mettre à jour OrbitStore")
                        .font(compact ? .headline : .title2.bold())
                    Text("Version actuelle : \(updater.currentVersion)")
                        .foregroundStyle(.secondary).font(.subheadline)
                }
                Spacer()
                if updater.isChecking || updater.isDownloading {
                    ProgressView().controlSize(.small)
                }
                Button("Vérifier") { Task { await updater.check(force:true) } }
                    .buttonStyle(.bordered)
                    .disabled(updater.isChecking || updater.isDownloading)
            }
            Text(updater.status)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(updater.availableVersion == nil ? Color.secondary : Color.green)
            if let version=updater.availableVersion {
                HStack {
                    Label("Nouvelle version \(version)",systemImage:"checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button(updater.isDownloading ? "Téléchargement…" : "Télécharger la mise à jour") {
                        Task { await updater.downloadAndOpen() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(updater.isDownloading || updater.isChecking)
                }
                if !compact && !updater.notes.isEmpty {
                    Text("Notes de publication").font(.headline)
                    Text(updater.notes)
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(6)
                }
            }
            if let error=updater.error {
                Label(error,systemImage:"exclamationmark.triangle")
                    .foregroundStyle(.orange).font(.caption)
            }
            if updater.downloadedDMG != nil {
                HStack {
                    Label("DMG contrôlé par SHA-256 et téléchargé",systemImage:"checkmark.shield.fill")
                        .foregroundStyle(.green).font(.caption)
                    Spacer()
                    Button("Afficher dans le Finder") { updater.revealDownloaded() }
                        .buttonStyle(.bordered)
                }
            }
            HStack(alignment:.top,spacing:9) {
                Image(systemName:"info.circle").foregroundStyle(.secondary)
                Text("Les versions d'OrbitStore sont signées ad hoc et non notarisées. Après le téléchargement, ouvre le DMG, ferme OrbitStore puis remplace l'application dans Applications. L'autorisation éventuelle de macOS reste nécessaire.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let page=updater.releasePage {
                Button("Voir la release GitHub") { NSWorkspace.shared.open(page) }
                    .buttonStyle(.link)
            }
        }
        .padding(compact ? 14 : 19)
        .background(Color(nsColor:.controlBackgroundColor),
                    in:RoundedRectangle(cornerRadius:18))
    }
}
