import Foundation

public final class FrameBuffer {
    private let lock = NSLock()
    private var latestFrame: VideoFrame?

    public init() {}

    public func update(_ frame: VideoFrame) {
        lock.lock()
        defer { lock.unlock() }
        latestFrame = frame
    }

    public func snapshot() -> VideoFrame? {
        lock.lock()
        defer { lock.unlock() }
        return latestFrame
    }
}
