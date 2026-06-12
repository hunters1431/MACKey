import Foundation
import AppKit

// MARK: - Model

struct SystemShortcut: Identifiable {
    let id: Int                 // AppleSymbolicHotKeys numeric ID
    let name: String
    let keyCode: UInt32
    let modifierFlags: UInt     // NSEvent.ModifierFlags raw value

    var displayString: String {
        ShortcutBinding(keyCode: keyCode, modifierFlags: modifierFlags).displayString
    }
}

// MARK: - Reader

/// Reads macOS's built-in global keyboard shortcuts.
///
/// Key insight: `com.apple.symbolichotkeys.plist` only stores entries the user has
/// **touched** (re-mapped or toggled). Factory-default shortcuts that were never
/// changed (e.g. ⌘Space Spotlight, ⌘⇧5 screenshot) are NOT in the plist at all —
/// they live as compiled-in OS defaults. So we seed a built-in defaults table first,
/// then overlay the plist to reflect the user's customizations and disables.
enum SystemShortcutReader {

    // NSEvent.ModifierFlags raw bits
    private static let shift:   UInt = 0x20000
    private static let control: UInt = 0x40000
    private static let option:  UInt = 0x80000
    private static let command: UInt = 0x100000

    private struct DefaultEntry {
        let name: String
        let keyCode: UInt32
        let modifierFlags: UInt
    }

    /// Factory defaults for the well-known symbolic hotkey IDs (assumed enabled
    /// unless the plist explicitly disables them).
    private static let defaults: [Int: DefaultEntry] = [
        60:  .init(name: "切换到上一个输入法",      keyCode: 49,  modifierFlags: control),
        61:  .init(name: "切换到下一个输入法",      keyCode: 49,  modifierFlags: control | option),
        64:  .init(name: "Spotlight 聚焦搜索",       keyCode: 49,  modifierFlags: command),
        65:  .init(name: "Spotlight 访达搜索窗口",   keyCode: 49,  modifierFlags: command | option),
        28:  .init(name: "截屏并存为文件",          keyCode: 20,  modifierFlags: command | shift),
        29:  .init(name: "截屏并拷贝到剪贴板",      keyCode: 20,  modifierFlags: control | command | shift),
        30:  .init(name: "区域截屏并存为文件",      keyCode: 21,  modifierFlags: command | shift),
        31:  .init(name: "区域截屏并拷贝",          keyCode: 21,  modifierFlags: control | command | shift),
        184: .init(name: "截屏与录屏工具栏",        keyCode: 23,  modifierFlags: command | shift),
        32:  .init(name: "调度中心",                keyCode: 126, modifierFlags: control),
        33:  .init(name: "应用程序窗口",            keyCode: 125, modifierFlags: control),
        36:  .init(name: "显示桌面",                keyCode: 103, modifierFlags: 0),
        79:  .init(name: "移到左侧的空间",          keyCode: 123, modifierFlags: control),
        81:  .init(name: "移到右侧的空间",          keyCode: 124, modifierFlags: control),
    ]

    /// Extra human-readable names for plist-only IDs not covered by `defaults`.
    private static let knownNames: [Int: String] = [
        7: "聚焦菜单栏", 8: "聚焦 Dock", 27: "上一窗口分区",
        118: "切换到桌面 1", 119: "切换到桌面 2", 120: "切换到桌面 3",
        160: "启动台", 162: "启动台", 163: "通知中心",
        175: "听写", 179: "勿扰模式", 190: "聚焦", 222: "快速备忘录",
    ]

    /// Effective enabled system shortcuts: built-in defaults overlaid with the user's plist.
    static func readEnabled() -> [SystemShortcut] {
        var map: [Int: SystemShortcut] = [:]

        // 1. Seed from compiled-in defaults.
        for (id, d) in defaults {
            map[id] = SystemShortcut(id: id, name: d.name, keyCode: d.keyCode, modifierFlags: d.modifierFlags)
        }

        // 2. Overlay the user's plist (customizations + disables).
        if let hotkeys = loadPlistHotkeys() {
            for (key, raw) in hotkeys {
                guard let id = Int(key), let dict = raw as? [String: Any] else { continue }

                let enabled = (dict["enabled"] as? Bool) ?? false
                if !enabled {
                    map.removeValue(forKey: id)   // user turned it off
                    continue
                }

                // Enabled with a real custom key binding → override.
                if let value = dict["value"] as? [String: Any],
                   let params = value["parameters"] as? [Any],
                   params.count >= 3,
                   let kc = params[1] as? NSNumber,
                   let md = params[2] as? NSNumber,
                   kc.uint32Value != 65535 {
                    let name = defaults[id]?.name ?? knownNames[id] ?? "系统快捷键 #\(id)"
                    map[id] = SystemShortcut(
                        id: id,
                        name: name,
                        keyCode: kc.uint32Value,
                        modifierFlags: UInt(truncatingIfNeeded: md.intValue)
                    )
                }
                // Enabled but no usable key: keep the seeded default if any.
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
