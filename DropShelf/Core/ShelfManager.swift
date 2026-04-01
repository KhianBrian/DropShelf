import AppKit

final class ShelfManager: NSObject {

    let dragMonitor = DragMonitor()

    private(set) var shelfWindow: ShelfWindow!
    private var shelfView: ShelfView!

    // MARK: - Setup

    override init() {
        super.init()
        buildWindow()
        connectDragMonitor()
    }

    private func buildWindow() {
        shelfWindow = ShelfWindow()
        shelfView   = ShelfView(frame: shelfWindow.contentView!.bounds)
        shelfView.autoresizingMask = [.width, .height]
        shelfWindow.contentView?.addSubview(shelfView)
        shelfWindow.delegate = self
    }

    private func connectDragMonitor() {
        dragMonitor.onShakeDetected = { [weak self] point in
            DispatchQueue.main.async {
                self?.showShelf(near: point)
            }
        }
    }

    // MARK: - Public API

    func showShelf(near point: CGPoint? = nil) {
        if let point = point {
            positionShelf(near: point)
        }
        if shelfWindow.isVisible {
            shelfWindow.orderFront(nil)
            return
        }
        shelfWindow.alphaValue = 0
        shelfWindow.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            self.shelfWindow.animator().alphaValue = 1
        }
    }

    func hideShelf() {
        guard shelfWindow.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            self.shelfWindow.animator().alphaValue = 0
        }) { [weak self] in
            self?.shelfWindow.orderOut(nil)
            self?.shelfWindow.alphaValue = 1
        }
    }

    func toggleShelf() {
        shelfWindow.isVisible ? hideShelf() : showShelf()
    }

    func clearShelf() {
        shelfView.clearAll()
    }

    // MARK: - Positioning

    private func positionShelf(near point: CGPoint) {
        // Find which screen the cursor is on
        let screen = NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
                  ?? NSScreen.main!

        var origin = CGPoint(
            x: point.x + 24,
            y: point.y - shelfWindow.frame.height / 2
        )

        // Clamp so shelf stays fully on-screen
        let vis = screen.visibleFrame
        origin.x = min(origin.x, vis.maxX - shelfWindow.frame.width - 4)
        origin.x = max(origin.x, vis.minX + 4)
        origin.y = min(origin.y, vis.maxY - shelfWindow.frame.height - 4)
        origin.y = max(origin.y, vis.minY + 4)

        shelfWindow.setFrameOrigin(origin)
    }
}

// MARK: - NSWindowDelegate

extension ShelfManager: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        shelfWindow.savePosition()
    }
    func windowWillClose(_ notification: Notification) {
        shelfWindow.savePosition()
    }
}
