import Config
import CoreGraphics
import Foundation
@testable import Gesture
import Testing
import VisionPipeline

struct GestureEngineScrollTests {
    @Test func twoFingerVerticalMoveDoesNotProduceScrollWhileDisabled() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                scrollStep: 11,
                zoomDeltaThreshold: 0.01,
                minimumGestureFrames: 1,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let start = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.3))],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        _ = engine.process(start, screenBounds: screen, now: start.timestamp)

        let end = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.38))],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let actions = engine.process(end, screenBounds: screen, now: end.timestamp)

        #expect(!actions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
    }

    @Test func horizontalWristMoveDoesNotTriggerScroll() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                zoomDeltaThreshold: 0.01,
                minimumGestureFrames: 1,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let start = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.4, y: 0.3))],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        _ = engine.process(start, screenBounds: screen, now: start.timestamp)

        let end = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.58, y: 0.3))],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let actions = engine.process(end, screenBounds: screen, now: end.timestamp)

        #expect(!actions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
    }

    @Test func returningFingersStillDoNotProduceScrollWhileDisabled() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                scrollStep: 5,
                zoomDeltaThreshold: 0.01,
                minimumGestureFrames: 1,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let start = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.3))],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        _ = engine.process(start, screenBounds: screen, now: start.timestamp)

        let scrolledDown = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.38))],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let downActions = engine.process(scrolledDown, screenBounds: screen, now: scrolledDown.timestamp)

        let returningUp = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.3))],
            timestamp: Date(timeIntervalSince1970: 0.2)
        )
        let returnActions = engine.process(returningUp, screenBounds: screen, now: returningUp.timestamp)

        #expect(!downActions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
        #expect(!returnActions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
    }

    @Test func scrollPoseWithPalmFallbackDoesNotProduceScrollWhileDisabled() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                scrollStep: 7,
                zoomDeltaThreshold: 0.01,
                minimumGestureFrames: 1,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let start = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.3), includeWrist: false)],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        _ = engine.process(start, screenBounds: screen, now: start.timestamp)

        let end = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.38), includeWrist: false)],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let actions = engine.process(end, screenBounds: screen, now: end.timestamp)

        #expect(!actions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
    }

    @Test func configurableScrollThresholdsHaveNoEffectWhileScrollDisabled() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                scrollStep: 3,
                scrollActivationThreshold: 0.02,
                scrollPoseExtendedThreshold: 0.04,
                scrollPoseFoldedThreshold: 0.16,
                zoomDeltaThreshold: 0.04,
                minimumGestureFrames: 1,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let start = HandDetectionResult(
            observations: [makeHand(center: CGPoint(x: 0.3, y: 0.42), landmarks: [
                .indexMCP: CGPoint(x: 0.28, y: 0.35),
                .indexPIP: CGPoint(x: 0.28, y: 0.40),
                .indexTip: CGPoint(x: 0.28, y: 0.47),
                .middleMCP: CGPoint(x: 0.32, y: 0.35),
                .middlePIP: CGPoint(x: 0.32, y: 0.40),
                .middleTip: CGPoint(x: 0.32, y: 0.47),
                .ringMCP: CGPoint(x: 0.36, y: 0.35),
                .ringPIP: CGPoint(x: 0.36, y: 0.39),
                .ringTip: CGPoint(x: 0.36, y: 0.40),
                .littleMCP: CGPoint(x: 0.39, y: 0.35),
                .littlePIP: CGPoint(x: 0.39, y: 0.385),
                .littleTip: CGPoint(x: 0.39, y: 0.39),
            ])],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        _ = engine.process(start, screenBounds: screen, now: start.timestamp)

        let end = HandDetectionResult(
            observations: [makeHand(center: CGPoint(x: 0.3, y: 0.44), landmarks: [
                .indexMCP: CGPoint(x: 0.28, y: 0.37),
                .indexPIP: CGPoint(x: 0.28, y: 0.42),
                .indexTip: CGPoint(x: 0.28, y: 0.49),
                .middleMCP: CGPoint(x: 0.32, y: 0.37),
                .middlePIP: CGPoint(x: 0.32, y: 0.42),
                .middleTip: CGPoint(x: 0.32, y: 0.49),
                .ringMCP: CGPoint(x: 0.36, y: 0.37),
                .ringPIP: CGPoint(x: 0.36, y: 0.405),
                .ringTip: CGPoint(x: 0.36, y: 0.41),
                .littleMCP: CGPoint(x: 0.39, y: 0.37),
                .littlePIP: CGPoint(x: 0.39, y: 0.40),
                .littleTip: CGPoint(x: 0.39, y: 0.405),
            ])],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let actions = engine.process(end, screenBounds: screen, now: end.timestamp)

        #expect(!actions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
    }

    @Test func stableScrollPoseStillDoesNotProduceScrollWhileDisabled() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                scrollStep: 6,
                zoomDeltaThreshold: 0.01,
                minimumGestureFrames: 3,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let frame1 = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.30))],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        let frame2 = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.38))],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let frame3 = HandDetectionResult(
            observations: [makeTwoFingerScrollPose(wrist: CGPoint(x: 0.21, y: 0.46))],
            timestamp: Date(timeIntervalSince1970: 0.2)
        )

        let firstActions = engine.process(frame1, screenBounds: screen, now: frame1.timestamp)
        let secondActions = engine.process(frame2, screenBounds: screen, now: frame2.timestamp)
        let thirdActions = engine.process(frame3, screenBounds: screen, now: frame3.timestamp)

        #expect(!firstActions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
        #expect(!secondActions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
        #expect(!thirdActions.contains(where: {
            if case .scroll = $0 { return true }
            return false
        }))
    }
}

