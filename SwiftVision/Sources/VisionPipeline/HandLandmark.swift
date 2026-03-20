import CoreGraphics
import Foundation
import Support

public enum HandLandmarkName: CaseIterable, Hashable, Sendable {
    case wrist
    case thumbCMC
    case thumbMP
    case thumbIP
    case thumbTip
    case indexMCP
    case indexPIP
    case indexDIP
    case indexTip
    case middleMCP
    case middlePIP
    case middleDIP
    case middleTip
    case ringMCP
    case ringPIP
    case ringDIP
    case ringTip
    case littleMCP
    case littlePIP
    case littleDIP
    case littleTip
}

public extension HandLandmarkName {
    var displayName: String {
        switch self {
        case .wrist:
            return "wrist"
        case .thumbCMC:
            return "thumb-cmc"
        case .thumbMP:
            return "thumb-mp"
        case .thumbIP:
            return "thumb-ip"
        case .thumbTip:
            return "thumb"
        case .indexMCP:
            return "index-mcp"
        case .indexPIP:
            return "index-pip"
        case .indexDIP:
            return "index-dip"
        case .indexTip:
            return "index"
        case .middleMCP:
            return "middle-mcp"
        case .middlePIP:
            return "middle-pip"
        case .middleDIP:
            return "middle-dip"
        case .middleTip:
            return "middle"
        case .ringMCP:
            return "ring-mcp"
        case .ringPIP:
            return "ring-pip"
        case .ringDIP:
            return "ring-dip"
        case .ringTip:
            return "ring"
        case .littleMCP:
            return "little-mcp"
        case .littlePIP:
            return "little-pip"
        case .littleDIP:
            return "little-dip"
        case .littleTip:
            return "little"
        }
    }

    static let fingertipNames: [HandLandmarkName] = [
        .thumbTip,
        .indexTip,
        .middleTip,
        .ringTip,
        .littleTip,
    ]

    static let skeletonConnections: [(HandLandmarkName, HandLandmarkName)] = [
        (.wrist, .thumbCMC),
        (.thumbCMC, .thumbMP),
        (.thumbMP, .thumbIP),
        (.thumbIP, .thumbTip),
        (.wrist, .indexMCP),
        (.indexMCP, .indexPIP),
        (.indexPIP, .indexDIP),
        (.indexDIP, .indexTip),
        (.wrist, .middleMCP),
        (.middleMCP, .middlePIP),
        (.middlePIP, .middleDIP),
        (.middleDIP, .middleTip),
        (.wrist, .ringMCP),
        (.ringMCP, .ringPIP),
        (.ringPIP, .ringDIP),
        (.ringDIP, .ringTip),
        (.wrist, .littleMCP),
        (.littleMCP, .littlePIP),
        (.littlePIP, .littleDIP),
        (.littleDIP, .littleTip),
    ]
}

public enum HandChirality: Sendable {
    case left
    case right
    case unknown
}

public struct HandObservation: Sendable {
    public let chirality: HandChirality
    public let confidence: Float
    public let boundingBox: CGRect
    public let landmarks: [HandLandmarkName: CGPoint]

    public init(
        chirality: HandChirality,
        confidence: Float,
        boundingBox: CGRect,
        landmarks: [HandLandmarkName: CGPoint]
    ) {
        self.chirality = chirality
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }

    public func point(_ landmark: HandLandmarkName) -> CGPoint? {
        landmarks[landmark]
    }

    public var center: CGPoint {
        if let average = Geometry.average(Array(landmarks.values)) {
            return average
        }
        return CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }

    public var hasWrist: Bool {
        point(.wrist) != nil
    }

    public var palmAnchor: CGPoint? {
        if let wrist = point(.wrist) {
            return wrist
        }

        let palmBasePoints = [
            point(.indexMCP),
            point(.middleMCP),
            point(.ringMCP),
            point(.littleMCP),
        ].compactMap { $0 }

        if let average = Geometry.average(palmBasePoints), !palmBasePoints.isEmpty {
            return average
        }

        return nil
    }

    public var fingertipPoints: [CGPoint] {
        HandLandmarkName.fingertipNames.compactMap { landmarks[$0] }
    }

