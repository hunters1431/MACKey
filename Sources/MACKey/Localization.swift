import Foundation

/// Localized string from the app bundle's Localizable.strings.
/// macOS picks the .lproj matching the user's system language automatically.
func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: .main, comment: "")
}

/// Localized + formatted (e.g. L("rec.conflict.app", appName)).
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: .main, comment: ""), arguments: args)
}
