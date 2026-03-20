import Foundation

public struct HandDetectionResult: Sendable {
    public let observations: [HandObservation]
    public let timestamp: Date

    public init(observations: [HandObservation], timestamp: Date) {
        self.observations = observations
        self.timestamp = timestamp
    }
}
