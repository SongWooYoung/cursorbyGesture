import AppKit
import Capture
import Config
import Control
import Foundation
import Gesture
import Support
import VisionPipeline

public final class AppCoordinator: NSObject {
    private let environment: AppEnvironment
    private let configPath: String
    private let pipelineState = PipelineState()
    private let frameBuffer = FrameBuffer()
    private let handTracker = HandTracker()
    private let gestureEngine: GestureEngine
    private let dispatcher = EventDispatcher()
    private let videoSource: any VideoSource
    private var lastFingerLogSignature: String?
    @MainActor
    private var cursorSmoothingPanelController: CursorSmoothingPanelController?
    @MainActor
    private var handDebugPreviewPanelController: HandDebugPreviewPanelController?

    public init(config: AppConfig, configPath: String = ".env") {
        environment = AppEnvironment(config: config)
        self.configPath = configPath
        gestureEngine = GestureEngine(config: config)

        switch config.inputMode {
        case .camera:
            videoSource = CameraDeviceSource(config: config)
        case .rtsp:
            videoSource = RTSPSource()
        }

        super.init()
        videoSource.delegate = self
    }

    @MainActor
    public func start() throws {
        Logger.info("visualAgent starting")
        Logger.info("Input mode: \(environment.config.inputMode.rawValue)")
        Logger.info("Grant Camera and Accessibility permissions before use.")
        presentGestureControlsPanel(
            initialSmoothingValue: environment.config.thresholds.smoothingAlpha,
            initialScrollSpeed: environment.config.thresholds.scrollStep,
            initialScrollActivationThreshold: environment.config.thresholds.scrollActivationThreshold,
            initialScrollPoseExtendedThreshold: environment.config.thresholds.scrollPoseExtendedThreshold,
            initialScrollPoseFoldedThreshold: environment.config.thresholds.scrollPoseFoldedThreshold
        )
        presentHandDebugPreviewPanel()
        try videoSource.start()
    }

    @MainActor
    private func presentGestureControlsPanel(
        initialSmoothingValue: CGFloat,
        initialScrollSpeed: Int32,
        initialScrollActivationThreshold: CGFloat,
        initialScrollPoseExtendedThreshold: CGFloat,
        initialScrollPoseFoldedThreshold: CGFloat
    ) {
        let controller = CursorSmoothingPanelController(
            initialSmoothingValue: initialSmoothingValue,
            initialScrollSpeed: initialScrollSpeed,
            initialScrollActivationThreshold: initialScrollActivationThreshold,
            initialScrollPoseExtendedThreshold: initialScrollPoseExtendedThreshold,
            initialScrollPoseFoldedThreshold: initialScrollPoseFoldedThreshold,
            onSmoothingChanged: { [weak self] value in
                self?.applyCursorSmoothing(value)
            },
            onScrollSpeedChanged: { [weak self] value in
                self?.applyScrollSpeed(value)
            },
            onScrollActivationChanged: { [weak self] value in
                self?.applyScrollActivationThreshold(value)
            },
            onScrollPoseExtendedChanged: { [weak self] value in
                self?.applyScrollPoseExtendedThreshold(value)
            },
            onScrollPoseFoldedChanged: { [weak self] value in
                self?.applyScrollPoseFoldedThreshold(value)
            }
        )
        cursorSmoothingPanelController = controller
        controller.showPanel()
    }

    @MainActor
    private func presentHandDebugPreviewPanel() {
        let controller = HandDebugPreviewPanelController(
            frameBuffer: frameBuffer,
            pipelineState: pipelineState,
            mirrorHorizontally: environment.config.mirrorCursorHorizontally
        )
        handDebugPreviewPanelController = controller
        controller.showPanel()
    }

