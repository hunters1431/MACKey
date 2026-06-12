import AppKit
import SwiftUI

final class DonationWindowController: NSWindowController {
    static let shared = DonationWindowController()

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "支持 MACKey · Support MACKey"
        window.center()
        window.contentView = NSHostingView(rootView: DonationView())
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
