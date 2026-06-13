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
        27:  ("sys.windowcycle", "macwindow.on.rectangle"),
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

    // MARK: - Curated frequency-ranked list (Column ①)

    private struct CuratedItem {
        let rank: Int
        let nameKey: String
        let icon: String
        let symbolicID: Int?      // nil = hard-wired (not user-customizable)
        let keyCode: UInt32
        let modifierFlags: UInt
    }

    /// The reference list shown in Column ①, ordered by recommended usage frequency.
    /// Symbolic-hotkey-backed items reflect the user's customizations (read from plist);
    /// hard-wired items (⌘Tab, lock, force-quit) are fixed.
    private static let curated: [CuratedItem] = [
        .init(rank: 1,  nameKey: "sys.spotlight",            icon: "magnifyingglass",        symbolicID: 64,  keyCode: 49,  modifierFlags: command),
        .init(rank: 2,  nameKey: "sys.appswitch",           icon: "square.stack.3d.up",     symbolicID: nil, keyCode: 48,  modifierFlags: command),
        .init(rank: 3,  nameKey: "sys.screenshot.area.file", icon: "camera.viewfinder",     symbolicID: 30,  keyCode: 21,  modifierFlags: command | shift),
        .init(rank: 4,  nameKey: "sys.screenshot.toolbar",  icon: "camera.on.rectangle",    symbolicID: 184, keyCode: 23,  modifierFlags: command | shift),
        .init(rank: 5,  nameKey: "sys.screenshot.file",     icon: "camera",                 symbolicID: 28,  keyCode: 20,  modifierFlags: command | shift),
        .init(rank: 6,  nameKey: "sys.input.prev",          icon: "globe",                  symbolicID: 60,  keyCode: 49,  modifierFlags: control),
        .init(rank: 7,  nameKey: "sys.windowcycle",         icon: "macwindow.on.rectangle", symbolicID: 27,  keyCode: 50,  modifierFlags: command),
        .init(rank: 8,  nameKey: "sys.lockscreen",          icon: "lock",                   symbolicID: nil, keyCode: 12,  modifierFlags: control | command),
        .init(rank: 9,  nameKey: "sys.forcequit",           icon: "xmark.octagon",          symbolicID: nil, keyCode: 53,  modifierFlags: option | command),
        .init(rank: 10, nameKey: "sys.mission",             icon: "rectangle.3.group",      symbolicID: 32,  keyCode: 126, modifierFlags: control),
        .init(rank: 11, nameKey: "sys.showdesktop",         icon: "menubar.dock.rectangle", symbolicID: 36,  keyCode: 103, modifierFlags: 0),
        .init(rank: 12, nameKey: "sys.spotlight.finder",    icon: "magnifyingglass",        symbolicID: 65,  keyCode: 49,  modifierFlags: command | option),
        .init(rank: 13, nameKey: "sys.dockhide",            icon: "dock.rectangle",         symbolicID: 52,  keyCode: 2,   modifierFlags: option | command),
        .init(rank: 14, nameKey: "sys.space.right",         icon: "rectangle.split.3x1",    symbolicID: 81,  keyCode: 124, modifierFlags: control),
        .init(rank: 15, nameKey: "sys.space.left",          icon: "rectangle.split.3x1",    symbolicID: 79,  keyCode: 123, modifierFlags: control),
        .init(rank: 16, nameKey: "sys.appwindows",          icon: "macwindow.on.rectangle", symbolicID: 33,  keyCode: 125, modifierFlags: control),
        .init(rank: 17, nameKey: "sys.input.next",          icon: "globe",                  symbolicID: 61,  keyCode: 49,  modifierFlags: control | option),
        .init(rank: 18, nameKey: "sys.screenshot.area.clip", icon: "camera.viewfinder",     symbolicID: 31,  keyCode: 21,  modifierFlags: control | command | shift),
        .init(rank: 19, nameKey: "sys.screenshot.clip",     icon: "camera",                 symbolicID: 29,  keyCode: 20,  modifierFlags: control | command | shift),
        .init(rank: 20, nameKey: "sys.desktop1",            icon: "rectangle.split.3x1",    symbolicID: 118, keyCode: 18,  modifierFlags: control),
    ]

    /// Column ① content: the curated 20.
    /// App Store build uses factory defaults only (no plist access required by sandbox).
    /// GitHub build overlays user customizations from symbolichotkeys.plist.
    static func curatedList() -> [SystemShortcut] {
        #if APPSTORE
        return curated.map { item in
            SystemShortcut(id: item.rank, name: L(item.nameKey), icon: item.icon,
                           keyCode: item.keyCode, modifierFlags: item.modifierFlags)
        }
        #else
        let plist = loadPlistHotkeys()
        return curated.map { item in
            var kc = item.keyCode
            var mf = item.modifierFlags
            if let id = item.symbolicID,
               let hk = plist?[String(id)] as? [String: Any],
               (hk["enabled"] as? Bool) == true,
               let v = hk["value"] as? [String: Any],
               let p = v["parameters"] as? [Any], p.count >= 3,
               let k = p[1] as? NSNumber, let m = p[2] as? NSNumber,
               k.uint32Value != 65535 {
                kc = k.uint32Value
                mf = UInt(truncatingIfNeeded: m.intValue)
            }
            return SystemShortcut(id: item.rank, name: L(item.nameKey), icon: item.icon,
                                  keyCode: kc, modifierFlags: mf)
        }
        #endif
    }

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

    private static var plistCacheTime: Date = .distantPast
    private static var plistCache: [String: Any]? = nil

    private static func loadPlistHotkeys() -> [String: Any]? {
        if Date().timeIntervalSince(plistCacheTime) < 5 { return plistCache }
        let path = NSHomeDirectory() + "/Library/Preferences/com.apple.symbolichotkeys.plist"
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let hotkeys = plist["AppleSymbolicHotKeys"] as? [String: Any]
        else {
            plistCacheTime = Date()
            plistCache = nil
            return nil
        }
        plistCacheTime = Date()
        plistCache = hotkeys
        return hotkeys
    }
}
