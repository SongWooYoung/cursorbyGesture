import Config
import CoreGraphics
import Foundation
@testable import Gesture
import Testing
import VisionPipeline

struct GestureEngineCursorTests {
    @Test func singleFingerMoveProducesCursorAction() async throws {
        let config = AppConfig()
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let result = HandDetectionResult(
            observations: [makeHand(center: CGPoint(x: 0.45, y: 0.5), landmarks: [
                .indexTip: CGPoint(x: 0.45, y: 0.5),
            ])],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let actions = engine.process(result, screenBounds: screen, now: result.timestamp)

        #expect(actions.contains(where: {
            if case .moveCursor = $0 { return true }
            return false
        }))
    }

    @Test func cursorHorizontalMappingCanBeUnmirrored() async throws {
        let config = AppConfig(mirrorCursorHorizontally: false)
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

        let result = HandDetectionResult(
            observations: [makeHand(center: CGPoint(x: 0.2, y: 0.4), landmarks: [
                .indexTip: CGPoint(x: 0.2, y: 0.4),
            ])],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let actions = engine.process(result, screenBounds: screen, now: result.timestamp)

        let movedPoint = actions.compactMap { action -> CGPoint? in
            if case let .moveCursor(point) = action {
                return point
            }
            return nil
        }.first

        #expect(movedPoint?.x == 200)
    }

    @Test func pinchProducesSingleLeftClickWhileHoldingPose() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                clickPinchDistance: 0.08,
                clickPinchReleaseDistance: 0.10,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let pinchPose = makeHand(center: CGPoint(x: 0.41, y: 0.3), landmarks: [
            .indexTip: CGPoint(x: 0.41, y: 0.3),
            .thumbTip: CGPoint(x: 0.45, y: 0.3),
        ])

        let start = HandDetectionResult(
            observations: [pinchPose],
            timestamp: Date(timeIntervalSince1970: 0)
        )
        let firstActions = engine.process(start, screenBounds: screen, now: start.timestamp)

        let held = HandDetectionResult(
            observations: [pinchPose],
            timestamp: Date(timeIntervalSince1970: 0.1)
        )
        let heldActions = engine.process(held, screenBounds: screen, now: held.timestamp)

        #expect(firstActions.contains(where: {
            if case .leftClick = $0 { return true }
            return false
        }))
        #expect(!heldActions.contains(.leftClick))
    }

    @Test func clickUsesHysteresisBeforeRearming() async throws {
        let config = AppConfig(
            thresholds: ThresholdConfig(
                clickPinchDistance: 0.06,
                clickPinchReleaseDistance: 0.09,
                gestureCooldownSeconds: 0
            )
        )
        let engine = GestureEngine(config: config)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let pressedPose = makeHand(center: CGPoint(x: 0.41, y: 0.3), landmarks: [
            .indexTip: CGPoint(x: 0.41, y: 0.3),
            .thumbTip: CGPoint(x: 0.46, y: 0.3),
        ])
        let halfReleasedPose = makeHand(center: CGPoint(x: 0.41, y: 0.3), landmarks: [
            .indexTip: CGPoint(x: 0.41, y: 0.3),
            .thumbTip: CGPoint(x: 0.49, y: 0.3),
        ])
        let releasedPose = makeHand(center: CGPoint(x: 0.41, y: 0.3), landmarks: [
            .indexTip: CGPoint(x: 0.41, y: 0.3),
            .thumbTip: CGPoint(x: 0.51, y: 0.3),
        ])

        let frame1 = HandDetectionResult(observations: [pressedPose], timestamp: Date(timeIntervalSince1970: 0.0))
        let frame2 = HandDetectionResult(observations: [halfReleasedPose], timestamp: Date(timeIntervalSince1970: 0.1))
        let frame3 = HandDetectionResult(observations: [pressedPose], timestamp: Date(timeIntervalSince1970: 0.2))
        let frame4 = HandDetectionResult(observations: [releasedPose], timestamp: Date(timeIntervalSince1970: 0.3))
        let frame5 = HandDetectionResult(observations: [halfReleasedPose], timestamp: Date(timeIntervalSince1970: 0.4))
        let frame6 = HandDetectionResult(observations: [pressedPose], timestamp: Date(timeIntervalSince1970: 0.5))

        let actions1 = engine.process(frame1, screenBounds: screen, now: frame1.timestamp)
        let actions2 = engine.process(frame2, screenBounds: screen, now: frame2.timestamp)
        let actions3 = engine.process(frame3, screenBounds: screen, now: frame3.timestamp)
        let actions4 = engine.process(frame4, screenBounds: screen, now: frame4.timestamp)
        let actions5 = engine.process(frame5, screenBounds: screen, now: frame5.timestamp)
        let actions6 = engine.process(frame6, screenBounds: screen, now: frame6.timestamp)

        #expect(actions1.contains(.leftClick))
        #expect(!actions2.contains(.leftClick))
        #expect(!actions3.contains(.leftClick))
        #expect(!actions4.contains(.leftClick))
        #expect(!actions5.contains(.leftClick))
        #expect(actions6.contains(.leftClick))
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

