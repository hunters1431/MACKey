import Foundation

struct DockReader {
    /// Reads the current Dock app order. Goes through cfprefsd
    /// (CFPreferences) first so a freshly-reordered Dock is reflected
    /// immediately — reading the raw plist file returns a stale, cached copy.
    /// Falls back to the file if the preference read yields nothing.
    static func readApps() -> [AppEntry] {
        let domain = "com.apple.dock" as CFString
        CFPreferencesAppSynchronize(domain)
        if let value = CFPreferencesCopyAppValue("persistent-apps" as CFString, domain) as? [[String: Any]],
           !value.isEmpty {
            return parse(value)
        }
        return readFromFile()
    }

    private static func parse(_ persistentApps: [[String: Any]]) -> [AppEntry] {
        persistentApps.compactMap { item -> AppEntry? in
            guard
                let tileData = item["tile-data"] as? [String: Any],
                let name = tileData["file-label"] as? String,
                let bundleID = tileData["bundle-identifier"] as? String,
                let fileData = tileData["file-data"] as? [String: Any],
                let urlString = fileData["_CFURLString"] as? String
            else { return nil }

            return AppEntry(name: name, bundleIdentifier: bundleID, appPath: urlString)
        }
    }

    private static func readFromFile() -> [AppEntry] {
        let plistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist"
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dict = plist as? [String: Any],
            let persistentApps = dict["persistent-apps"] as? [[String: Any]]
        else { return [] }

        return parse(persistentApps)
    }
}
