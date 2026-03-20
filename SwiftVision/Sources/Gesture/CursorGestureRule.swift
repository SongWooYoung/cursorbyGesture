import Config
import CoreGraphics
import Support
import VisionPipeline

struct CursorGestureRule {
    let mirrorHorizontally: Bool

    func cursorPoint(for hand: HandObservation, in screenBounds: CGRect) -> CGPoint? {
        guard let indexTip = hand.point(.indexTip) else {
            return nil
        }
        return indexTip.denormalized(in: screenBounds, mirrorX: mirrorHorizontally)
    }
}
