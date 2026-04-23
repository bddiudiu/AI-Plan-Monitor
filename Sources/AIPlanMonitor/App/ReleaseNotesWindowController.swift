import AppKit
import WebKit

@MainActor
final class ReleaseNotesWindowController: NSObject, NSWindowDelegate {
    static let shared = ReleaseNotesWindowController()

    private var window: NSWindow?
    private var webView: WKWebView?

    private override init() {
        super.init()
    }

    func show(releaseNotes: PendingPostUpdateReleaseNotes) {
        let window = ensureWindow()
        window.title = title(for: releaseNotes.version)
        load(releaseNotes.displayURL)
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func ensureWindow() -> NSWindow {
        if let window {
            return window
        }

        let webView = WKWebView(frame: .zero)
        webView.setValue(false, forKey: "drawsBackground")
        self.webView = webView

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .visible
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.minSize = NSSize(width: 700, height: 480)
        panel.contentView = webView
        self.window = panel
        return panel
    }

    private func load(_ url: URL) {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        webView?.load(request)
    }

    private func title(for version: String) -> String {
        if Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true {
            return "AI Plan Monitor \(version) 更新说明"
        }
        return "AI Plan Monitor \(version) Release Notes"
    }
}
