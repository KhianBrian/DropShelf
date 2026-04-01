import AppKit

private let kFrameKey = "ShelfWindowFrame"

final class ShelfWindow: NSPanel {

    // MARK: - Init

    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 284, height: 380),
            styleMask: [.nonactivatingPanel, .fullSizeContentView,
                        .titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style,
                   backing: backingStoreType, defer: flag)
    }

    // MARK: - Configuration

    private func configure() {
        level                      = .floating
        isFloatingPanel            = true
        hidesOnDeactivate          = false
        isMovableByWindowBackground = true
        backgroundColor            = .windowBackgroundColor
        titlebarAppearsTransparent = true
        titleVisibility            = .hidden
        hasShadow                  = true
        isReleasedWhenClosed       = false
        minSize                    = NSSize(width: 180, height: 200)
        collectionBehavior         = [.canJoinAllSpaces, .stationary]

        restorePosition()
    }

    // NSPanel overrides so it can receive drops properly
    override var canBecomeKey:  Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Persistence

    func savePosition() {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: kFrameKey)
    }

    func restorePosition() {
        if let s = UserDefaults.standard.string(forKey: kFrameKey) {
            let r = NSRectFromString(s)
            if r.width > 0 {
                setFrame(r, display: false)
                return
            }
        }
        // Default: bottom-right of the main screen
        guard let screen = NSScreen.main else { return }
        let x = screen.visibleFrame.maxX - frame.width - 20
        let y = screen.visibleFrame.minY + 20
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
