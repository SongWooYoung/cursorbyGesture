import Config
import Foundation
import VisionPipeline

struct ClickGestureRule {
    let thresholds: ThresholdConfig

    func isClickPose(_ hand: HandObservation, wasActive: Bool) -> Bool {
        guard let pinch = hand.pinchDistance(.thumbTip, .indexTip) else {
            return false
        }

        let activationThreshold = thresholds.clickPinchDistance
        let releaseThreshold = max(thresholds.clickPinchReleaseDistance, activationThreshold)
        return wasActive ? pinch <= releaseThreshold : pinch <= activationThreshold
    }
}