    @MainActor
    private func applyCursorSmoothing(_ value: CGFloat) {
        let clampedValue = Geometry.clamped(value, min: 0.01, max: 1.0)
        gestureEngine.updateCursorSmoothing(clampedValue)

        do {
            try ConfigLoader.updateEnvValue(
                "CURSOR_SMOOTHING",
                value: String(format: "%.2f", Double(clampedValue)),
                at: configPath
            )
        } catch {
            Logger.warning("Failed to persist CURSOR_SMOOTHING: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func applyScrollSpeed(_ value: Int32) {
        let clampedValue = max(1, value)
        gestureEngine.updateScrollStep(clampedValue)

        do {
            try ConfigLoader.updateEnvValue(
                "SCROLL_STEP",
                value: "\(clampedValue)",
                at: configPath
            )
        } catch {
            Logger.warning("Failed to persist SCROLL_STEP: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func applyScrollActivationThreshold(_ value: CGFloat) {
        let clampedValue = Geometry.clamped(value, min: 0.01, max: 0.12)
        gestureEngine.updateScrollActivationThreshold(clampedValue)

        do {
            try ConfigLoader.updateEnvValue(
                "SCROLL_ACTIVATION_THRESHOLD",
                value: String(format: "%.3f", Double(clampedValue)),
                at: configPath
            )
        } catch {
            Logger.warning("Failed to persist SCROLL_ACTIVATION_THRESHOLD: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func applyScrollPoseExtendedThreshold(_ value: CGFloat) {
        let clampedValue = Geometry.clamped(value, min: 0.04, max: 0.25)
        gestureEngine.updateScrollPoseExtendedThreshold(clampedValue)

        do {
            try ConfigLoader.updateEnvValue(
                "SCROLL_POSE_EXTENDED_THRESHOLD",
                value: String(format: "%.3f", Double(clampedValue)),
                at: configPath
            )
        } catch {
            Logger.warning("Failed to persist SCROLL_POSE_EXTENDED_THRESHOLD: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func applyScrollPoseFoldedThreshold(_ value: CGFloat) {
        let clampedValue = Geometry.clamped(value, min: 0.02, max: 0.20)
        gestureEngine.updateScrollPoseFoldedThreshold(clampedValue)

        do {
            try ConfigLoader.updateEnvValue(
                "SCROLL_POSE_FOLDED_THRESHOLD",
                value: String(format: "%.3f", Double(clampedValue)),
                at: configPath
            )
        } catch {
            Logger.warning("Failed to persist SCROLL_POSE_FOLDED_THRESHOLD: \(error.localizedDescription)")
        }
    }
}

extension AppCoordinator: VideoSourceDelegate {
    public func videoSource(_ source: any VideoSource, didOutput frame: VideoFrame) {
        frameBuffer.update(frame)

        do {
            let result = try handTracker.process(frame.sampleBuffer, timestamp: frame.timestamp)
            pipelineState.store(result)
            logRecognizedFingers(result)

            let screenBounds = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
            let actions = gestureEngine.process(result, screenBounds: screenBounds)
            if !actions.isEmpty {
                dispatcher.dispatch(actions)
            }
        } catch {
            Logger.warning("Frame processing failed: \(error.localizedDescription)")
        }
    }

    public func videoSource(_ source: any VideoSource, didFail error: Error) {
        Logger.error("Video source error: \(error.localizedDescription)")
    }

    private func logRecognizedFingers(_ result: HandDetectionResult) {
        let signature: String
        if result.observations.isEmpty {
            signature = "none"
        } else {
            signature = result.observations.enumerated().map { index, observation in
                let chirality: String
                switch observation.chirality {
                case .left:
                    chirality = "left"
                case .right:
                    chirality = "right"
                case .unknown:
                    chirality = "unknown"
                }
                let fingers = observation.recognizedFingers.map(\.displayName).joined(separator: ", ")
                let anchorSource: String
                if observation.hasWrist {
                    anchorSource = "wrist"
                } else if observation.palmAnchor != nil {
                    anchorSource = "palm-fallback"
                } else {
                    anchorSource = "none"
                }
                return "hand\(index + 1)[\(chirality)][anchor:\(anchorSource)]: \(fingers.isEmpty ? "none" : fingers)"
            }.joined(separator: " | ")
        }

        guard signature != lastFingerLogSignature else {
            return
        }
        lastFingerLogSignature = signature
        Logger.info("Recognized fingers: \(signature)")
    }
}
