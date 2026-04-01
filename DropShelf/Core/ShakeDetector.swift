import Foundation
import CoreGraphics

/// Detects a horizontal shake gesture by looking for rapid direction reversals
/// in a sliding time window of mouse positions.
final class ShakeDetector {

    // Tuning knobs
    private let windowDuration: TimeInterval = 0.45   // seconds of history to keep
    private let minReversals    = 3                    // direction changes needed
    private let minDx: CGFloat  = 12                  // px movement to count as intentional

    private let cooldown: TimeInterval = 0.8           // seconds between fires

    var onShake: ((CGPoint) -> Void)?

    // MARK: - Private state

    private struct Sample { let x: CGFloat; let time: TimeInterval }
    private var samples: [Sample] = []
    private var lastFireTime: TimeInterval = 0

    // MARK: - API

    func feed(point: CGPoint, timestamp: TimeInterval) {
        samples.append(Sample(x: point.x, time: timestamp))

        // Prune samples older than the window
        let cutoff = timestamp - windowDuration
        samples.removeAll { $0.time < cutoff }

        guard samples.count >= 5 else { return }
        guard timestamp - lastFireTime >= cooldown else { return }

        if detectShake() {
            lastFireTime = timestamp
            samples.removeAll()
            onShake?(point)
        }
    }

    func reset() {
        samples.removeAll()
    }

    // MARK: - Algorithm

    private func detectShake() -> Bool {
        var reversals = 0
        var lastSign: CGFloat = 0

        for i in 1 ..< samples.count {
            let dx = samples[i].x - samples[i - 1].x
            guard abs(dx) >= minDx else { continue }
            let sign: CGFloat = dx > 0 ? 1 : -1
            if lastSign != 0, sign != lastSign {
                reversals += 1
            }
            lastSign = sign
        }

        return reversals >= minReversals
    }
}
