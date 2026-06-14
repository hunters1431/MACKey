import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance guard: if another MACKey is already running, this copy
        // would fail to register the global hotkeys (slots already taken), so bow out.
        if let bundleID = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
            NSApp.terminate(nil)
            return
        }

        requestAccessibilityIfNeeded()
        Theme.shared.load()
        SettingsStore.shared.load()   // registers all hotkeys internally
        statusBarController = StatusBarController()
    }

    private func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
