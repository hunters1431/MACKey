import AppKit
import Carbon
import HotKey

// MARK: - Conflict Result

enum ConflictResult {
    case none
    case sameApp(name: String)        // another entry in our own store owns this combo
    case systemNamed(name: String)    // matches a known macOS system shortcut
    case system                       // taken by macOS / a third-party app (unidentified)
}

// MARK: - ShortcutManager

final class ShortcutManager {
    static let shared = ShortcutManager()

    // Hold strong references — HotKey deregisters on dealloc
    private var hotKeys: [UUID: HotKey] = [:]

    // MARK: Reload / Register / Unregister

    func reloadAll(entries: [AppEntry]) {
        hotKeys.removeAll()
        entries.filter { $0.shortcut != nil }.forEach { register($0) }
    }

    func register(_ entry: AppEntry) {
        guard
            let binding = entry.shortcut,
            let key = Key(carbonKeyCode: binding.keyCode)
        else { return }

        let modifiers = NSEvent.ModifierFlags(rawValue: binding.modifierFlags)
        let hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey.keyDownHandler = { [weak self] in
            self?.activateOrLaunch(entry: entry)
        }
        hotKeys[entry.id] = hotKey
    }

    func unregister(id: UUID) {
        hotKeys.removeValue(forKey: id)
    }

    // MARK: Conflict Detection

    /// Check whether a binding conflicts with our own entries or a system/third-party registration.
    /// Pass `excludingID` for the entry currently being edited so we don't report it as a self-conflict.
    func checkConflict(binding: ShortcutBinding, excludingID: UUID? = nil) -> ConflictResult {
        // 1. Check our own active entries first (fast, no Carbon call needed)
        let entries = SettingsStore.shared.allBindings
        for entry in entries {
            guard entry.id != excludingID else { continue }
            if entry.shortcut == binding {
                return .sameApp(name: entry.name)
            }
        }

        // 2. Check macOS system shortcuts — these can be named precisely.
        if let sys = SystemShortcutReader.match(binding) {
            return .systemNamed(name: sys.name)
        }

        // 3. Temporarily unregister OUR hotkey for the excluded entry so the Carbon
        //    probe doesn't see our own registration as a conflict.
        var savedHotKey: HotKey?
        if let id = excludingID {
            savedHotKey = hotKeys[id]
            hotKeys.removeValue(forKey: id)
        }
        defer {
            // Restore after probe
            if let id = excludingID, let saved = savedHotKey {
                hotKeys[id] = saved
            }
        }

        // 4. Try to register via Carbon — if it fails the slot is taken by another app
        if carbonSlotTaken(keyCode: binding.keyCode, modifierFlags: binding.modifierFlags) {
            return .system
        }

        return .none
    }

    // MARK: Private helpers

    private func carbonSlotTaken(keyCode: UInt32, modifierFlags: UInt) -> Bool {
        let mods = NSEvent.ModifierFlags(rawValue: modifierFlags)
        var carbonMods: UInt32 = 0
        if mods.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if mods.contains(.option)  { carbonMods |= UInt32(optionKey) }
        if mods.contains(.shift)   { carbonMods |= UInt32(shiftKey) }
        if mods.contains(.control) { carbonMods |= UInt32(controlKey) }

        // Probe signature: "SHRT" = 0x53485254
        let hotKeyID = EventHotKeyID(signature: 0x53485254, id: 0xFFFE)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode, carbonMods, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if status == OSStatus(noErr) {
            UnregisterEventHotKey(hotKeyRef!)
            return false   // successfully registered ⇒ slot is free
        }
        return true        // registration failed ⇒ slot is taken
    }

    private func activateOrLaunch(entry: AppEntry) {
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == entry.bundleIdentifier
        }) {
            running.activate(options: [.activateAllWindows])
        } else {
            let rawPath = entry.appPath
            let path = rawPath.hasPrefix("file://")
                ? (URL(string: rawPath)?.path ?? rawPath)
                : rawPath
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: path),
                configuration: .init()
            ) { _, _ in }
        }
    }
}
