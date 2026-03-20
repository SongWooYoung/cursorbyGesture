import CoreGraphics
import Foundation

public struct ThresholdConfig: Sendable {
    public var smoothingAlpha: CGFloat
    public var scrollStep: Int32
    public var scrollActivationThreshold: CGFloat
    public var scrollPoseExtendedThreshold: CGFloat
    public var scrollPoseFoldedThreshold: CGFloat
    public var clickPinchDistance: CGFloat
    public var clickPinchReleaseDistance: CGFloat
    public var overviewCompactness: CGFloat
    public var zoomDeltaThreshold: CGFloat
    public var swipeVelocityThreshold: CGFloat
    public var swipeDistanceThreshold: CGFloat
    public var capturePinchDistance: CGFloat
    public var captureSpreadThreshold: CGFloat
    public var minimumGestureFrames: Int
    public var gestureCooldownSeconds: TimeInterval

    public init(
        smoothingAlpha: CGFloat = 0.35,
        scrollStep: Int32 = 8,
        scrollActivationThreshold: CGFloat = 0.04,
        scrollPoseExtendedThreshold: CGFloat = 0.12,
        scrollPoseFoldedThreshold: CGFloat = 0.08,
        clickPinchDistance: CGFloat = 0.065,
        clickPinchReleaseDistance: CGFloat = 0.09,
        overviewCompactness: CGFloat = 0.12,
        zoomDeltaThreshold: CGFloat = 0.04,
        swipeVelocityThreshold: CGFloat = 0.9,
        swipeDistanceThreshold: CGFloat = 0.18,
        capturePinchDistance: CGFloat = 0.07,
        captureSpreadThreshold: CGFloat = 0.16,
        minimumGestureFrames: Int = 3,
        gestureCooldownSeconds: TimeInterval = 0.7
    ) {
        self.smoothingAlpha = smoothingAlpha
        self.scrollStep = scrollStep
        self.scrollActivationThreshold = scrollActivationThreshold
        self.scrollPoseExtendedThreshold = scrollPoseExtendedThreshold
        self.scrollPoseFoldedThreshold = scrollPoseFoldedThreshold
        self.clickPinchDistance = clickPinchDistance
        self.clickPinchReleaseDistance = clickPinchReleaseDistance
        self.overviewCompactness = overviewCompactness
        self.zoomDeltaThreshold = zoomDeltaThreshold
        self.swipeVelocityThreshold = swipeVelocityThreshold
        self.swipeDistanceThreshold = swipeDistanceThreshold
        self.capturePinchDistance = capturePinchDistance
        self.captureSpreadThreshold = captureSpreadThreshold
        self.minimumGestureFrames = minimumGestureFrames
        self.gestureCooldownSeconds = gestureCooldownSeconds
    }
}
