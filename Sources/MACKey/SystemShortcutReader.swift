import Foundation
import AppKit

// MARK: - Model

struct SystemShortcut: Identifiable {
    let id: Int                 // AppleSymbolicHotKeys numeric ID
    let name: String            // already localized for display
    let icon: String            // SF Symbol name
    let keyCode: UInt32
    let modifierFlags: UInt     // NSEvent.ModifierFlags raw value

    var displayString: String {
        ShortcutBinding(keyCode: keyCode, modifierFlags: modifierFlags).displayString
    }
}

// MARK: - Reader

/// Reads macOS's built-in global keyboard shortcuts.
///
/// `com.apple.symbolichotkeys.plist` only stores entries the user has touched;
/// factory defaults that were never changed (⌘Space, ⌘⇧5…) live as compiled-in
/// OS defaults. So we seed a built-in defaults table, then overlay the plist.
enum SystemShortcutReader {

    private static let shift:   UInt = 0x20000
    private static let control: UInt = 0x40000
    private static let option:  UInt = 0x80000
    private static let command: UInt = 0x100000

    private struct DefaultEntry {
        let nameKey: String
        let icon: String
        let keyCode: UInt32
        let modifierFlags: UInt
    }

    /// Factory defaults for well-known symbolic hotkey IDs.
    private static let defaults: [Int: DefaultEntry] = [
        60:  .init(nameKey: "sys.input.prev",           icon: "globe",                  keyCode: 49,  modifierFlags: control),
        61:  .init(nameKey: "sys.input.next",           icon: "globe",                  keyCode: 49,  modifierFlags: control | option),
        64:  .init(nameKey: "sys.spotlight",            icon: "magnifyingglass",        keyCode: 49,  modifierFlags: command),
        65:  .init(nameKey: "sys.spotlight.finder",     icon: "magnifyingglass",        keyCode: 49,  modifierFlags: command | option),
        28:  .init(nameKey: "sys.screenshot.file",      icon: "camera",                 keyCode: 20,  modifierFlags: command | shift),
        29:  .init(nameKey: "sys.screenshot.clip",      icon: "camera",                 keyCode: 20,  modifierFlags: control | command | shift),
        30:  .init(nameKey: "sys.screenshot.area.file", icon: "camera.viewfinder",      keyCode: 21,  modifierFlags: command | shift),
        31:  .init(nameKey: "sys.screenshot.area.clip", icon: "camera.viewfinder",      keyCode: 21,  modifierFlags: control | command | shift),
        184: .init(nameKey: "sys.screenshot.toolbar",   icon: "camera.on.rectangle",    keyCode: 23,  modifierFlags: command | shift),
        32:  .init(nameKey: "sys.mission",              icon: "rectangle.3.group",      keyCode: 126, modifierFlags: control),
        33:  .init(nameKey: "sys.appwindows",           icon: "macwindow.on.rectangle", keyCode: 125, modifierFlags: control),
        36:  .init(nameKey: "sys.showdesktop",          icon: "menubar.dock.rectangle", keyCode: 103, modifierFlags: 0),
        79:  .init(nameKey: "sys.space.left",           icon: "rectangle.split.3x1",    keyCode: 123, modifierFlags: control),
        81:  .init(nameKey: "sys.space.right",          icon: "rectangle.split.3x1",    keyCode: 124, modifierFlags: control),
    ]

    /// Extra name/icon for plist-only IDs not covered by `defaults`.
    private static let known: [Int: (key: String, icon: String)] = [
        7:   ("sys.menubar", "menubar.arrow.up.rectangle"),
        8:   ("sys.dock", "dock.rectangle"),
        27:  ("sys.windowtile", "rectangle.split.2x1"),
        118: ("sys.desktop1", "rectangle.split.3x1"),
        119: ("sys.desktop2", "rectangle.split.3x1"),
        120: ("sys.desktop3", "rectangle.split.3x1"),
        160: ("sys.launchpad", "square.grid.3x3"),
        162: ("sys.launchpad", "square.grid.3x3"),
        163: ("sys.notification", "bell"),
        175: ("sys.dictation", "mic"),
        179: ("sys.dnd", "moon"),
        190: ("sys.spotlightFocus", "magnifyingglass"),
        222: ("sys.quicknote", "note.text"),
    ]

    /// Effective enabled system shortcuts: built-in defaults overlaid with the user's plist.
    static func readEnabled() -> [SystemShortcut] {
        var map: [Int: SystemShortcut] = [:]

        for (id, d) in defaults {
            map[id] = SystemShortcut(id: id, name: L(d.nameKey), icon: d.icon,
                                     keyCode: d.keyCode, modifierFlags: d.modifierFlags)
        }

        if let hotkeys = loadPlistHotkeys() {
            for (key, raw) in hotkeys {
                guard let id = Int(key), let dict = raw as? [String: Any] else { continue }

                let enabled = (dict["enabled"] as? Bool) ?? false
                if !enabled {
                    map.removeValue(forKey: id)
                    continue
                }

                if let value = dict["value"] as? [String: Any],
                   let params = value["parameters"] as? [Any],
                   params.count >= 3,
                   let kc = params[1] as? NSNumber,
                   let md = params[2] as? NSNumber,
                   kc.uint32Value != 65535 {
                    let name: String
                    let icon: String
                    if let d = defaults[id] {
                        name = L(d.nameKey); icon = d.icon
                    } else if let k = known[id] {
                        name = L(k.key); icon = k.icon
                    } else {
                        name = L("sys.unknown", id); icon = "command"
                    }
                    map[id] = SystemShortcut(id: id, name: name, icon: icon,
                                             keyCode: kc.uint32Value,
                                             modifierFlags: UInt(truncatingIfNeeded: md.intValue))
                }
            }
        }

        return map.values.sorted { $0.id < $1.id }
    }

    /// Find the system shortcut matching a given binding, if any.
    static func match(_ binding: ShortcutBinding) -> SystemShortcut? {
        let mask: NSEvent.ModifierFlags = [.command, .option, .shift, .control]
        let target = NSEvent.ModifierFlags(rawValue: binding.modifierFlags).intersection(mask)
        return readEnabled().first { sc in
            let scMods = NSEvent.ModifierFlags(rawValue: sc.modifierFlags).intersection(mask)
            return sc.keyCode == binding.keyCode && scMods == target
        }
    }

    // MARK: Private

    private static func loadPlistHotkeys() -> [String: Any]? {
        let path = NSHomeDirectory() + "/Library/Preferences/com.apple.symbolichotkeys.plist"
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let hotkeys = plist["AppleSymbolicHotKeys"] as? [String: Any]
        else { return nil }
        return hotkeys
    }
}
