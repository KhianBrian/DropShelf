import AppKit

/// Monitors global mouse events and fires `onShakeDetected` when the user shakes
/// the cursor while holding the left mouse button down (i.e. while dragging).
final class DragMonitor {

    private var dragMonitor:  Any?
    private var mouseUpMonitor: Any?

    private let shakeDetector = ShakeDetector()

    var onShakeDetected: ((CGPoint) -> Void)? {
        get { shakeDetector.onShake }
        set { shakeDetector.onShake = newValue }
    }

    // MARK: - Lifecycle

    func start() {
        guard dragMonitor == nil else { return }

        // Feed every drag event into the shake detector.
        // NSEvent.mouseLocation gives screen coords (origin = bottom-left of main screen).
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            self?.shakeDetector.feed(point: NSEvent.mouseLocation, timestamp: event.timestamp)
        }

        // Reset detector when the drag ends so stale samples don't cause false positives.
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.shakeDetector.reset()
        }
    }

    func stop() {
        [dragMonitor, mouseUpMonitor].forEach {
            if let m = $0 { NSEvent.removeMonitor(m) }
        }
        dragMonitor  = nil
        mouseUpMonitor = nil
        shakeDetector.reset()
    }

    var isRunning: Bool { dragMonitor != nil }
}
