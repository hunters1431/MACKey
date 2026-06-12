import Foundation

struct DockReader {
    static func readApps() -> [AppEntry] {
        let plistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist"
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dict = plist as? [String: Any],
            let persistentApps = dict["persistent-apps"] as? [[String: Any]]
        else { return [] }

        return persistentApps.compactMap { item -> AppEntry? in
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
}