private func makeHand(center: CGPoint, landmarks: [HandLandmarkName: CGPoint]) -> HandObservation {
    HandObservation(
        chirality: .unknown,
        confidence: 1,
        boundingBox: CGRect(x: center.x - 0.1, y: center.y - 0.1, width: 0.2, height: 0.2),
        landmarks: landmarks
    )
}

private func makeTwoFingerScrollPose(wrist: CGPoint, includeWrist: Bool = true) -> HandObservation {
    let indexMCP = CGPoint(x: wrist.x - 0.01, y: wrist.y + 0.10)
    let indexPIP = CGPoint(x: wrist.x - 0.015, y: wrist.y + 0.20)
    let indexTip = CGPoint(x: wrist.x - 0.02, y: wrist.y + 0.34)
    let middleMCP = CGPoint(x: wrist.x + 0.02, y: wrist.y + 0.10)
    let middlePIP = CGPoint(x: wrist.x + 0.025, y: wrist.y + 0.21)
    let middleTip = CGPoint(x: wrist.x + 0.03, y: wrist.y + 0.35)
    let ringMCP = CGPoint(x: wrist.x + 0.05, y: wrist.y + 0.09)
    let ringPIP = CGPoint(x: wrist.x + 0.055, y: wrist.y + 0.14)
    let ringTip = CGPoint(x: wrist.x + 0.05, y: wrist.y + 0.105)
    let littleMCP = CGPoint(x: wrist.x + 0.075, y: wrist.y + 0.08)
    let littlePIP = CGPoint(x: wrist.x + 0.08, y: wrist.y + 0.12)
    let littleTip = CGPoint(x: wrist.x + 0.075, y: wrist.y + 0.09)
    let thumbCMC = CGPoint(x: wrist.x - 0.045, y: wrist.y + 0.03)
    let thumbMP = CGPoint(x: wrist.x - 0.055, y: wrist.y + 0.055)
    let thumbIP = CGPoint(x: wrist.x - 0.05, y: wrist.y + 0.075)
    let thumbTip = CGPoint(x: wrist.x - 0.04, y: wrist.y + 0.085)

    var landmarks: [HandLandmarkName: CGPoint] = [
        .thumbCMC: thumbCMC,
        .thumbMP: thumbMP,
        .thumbIP: thumbIP,
        .thumbTip: thumbTip,
        .indexMCP: indexMCP,
        .indexPIP: indexPIP,
        .indexDIP: CGPoint(x: wrist.x - 0.018, y: wrist.y + 0.27),
        .indexTip: indexTip,
        .middleMCP: middleMCP,
        .middlePIP: middlePIP,
        .middleDIP: CGPoint(x: wrist.x + 0.028, y: wrist.y + 0.28),
        .middleTip: middleTip,
        .ringMCP: ringMCP,
        .ringPIP: ringPIP,
        .ringDIP: CGPoint(x: wrist.x + 0.054, y: wrist.y + 0.12),
        .ringTip: ringTip,
        .littleMCP: littleMCP,
        .littlePIP: littlePIP,
        .littleDIP: CGPoint(x: wrist.x + 0.078, y: wrist.y + 0.10),
        .littleTip: littleTip,
    ]

    if includeWrist {
        landmarks[.wrist] = wrist
    }

    return makeHand(center: CGPoint(x: wrist.x, y: wrist.y + 0.18), landmarks: landmarks)
}
