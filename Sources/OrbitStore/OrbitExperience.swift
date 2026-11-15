import SwiftUI
import AppKit

/// A compact, persistent confirmation surface that never hides behind the
/// Dock: it is laid out in the scroll view's safe-area inset.
struct OrbitActivityBar:View {
    @EnvironmentObject private var operations:OrbitOperations
    let showQueue:()->Void

    private var active:[OrbitJob] { operations.jobs.filter{!$0.finished} }
    var body:some View {
        if !active.isEmpty || operations.lastFeedback != nil {
            HStack(spacing:12) {
                if !active.isEmpty {
                    ProgressView().controlSize(.small)
                } else if let feedback=operations.lastFeedback {
                    Image(systemName:feedback.kind == .success ? "checkmark.circle.fill" :
                              feedback.kind == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundStyle(feedback.kind == .success ? Color.green :
                                         feedback.kind == .warning ? Color.orange : Color.indigo)
                        .font(.title3)
                }
                VStack(alignment:.leading,spacing:3) {
                    Text(active.isEmpty ? (operations.lastFeedback?.title ?? "Action enregistrée")
                         : "\(active.count) installation(s) en cours")
                        .font(.subheadline.weight(.semibold))
                    Text(active.last.map{"\($0.name) · \($0.phase) — \($0.detail)"} ??
                         operations.lastFeedback?.message ?? "")
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength:6)
                Button("Suivre") { showQueue() }
                    .buttonStyle(.bordered)
                Button { operations.clearFeedback() } label: {
                    Image(systemName:"xmark")
                        .font(.caption)
                        .frame(width:24,height:24)
                }.buttonStyle(.plain)
                    .help("Masquer le message")
            }
            .padding(.horizontal,18).padding(.vertical,12)
            .background(.regularMaterial)
            .overlay(alignment:.top) { Divider() }
            .accessibilityElement(children:.contain)
        }
    }
}

/// Always constrain the main window to macOS' visible screen area. The
/// visible frame excludes the menu bar and Dock; no private API is used.
struct OrbitWindowBoundsGuard:NSViewRepresentable {
    func makeNSView(context:Context)->WindowAwareView { WindowAwareView() }
    func updateNSView(_ view:WindowAwareView,context:Context) {}
    final class WindowAwareView:NSView {
        private var move:NSObjectProtocol?
        private var resize:NSObjectProtocol?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let move { NotificationCenter.default.removeObserver(move) }
            if let resize { NotificationCenter.default.removeObserver(resize) }
            guard let window else { return }
            let center=NotificationCenter.default
            move=center.addObserver(forName:NSWindow.didMoveNotification,object:window,queue:.main){ [weak self] _ in self?.limitWindow() }
            resize=center.addObserver(forName:NSWindow.didResizeNotification,object:window,queue:.main){ [weak self] _ in self?.limitWindow() }
            DispatchQueue.main.async { [weak self] in self?.limitWindow() }
        }
        private func limitWindow() {
            guard let window, !window.styleMask.contains(.fullScreen),
                  let screen=window.screen ?? NSScreen.main else { return }
            let visible=screen.visibleFrame.insetBy(dx:5,dy:5)
            var frame=window.frame
            let newWidth=min(frame.width,visible.width)
            let newHeight=min(frame.height,visible.height)
            frame.size=NSSize(width:newWidth,height:newHeight)
            frame.origin.x=min(max(frame.origin.x,visible.minX),visible.maxX-frame.width)
            frame.origin.y=min(max(frame.origin.y,visible.minY),visible.maxY-frame.height)
            if abs(frame.origin.x-window.frame.origin.x)>1 ||
               abs(frame.origin.y-window.frame.origin.y)>1 ||
               abs(frame.width-window.frame.width)>1 ||
               abs(frame.height-window.frame.height)>1 {
                window.setFrame(frame,display:true,animate:false)
            }
        }
        deinit {
            if let move { NotificationCenter.default.removeObserver(move) }
            if let resize { NotificationCenter.default.removeObserver(resize) }
        }
    }
}

/// Richer editorial storefront sections. Real repository/project imagery is
/// loaded by AuthenticAppIcon, not generated or substitute app logos.
struct OrbitFeaturedStrip:View {
    let entries:[CatalogApp]
    let store:StoreModel
    let open:(CatalogApp)->Void
    var body:some View {
        if !entries.isEmpty {
            VStack(alignment:.leading,spacing:14) {
                HStack {
                    Label("La sélection OrbitStore",systemImage:"sparkles")
                        .font(.title2.bold())
                    Spacer()
                    Text("Des applications à découvrir")
                        .font(.caption).foregroundStyle(.secondary)
                }
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:13) {
                        ForEach(entries.prefix(8)) { entry in
                            Button { open(entry) } label: {
                                VStack(alignment:.leading,spacing:13) {
                                    HStack {
                                        AuthenticAppIcon(repo:entry.repo,name:entry.name,
                                            installedPath:store.matches(entry).first?.path,
                                            branch:store.info[entry.repo]?.default_branch,
                                            homepage:store.info[entry.repo]?.homepage,size:63)
                                        Spacer()
                                        Image(systemName:"arrow.up.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(entry.name)
                                        .font(.headline).foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(store.catalogDescription(entry))
                                        .font(.caption).foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .frame(height:34,alignment:.topLeading)
                                    HStack {
                                        Text(entry.category).lineLimit(1)
                                        Spacer()
                                        if store.catalogStars(entry)>0 {
                                            Label(store.catalogStars(entry).formatted(.number.notation(.compactName)),
                                                  systemImage:"star.fill")
                                        }
                                    }
                                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                                }
                                .padding(17)
                                .frame(width:236,height:193,alignment:.topLeading)
                                .background(Color(nsColor:.controlBackgroundColor),
                                            in:RoundedRectangle(cornerRadius:18))
                                .overlay(RoundedRectangle(cornerRadius:18)
                                            .stroke(Color.primary.opacity(0.06)))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical,3)
                }
            }
        }
    }
}

struct OrbitCategoryShortcut:View {
    let title:String
    let subtitle:String
    let icon:String
    let color:Color
    let action:()->Void
    var body:some View {
        Button(action:action) {
            HStack(spacing:12) {
                Image(systemName:icon).font(.title3)
                    .frame(width:43,height:43)
                    .foregroundStyle(color)
                    .background(color.opacity(0.12),in:RoundedRectangle(cornerRadius:12))
                VStack(alignment:.leading,spacing:3) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength:3)
                Image(systemName:"chevron.right")
                    .font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(13)
            .frame(maxWidth:.infinity)
            .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:15))
        }.buttonStyle(.plain)
    }
}
