import Foundation
import AppKit
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    /// Column ③ — first N Dock apps, auto-assigned ⌃1…⌃0.
    @Published var entries: [AppEntry] = []
    /// Column ② — user-curated apps with arbitrary custom shortcuts.
    @Published var customEntries: [AppEntry] = []

    private let defaultsKey = "shortcut.entries.v1"
    private let customKey = "mackey.custom.v1"

    /// How many leading Dock apps get an auto-assigned shortcut.
    static let autoAssignCount = 10

    /// Virtual key codes for the digit row 1,2,3,4,5,6,7,8,9,0 (in that order).
    private static let digitKeyCodes: [UInt32] = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29]

    /// All active bindings across both columns — what ShortcutManager registers / checks.
    var allBindings: [AppEntry] { entries + customEntries }

    // MARK: - Load

    func load() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([AppEntry].self, from: data) {
            entries = decoded
        } else {
            entries = DockReader.readApps()
        }
        if let data = UserDefaults.standard.data(forKey: customKey),
           let decoded = try? JSONDecoder().decode([AppEntry].self, from: data) {
            customEntries = decoded
        }
        assignDefaultShortcuts()
        persist()
        reloadHotKeys()
    }

    // MARK: - Column ③ (Dock) mutations

    func updateShortcut(for id: UUID, binding: ShortcutBinding?) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].shortcut = binding
        persist()
        reloadHotKeys()
    }

    /// Re-read the Dock and renumber ⌃1…⌃0 strictly by the new position.
    /// Unlike startup load (which preserves saved bindings), an explicit refresh
    /// resyncs the column to the current Dock order, overwriting the first 10.
    func refreshFromDock() {
        entries = DockReader.readApps()
        reassignDockShortcuts()
        persist()
        reloadHotKeys()
    }

    private func reassignDockShortcuts() {
        let control = NSEvent.ModifierFlags.control.rawValue
        for i in entries.indices where i < Self.autoAssignCount {
            entries[i].shortcut = ShortcutBinding(keyCode: Self.digitKeyCodes[i], modifierFlags: control)
        }
    }

    // MARK: - Column ② (custom) mutations

    /// Add an .app chosen by the user; ignores duplicates by bundle id.
    @discardableResult
    func addCustomApp(at url: URL) -> Bool {
        let bundle = Bundle(url: url)
        let bundleID = bundle?.bundleIdentifier ?? url.standardizedFileURL.path
        guard !customEntries.contains(where: { $0.bundleIdentifier == bundleID }) else { return false }

        let name = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
            ?? FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")

        customEntries.append(AppEntry(name: name, bundleIdentifier: bundleID, appPath: url.path))
        persist()
        reloadHotKeys()
        return true
    }

    func updateCustomShortcut(for id: UUID, binding: ShortcutBinding?) {
        guard let idx = customEntries.firstIndex(where: { $0.id == id }) else { return }
        customEntries[idx].shortcut = binding
        persist()
        reloadHotKeys()
    }

    func removeCustomEntry(id: UUID) {
        customEntries.removeAll { $0.id == id }
        persist()
        reloadHotKeys()
    }

    /// Manual drag-to-reorder of column ② (order is cosmetic; bindings unchanged).
    func moveCustomEntry(from source: IndexSet, to destination: Int) {
        customEntries.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    // MARK: - Auto assignment (Snap-style ⌃1…⌃0 by Dock position)

    private func assignDefaultShortcuts() {
        let control = NSEvent.ModifierFlags.control.rawValue
        let count = min(Self.autoAssignCount, entries.count)
        for i in 0..<count where entries[i].shortcut == nil {
            entries[i].shortcut = ShortcutBinding(keyCode: Self.digitKeyCodes[i], modifierFlags: control)
        }
    }

    // MARK: - Persistence & registration

    private func reloadHotKeys() {
        ShortcutManager.shared.reloadAll(entries: allBindings)
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: defaultsKey) }
        if let d = try? JSONEncoder().encode(customEntries) { UserDefaults.standard.set(d, forKey: customKey) }
    }
}
