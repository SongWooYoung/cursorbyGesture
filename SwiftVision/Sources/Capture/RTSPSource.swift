import Foundation

public enum RTSPSourceError: Error, LocalizedError {
    case unsupported

    public var errorDescription: String? {
        "RTSP input is planned as a fallback source but is not implemented in the first version."
    }
}

public final class RTSPSource: VideoSource {
    public weak var delegate: (any VideoSourceDelegate)?

    public init() {}

    public func start() throws {
        throw RTSPSourceError.unsupported
    }

    public func stop() {}
}
