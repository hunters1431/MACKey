import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // menu bar only, no Dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
