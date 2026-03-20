import CoreMedia
import Foundation
import Support
import Vision

public enum HandTrackerError: Error {
    case requestFailed(Error)
}

public final class HandTracker {
    private let request: VNDetectHumanHandPoseRequest

    public init(maxHands: Int = 2) {
        request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = maxHands
    }

    public func process(_ sampleBuffer: CMSampleBuffer, timestamp: Date) throws -> HandDetectionResult {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw HandTrackerError.requestFailed(error)
        }

        let observations = (request.results ?? []).compactMap(Self.makeObservation(from:))
        return HandDetectionResult(observations: observations, timestamp: timestamp)
    }

    private static func makeObservation(from observation: VNHumanHandPoseObservation) -> HandObservation? {
        let mapping: [(VNHumanHandPoseObservation.JointName, HandLandmarkName)] = [
            (.wrist, .wrist),
            (.thumbCMC, .thumbCMC),
            (.thumbMP, .thumbMP),
            (.thumbIP, .thumbIP),
            (.thumbTip, .thumbTip),
            (.indexMCP, .indexMCP),
            (.indexPIP, .indexPIP),
            (.indexDIP, .indexDIP),
            (.indexTip, .indexTip),
            (.middleMCP, .middleMCP),
            (.middlePIP, .middlePIP),
            (.middleDIP, .middleDIP),
            (.middleTip, .middleTip),
            (.ringMCP, .ringMCP),
            (.ringPIP, .ringPIP),
            (.ringDIP, .ringDIP),
            (.ringTip, .ringTip),
            (.littleMCP, .littleMCP),
            (.littlePIP, .littlePIP),
            (.littleDIP, .littleDIP),
            (.littleTip, .littleTip),
        ]

        guard let points = try? observation.recognizedPoints(.all) else {
            return nil
        }

        var landmarks: [HandLandmarkName: CGPoint] = [:]
        for (visionName, landmarkName) in mapping {
            guard let recognized = points[visionName], recognized.confidence > 0.2 else {
                continue
            }
            landmarks[landmarkName] = CGPoint(x: recognized.location.x, y: recognized.location.y)
        }

        guard !landmarks.isEmpty else {
            return nil
        }

        let chirality: HandChirality
        switch observation.chirality {
        case .left:
            chirality = .left
        case .right:
            chirality = .right
        default:
            chirality = .unknown
        }

        return HandObservation(
            chirality: chirality,
            confidence: observation.confidence,
            boundingBox: boundingBox(for: Array(landmarks.values)),
            landmarks: landmarks
        )
    }

    private static func boundingBox(for points: [CGPoint]) -> CGRect {
        guard let first = points.first else {
            return .zero
        }

        let minX = points.map(\.x).reduce(first.x, min)
        let maxX = points.map(\.x).reduce(first.x, max)
        let minY = points.map(\.y).reduce(first.y, min)
        let maxY = points.map(\.y).reduce(first.y, max)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
