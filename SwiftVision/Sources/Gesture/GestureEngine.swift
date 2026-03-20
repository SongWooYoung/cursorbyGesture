import Config
import CoreGraphics
import Foundation
import Support
import VisionPipeline

public final class GestureEngine {
    private let scrollEnabled = false
    private let cursorRule: CursorGestureRule
    private let clickStateTracker: GestureStateTracker<Bool>
    private let stateLock = NSLock()

    private var thresholds: ThresholdConfig
    private var cursorFilter: CGPointEMAFilter
    private var consecutiveScrollPoseFrames = 0
    private var previousNavigationAnchor: CGPoint?
    private var previousNavigationTimestamp: Date?

    public init(config: AppConfig) {
        cursorRule = CursorGestureRule(mirrorHorizontally: config.mirrorCursorHorizontally)
        clickStateTracker = GestureStateTracker(initialValue: false)
        thresholds = config.thresholds
        cursorFilter = CGPointEMAFilter(alpha: config.thresholds.smoothingAlpha)
    }

    public func updateCursorSmoothing(_ alpha: CGFloat) {
        stateLock.lock()
        defer { stateLock.unlock() }
        thresholds.smoothingAlpha = alpha
        cursorFilter.setAlpha(alpha)
    }

    public func updateScrollStep(_ step: Int32) {
        stateLock.lock()
        defer { stateLock.unlock() }
        thresholds.scrollStep = max(1, step)
    }

    public func updateScrollActivationThreshold(_ value: CGFloat) {
        stateLock.lock()
        defer { stateLock.unlock() }
        thresholds.scrollActivationThreshold = Geometry.clamped(value, min: 0.01, max: 0.12)
    }

    public func updateScrollPoseExtendedThreshold(_ value: CGFloat) {
        stateLock.lock()
        defer { stateLock.unlock() }
        thresholds.scrollPoseExtendedThreshold = Geometry.clamped(value, min: 0.04, max: 0.25)
    }

    public func updateScrollPoseFoldedThreshold(_ value: CGFloat) {
        stateLock.lock()
        defer { stateLock.unlock() }
        thresholds.scrollPoseFoldedThreshold = Geometry.clamped(value, min: 0.02, max: 0.20)
    }

    public func process(
        _ result: HandDetectionResult,
        screenBounds: CGRect,
        now: Date? = nil
    ) -> [GestureAction] {
        stateLock.lock()
        defer { stateLock.unlock() }

        let timestamp = now ?? result.timestamp
        let navigationRule = TwoFingerNavigationRule(thresholds: thresholds)
        let clickRule = ClickGestureRule(thresholds: thresholds)

        guard let hand = result.observations.first else {
            cursorFilter.reset()
            resetAllGestureState()
            return []
        }

        var actions: [GestureAction] = []
        if let cursorPoint = cursorRule.cursorPoint(for: hand, in: screenBounds) {
            actions.append(.moveCursor(cursorFilter.update(cursorPoint)))
        }

        let isClickPose = clickRule.isClickPose(hand, wasActive: clickStateTracker.currentValue)
        if let clickChange = clickStateTracker.update(isClickPose), clickChange.current {
            actions.append(.leftClick)
        }

        if scrollEnabled, navigationRule.isActive(hand), let anchor = navigationRule.navigationAnchor(for: hand) {
            consecutiveScrollPoseFrames += 1

            defer {
                previousNavigationAnchor = anchor
                previousNavigationTimestamp = timestamp
            }

            let requiredStableFrames = max(1, thresholds.minimumGestureFrames)
            guard consecutiveScrollPoseFrames >= requiredStableFrames else {
                return actions
            }

            let elapsed: TimeInterval
            if let previousTimestamp = previousNavigationTimestamp {
                elapsed = max(timestamp.timeIntervalSince(previousTimestamp), 0)
            } else {
                elapsed = 0
            }

            guard let intent = navigationRule.detect(
                current: anchor,
                previous: previousNavigationAnchor,
                elapsed: elapsed
            ) else {
                return actions
            }

            if case let .scroll(deltaY) = intent {
                actions.append(.scroll(deltaY: deltaY))
            }

            return actions
        }

        resetScrollState()
        return actions
    }

    private func resetAllGestureState() {
        clickStateTracker.reset(to: false)
        resetScrollState()
    }

    private func resetScrollState() {
        consecutiveScrollPoseFrames = 0
        previousNavigationAnchor = nil
        previousNavigationTimestamp = nil
    }
}
