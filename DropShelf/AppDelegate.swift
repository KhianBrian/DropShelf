import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private(set) var shelfManager: ShelfManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        shelfManager = ShelfManager()
        shelfManager.dragMonitor.start()
        setupStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        shelfManager.dragMonitor.stop()
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let img = NSImage(systemSymbolName: "tray.and.arrow.down.fill",
                              accessibilityDescription: "DropShelf")
            img?.isTemplate = true
            button.image = img
            button.toolTip = "DropShelf"
        }
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show / Hide Shelf",
                                action: #selector(toggleShelf),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear Shelf",
                                action: #selector(clearShelf),
                                keyEquivalent: ""))
        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login",
                                   action: #selector(toggleLoginItem),
                                   keyEquivalent: "")
        loginItem.state = isLoginItemEnabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit DropShelf",
                                action: #selector(quit),
                                keyEquivalent: "q"))
        for item in menu.items { item.target = self }
        return menu
    }

    // MARK: - Actions

    @objc private func toggleShelf() {
        shelfManager.toggleShelf()
    }

    @objc private func clearShelf() {
        shelfManager.clearShelf()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func toggleLoginItem() {
        guard #available(macOS 13.0, *) else { return }
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
            // Rebuild menu to update checkmark
            statusItem.menu = buildMenu()
        } catch {
            NSLog("DropShelf: failed to toggle login item: \(error)")
        }
    }

    private var isLoginItemEnabled: Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }
}
