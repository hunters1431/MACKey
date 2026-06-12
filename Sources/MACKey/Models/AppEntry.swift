import Foundation
import AppKit

struct AppEntry: Identifiable, Codable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let appPath: String
    var shortcut: ShortcutBinding?

    // Not Codable — computed on demand, cached by path to avoid repeated disk I/O
    private static var iconCache: [String: NSImage] = [:]

    var icon: NSImage? {
        let path = appPath.hasPrefix("file://")
            ? (URL(string: appPath)?.path ?? appPath)
            : appPath
        guard !path.isEmpty else { return nil }
        if let cached = AppEntry.iconCache[path] { return cached }
        let img = NSWorkspace.shared.icon(forFile: path)
        AppEntry.iconCache[path] = img
        return img
    }

    init(name: String, bundleIdentifier: String, appPath: String, shortcut: ShortcutBinding? = nil) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
        self.shortcut = shortcut
    }
}
