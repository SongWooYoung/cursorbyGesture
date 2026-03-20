import CoreMedia
import Foundation

public struct VideoFrame {
    public let sampleBuffer: CMSampleBuffer
    public let timestamp: Date

    public init(sampleBuffer: CMSampleBuffer, timestamp: Date = Date()) {
        self.sampleBuffer = sampleBuffer
        self.timestamp = timestamp
    }
}
