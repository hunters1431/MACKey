import AppKit
import ServiceManagement

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var settingsWindowController: SettingsWindowController?
    private var launchItem: NSMenuItem?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupButton()
        setupMenu()
    }

    // MARK: - Setup

    private func setupButton() {
        guard let button = statusItem.button else { return }
        // Prominent "⌘K" wordmark in the menu bar (adapts to light/dark via labelColor).
        let size: CGFloat = 14
        let base = NSFont.systemFont(ofSize: size, weight: .semibold)
        let font = (base.fontDescriptor.withDesign(.rounded)).flatMap {
            NSFont(descriptor: $0, size: size)
        } ?? base
        button.attributedTitle = NSAttributedString(string: "⌘K", attributes: [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ])
        button.image = nil
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let settingsItem = NSMenuItem(
            title: L("menu.settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let refreshItem = NSMenuItem(
            title: L("menu.refresh"),
            action: #selector(refreshFromDock),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let launch = NSMenuItem(
            title: L("menu.launch"),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launch.target = self
        menu.addItem(launch)
        launchItem = launch

        menu.addItem(.separator())

        let donateItem = NSMenuItem(
            title: L("menu.support"),
            action: #selector(openDonation),
            keyEquivalent: ""
        )
        donateItem.target = self
        menu.addItem(donateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L("menu.quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func refreshFromDock() {
        SettingsStore.shared.refreshFromDock()
    }

    @objc private func openDonation() {
        DonationWindowController.shared.show()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("MACKey: launch-at-login toggle failed: \(error)")
        }
        updateLaunchItemState()
    }

    private func updateLaunchItemState() {
        launchItem?.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
    }
}

// MARK: - NSMenuDelegate

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateLaunchItemState()
    }
}
