import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // No Dock icon (belt + suspenders alongside LSUIElement)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