    public var recognizedFingers: [HandLandmarkName] {
        HandLandmarkName.fingertipNames.filter { landmarks[$0] != nil }
    }

    public var compactness: CGFloat? {
        guard let center = Geometry.average(fingertipPoints), !fingertipPoints.isEmpty else {
            return nil
        }

        let distances = fingertipPoints.map { Geometry.distance($0, center) }
        return distances.reduce(0, +) / CGFloat(distances.count)
    }

    public func pinchDistance(_ first: HandLandmarkName, _ second: HandLandmarkName) -> CGFloat? {
        guard let firstPoint = point(first), let secondPoint = point(second) else {
            return nil
        }
        return Geometry.distance(firstPoint, secondPoint)
    }

    public var handScale: CGFloat {
        max(max(boundingBox.width, boundingBox.height), 0.1)
    }

    public func isIndexExtended(thresholdScale: CGFloat = 0.12) -> Bool {
        isFingerExtended(tip: .indexTip, pip: .indexPIP, mcp: .indexMCP, thresholdScale: thresholdScale)
    }

    public func isMiddleExtended(thresholdScale: CGFloat = 0.12) -> Bool {
        isFingerExtended(tip: .middleTip, pip: .middlePIP, mcp: .middleMCP, thresholdScale: thresholdScale)
    }

    public func isRingFolded(thresholdScale: CGFloat = 0.08) -> Bool {
        isFingerFolded(tip: .ringTip, pip: .ringPIP, mcp: .ringMCP, thresholdScale: thresholdScale)
    }

    public func isLittleFolded(thresholdScale: CGFloat = 0.08) -> Bool {
        isFingerFolded(tip: .littleTip, pip: .littlePIP, mcp: .littleMCP, thresholdScale: thresholdScale)
    }

    public func isThumbFolded() -> Bool {
        guard
            let palmAnchor,
            let thumbTip = point(.thumbTip),
            let thumbIP = point(.thumbIP)
        else {
            return true
        }

        let tipDistance = Geometry.distance(palmAnchor, thumbTip)
        let ipDistance = Geometry.distance(palmAnchor, thumbIP)
        return tipDistance <= ipDistance + (handScale * 0.08)
    }

    public func isTwoFingerScrollPose(
        extendedThresholdScale: CGFloat = 0.12,
        foldedThresholdScale: CGFloat = 0.08
    ) -> Bool {
        guard palmAnchor != nil else {
            return false
        }

        return isIndexExtended(thresholdScale: extendedThresholdScale)
            && isMiddleExtended(thresholdScale: extendedThresholdScale)
            && isRingFolded(thresholdScale: foldedThresholdScale)
            && isLittleFolded(thresholdScale: foldedThresholdScale)
    }

    private func isFingerExtended(
        tip: HandLandmarkName,
        pip: HandLandmarkName,
        mcp: HandLandmarkName,
        thresholdScale: CGFloat
    ) -> Bool {
        guard let extensionDelta = fingerExtensionDelta(tip: tip, pip: pip, mcp: mcp) else {
            return false
        }

        return extensionDelta > (handScale * thresholdScale)
    }

    private func isFingerFolded(
        tip: HandLandmarkName,
        pip: HandLandmarkName,
        mcp: HandLandmarkName,
        thresholdScale: CGFloat
    ) -> Bool {
        guard let extensionDelta = fingerExtensionDelta(tip: tip, pip: pip, mcp: mcp) else {
            return false
        }

        return extensionDelta < (handScale * thresholdScale)
    }

    private func fingerExtensionDelta(
        tip: HandLandmarkName,
        pip: HandLandmarkName,
        mcp: HandLandmarkName
    ) -> CGFloat? {
        guard
            let palmAnchor,
            let tipPoint = point(tip),
            let pipPoint = point(pip),
            let mcpPoint = point(mcp)
        else {
            return nil
        }

        let tipDistance = Geometry.distance(palmAnchor, tipPoint)
        let baselineDistance = max(Geometry.distance(palmAnchor, pipPoint), Geometry.distance(palmAnchor, mcpPoint))
        return tipDistance - baselineDistance
    }
}
