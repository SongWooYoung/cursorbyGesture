import Config
import CoreGraphics
import Foundation
import Support
import VisionPipeline

enum SwipeDirection {
    case left
    case right
}

struct SwipeGestureRule {
    let thresholds: ThresholdConfig

    func detect(
        current: CGPoint,
        previous: CGPoint?,
        elapsed: TimeInterval
    ) -> SwipeDirection? {
        guard let previous, elapsed > 0 else {
            return nil
        }

        let dx = current.x - previous.x
        let velocity = abs(dx) / CGFloat(elapsed)
        guard abs(dx) >= thresholds.swipeDistanceThreshold, velocity >= thresholds.swipeVelocityThreshold else {
            return nil
        }
        return dx > 0 ? .right : .left
    }
}
