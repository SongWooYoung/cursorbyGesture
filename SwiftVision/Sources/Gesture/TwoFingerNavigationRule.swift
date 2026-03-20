import Config
import CoreGraphics
import Foundation
import VisionPipeline

enum TwoFingerNavigationIntent: Equatable {
    case scroll(deltaY: Int32)
    case previousPage
    case nextPage
}

struct TwoFingerNavigationRule {
    let thresholds: ThresholdConfig

    func isActive(_ hand: HandObservation) -> Bool {
        hand.isTwoFingerScrollPose(
            extendedThresholdScale: thresholds.scrollPoseExtendedThreshold,
            foldedThresholdScale: thresholds.scrollPoseFoldedThreshold
        )
    }

    func navigationAnchor(for hand: HandObservation) -> CGPoint? {
        hand.palmAnchor
    }

    func detect(
        current: CGPoint,
        previous: CGPoint?,
        elapsed: TimeInterval
    ) -> TwoFingerNavigationIntent? {
        guard let previous, elapsed > 0 else {
            return nil
        }

        let dx = current.x - previous.x
        let dy = current.y - previous.y

        let verticalThreshold = max(thresholds.scrollActivationThreshold * 0.5, 0.015)
        if abs(dy) >= verticalThreshold, abs(dy) > abs(dx) {
            let step = max(1, thresholds.scrollStep)
            return .scroll(deltaY: dy > 0 ? step : -step)
        }

        return nil
    }
}
