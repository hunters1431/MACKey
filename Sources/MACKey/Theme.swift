import SwiftUI
import AppKit

/// The five curated accent presets. Teal is the default brand color and is
/// what the static app icon (.icns) and all marketing material use; the others
/// are opt-in personalization that recolor the in-app UI only.
enum AccentTheme: String, CaseIterable, Identifiable {
    case teal      // 墨绿 — default brand
    case amber     // 琥珀金
    case coral     // 珊瑚橙
    case indigo    // 靛蓝
    case graphite  // 石墨

    var id: String { rawValue }

    /// sRGB components, readable as a keycap fill in both light and dark mode.
    private var rgb: (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .teal:     return (0x0F / 255, 0x6E / 255, 0x56 / 255)
        case .amber:    return (0xC2 / 255, 0x82 / 255, 0x0C / 255)
        case .coral:    return (0xCE / 255, 0x5A / 255, 0x2E / 255)
        case .indigo:   return (0x2E / 255, 0x68 / 255, 0xD0 / 255)
        case .graphite: return (0x58 / 255, 0x58 / 255, 0x5B / 255)
        }
    }

    /// A slightly darker shade for the keycap "wall" (bottom edge).
    private var wallRGB: (CGFloat, CGFloat, CGFloat) {
        let (r, g, b) = rgb
        return (r * 0.55, g * 0.55, b * 0.55)
    }

    var nsColor: NSColor {
        let (r, g, b) = rgb
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    var wallNSColor: NSColor {
        let (r, g, b) = wallRGB
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    var color: Color { Color(nsColor) }
    var wallColor: Color { Color(wallNSColor) }

    var nameKey: String {
        switch self {
        case .teal:     return "theme.teal"
        case .amber:    return "theme.amber"
        case .coral:    return "theme.coral"
        case .indigo:   return "theme.indigo"
        case .graphite: return "theme.graphite"
        }
    }
}

/// Holds the user's chosen accent theme and persists it. Drives in-app UI color.
final class Theme: ObservableObject {
    static let shared = Theme()

    private let key = "mackey.theme.v1"

    @Published var accent: AccentTheme = .teal {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: key) }
    }

    func load() {
        // Theme switching is an App Store exclusive; the GitHub build stays teal.
        #if APPSTORE
        if let raw = UserDefaults.standard.string(forKey: key),
           let t = AccentTheme(rawValue: raw) {
            accent = t
        }
        #endif
    }
}
