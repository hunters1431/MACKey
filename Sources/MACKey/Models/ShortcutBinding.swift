import Foundation
import AppKit

struct ShortcutBinding: Codable, Equatable {
    let keyCode: UInt32
    let modifierFlags: UInt  // NSEvent.ModifierFlags.rawValue

    var displayString: String {
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option)  { parts.append("⌥") }
        if flags.contains(.shift)   { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(Self.keyCodeName(keyCode))
        return parts.joined(separator: " + ")
    }

    static func keyCodeName(_ code: UInt32) -> String {
        let map: [UInt32: String] = [
            // Letter row
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "§", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space", 50: "`",
            51: "⌫", 53: "Esc", 36: "↩", 76: "⌤", 117: "⌦",
            115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
            // F-keys
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 109: "F10", 111: "F12",
            118: "F4", 120: "F2", 122: "F1",
            105: "F13", 107: "F14", 113: "F15", 106: "F16",
            64: "F17", 79: "F18", 80: "F19", 90: "F20",
            // Numpad
            65: "⌗.", 67: "⌗*", 69: "⌗+", 71: "⌧", 75: "⌗/",
            78: "⌗-", 81: "⌗=",
            82: "⌗0", 83: "⌗1", 84: "⌗2", 85: "⌗3", 86: "⌗4",
            87: "⌗5", 88: "⌗6", 89: "⌗7", 91: "⌗8", 92: "⌗9",
            // Arrows
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return map[code] ?? "Key\(code)"
    }
}
