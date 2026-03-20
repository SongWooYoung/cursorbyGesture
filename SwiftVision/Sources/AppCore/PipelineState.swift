import Foundation
import VisionPipeline

public final class PipelineState {
    private let lock = NSLock()
    private(set) var lastResult: HandDetectionResult?

    public init() {}

    public func store(_ result: HandDetectionResult) {
        lock.lock()
        defer { lock.unlock() }
        lastResult = result
    }

    public func snapshot() -> HandDetectionResult? {
        lock.lock()
        defer { lock.unlock() }
        return lastResult
    }
}
