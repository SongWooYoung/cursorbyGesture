import Foundation

public enum VideoInputMode: String, Sendable {
    case camera
    case rtsp
}

public struct AppConfig: Sendable {
    public var inputMode: VideoInputMode
    public var cameraUniqueID: String?
    public var rtspURL: String?
    public var mirrorCursorHorizontally: Bool
    public var thresholds: ThresholdConfig

    public init(
        inputMode: VideoInputMode = .camera,
        cameraUniqueID: String? = nil,
        rtspURL: String? = nil,
        mirrorCursorHorizontally: Bool = true,
        thresholds: ThresholdConfig = ThresholdConfig()
    ) {
        self.inputMode = inputMode
        self.cameraUniqueID = cameraUniqueID
        self.rtspURL = rtspURL
        self.mirrorCursorHorizontally = mirrorCursorHorizontally
        self.thresholds = thresholds
    }
}
