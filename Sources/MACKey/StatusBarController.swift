import AppKit
import ServiceManagement

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var settingsWindowController: SettingsWindowController?
    private var launchItem: NSMenuItem?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        setupButton()
        setupMenu()
    }

    // MARK: - Setup

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "MACKey")
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let settingsItem = NSMenuItem(
            title: "设置快捷键…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let refreshItem = NSMenuItem(
            title: "从 Dock 刷新应用列表",
            action: #selector(refreshFromDock),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let launch = NSMenuItem(
            title: "开机时启动",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launch.target = self
        menu.addItem(launch)
        launchItem = launch

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 MACKey",
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
