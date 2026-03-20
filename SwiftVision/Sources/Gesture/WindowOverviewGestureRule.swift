import Config
import VisionPipeline

struct WindowOverviewGestureRule {
    let thresholds: ThresholdConfig

    func isOverviewPose(_ hand: HandObservation) -> Bool {
        guard hand.fingertipPoints.count >= 5 else {
            return false
        }
        guard let compactness = hand.compactness else {
            return false
        }
        return compactness <= thresholds.overviewCompactness
    }
}
