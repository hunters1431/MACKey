import Foundation
import AppKit

struct AppEntry: Identifiable, Codable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let appPath: String
    var shortcut: ShortcutBinding?

    // Not Codable — computed on demand
    var icon: NSImage? {
        let path = appPath.hasPrefix("file://")
            ? (URL(string: appPath)?.path ?? appPath)
            : appPath
        guard !path.isEmpty else { return nil }
        return NSWorkspace.shared.icon(forFile: path)
    }

    init(name: String, bundleIdentifier: String, appPath: String, shortcut: ShortcutBinding? = nil) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
        self.shortcut = shortcut
    }
}
