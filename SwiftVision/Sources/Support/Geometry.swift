import CoreGraphics

public enum Geometry {
    public static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }

    public static func midpoint(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2)
    }

    public static func average(_ points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else {
            return nil
        }

        let total = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        return CGPoint(
            x: total.x / CGFloat(points.count),
            y: total.y / CGFloat(points.count)
        )
    }

    public static func clamped(_ value: CGFloat, min lowerBound: CGFloat, max upperBound: CGFloat) -> CGFloat {
        Swift.max(lowerBound, Swift.min(upperBound, value))
    }
}

public extension CGPoint {
    func denormalized(in rect: CGRect, mirrorX: Bool = false) -> CGPoint {
        let resolvedX = mirrorX ? (1 - x) : x
        return CGPoint(
            x: rect.minX + (resolvedX * rect.width),
            y: rect.minY + (y * rect.height)
        )
    }
}
