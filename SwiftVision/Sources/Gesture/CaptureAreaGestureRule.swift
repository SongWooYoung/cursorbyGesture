import Config
import CoreGraphics
import Support
import VisionPipeline

struct CaptureAreaDetection {
    let startPoint: CGPoint
    let endPoint: CGPoint
}

struct CaptureAreaGestureRule {
    let thresholds: ThresholdConfig
    let mirrorHorizontally: Bool

    func detect(_ hands: [HandObservation], in screenBounds: CGRect) -> CaptureAreaDetection? {
        guard hands.count == 2 else {
            return nil
        }

        let sortedHands = hands.sorted { $0.center.x < $1.center.x }
        guard
            let leftThumb = sortedHands[0].point(.thumbTip),
            let leftIndex = sortedHands[0].point(.indexTip),
            let rightThumb = sortedHands[1].point(.thumbTip),
            let rightIndex = sortedHands[1].point(.indexTip)
        else {
            return nil
        }

        let leftPinch = Geometry.distance(leftThumb, leftIndex)
        let rightPinch = Geometry.distance(rightThumb, rightIndex)
        let spread = Geometry.distance(leftIndex, rightIndex)

        guard
            leftPinch <= thresholds.capturePinchDistance,
            rightPinch <= thresholds.capturePinchDistance,
            spread >= thresholds.captureSpreadThreshold
        else {
            return nil
        }

        return CaptureAreaDetection(
            startPoint: leftIndex.denormalized(in: screenBounds, mirrorX: mirrorHorizontally),
            endPoint: rightIndex.denormalized(in: screenBounds, mirrorX: mirrorHorizontally)
        )
    }
}
