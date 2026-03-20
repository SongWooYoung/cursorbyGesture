import Config
import CoreGraphics
import Support
import VisionPipeline

enum ZoomIntent {
    case zoomIn
    case zoomOut
}

struct ZoomGestureRule {
    let thresholds: ThresholdConfig

    func trioSpread(for hand: HandObservation) -> CGFloat? {
        guard
            let thumb = hand.point(.thumbTip),
            let index = hand.point(.indexTip),
            let middle = hand.point(.middleTip)
        else {
            return nil
        }

        let center = Geometry.average([thumb, index, middle]) ?? .zero
        let distances = [
            Geometry.distance(thumb, center),
            Geometry.distance(index, center),
            Geometry.distance(middle, center),
        ]
        return distances.reduce(0, +) / CGFloat(distances.count)
    }

    func detect(current: CGFloat, previous: CGFloat?) -> ZoomIntent? {
        guard let previous else {
            return nil
        }

        let delta = current - previous
        guard abs(delta) >= thresholds.zoomDeltaThreshold else {
            return nil
        }
        return delta > 0 ? .zoomIn : .zoomOut
    }
}
