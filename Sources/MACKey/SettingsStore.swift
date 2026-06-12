import Foundation
import AppKit
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var entries: [AppEntry] = []

    private let defaultsKey = "shortcut.entries.v1"

    /// How many leading Dock apps get an auto-assigned shortcut.
    static let autoAssignCount = 10

    /// Virtual key codes for the digit row 1,2,3,4,5,6,7,8,9,0 (in that order).
    private static let digitKeyCodes: [UInt32] = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29]

    func load() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([AppEntry].self, from: data) {
            entries = decoded
        } else {
            entries = DockReader.readApps()
        }
        assignDefaultShortcuts()
        persist()
    }

    func updateShortcut(for id: UUID, binding: ShortcutBinding?) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].shortcut = binding
        persist()
        ShortcutManager.shared.reloadAll(entries: entries)
    }

    func refreshFromDock() {
        let dockApps = DockReader.readApps()
        let existingByBundleID = Dictionary(uniqueKeysWithValues: entries.map { ($0.bundleIdentifier, $0) })
        // Preserve shortcuts for known apps; add new ones
        entries = dockApps.map { app in
            existingByBundleID[app.bundleIdentifier] ?? app
        }
        assignDefaultShortcuts()
        persist()
        ShortcutManager.shared.reloadAll(entries: entries)
    }

    // MARK: - Auto assignment (Snap-style ⌃1…⌃0 by Dock position)

    /// Assign ⌃1, ⌃2, … ⌃9, ⌃0 to the first N Dock apps that don't already
    /// have a user-set shortcut. Position drives the digit.
    private func assignDefaultShortcuts() {
        let control = NSEvent.ModifierFlags.control.rawValue
        let count = min(Self.autoAssignCount, entries.count)
        for i in 0..<count where entries[i].shortcut == nil {
            entries[i].shortcut = ShortcutBinding(
                keyCode: Self.digitKeyCodes[i],
                modifierFlags: control
            )
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
