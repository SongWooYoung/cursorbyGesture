import CoreGraphics

public struct CGPointEMAFilter {
    private var smoothingStrength: CGFloat
    private var state: CGPoint?

    public init(alpha: CGFloat) {
        smoothingStrength = Self.normalizedStrength(alpha)
    }

    public mutating func reset() {
        state = nil
    }

    public mutating func setAlpha(_ alpha: CGFloat) {
        smoothingStrength = Self.normalizedStrength(alpha)
    }

    public mutating func update(_ input: CGPoint) -> CGPoint {
        guard let state else {
            self.state = input
            return input
        }

        let distance = Geometry.distance(input, state)
        if distance <= deadZone {
            return state
        }

        let alpha = adaptiveAlpha(for: distance)

        let next = CGPoint(
            x: (alpha * input.x) + ((1 - alpha) * state.x),
            y: (alpha * input.y) + ((1 - alpha) * state.y)
        )
        self.state = next
        return next
    }

    private var deadZone: CGFloat {
        1.5 + (smoothingStrength * 10)
    }

    private func adaptiveAlpha(for distance: CGFloat) -> CGFloat {
        let baseAlpha = max(0.04, 1 - (smoothingStrength * 0.96))
        let responseBoost = Geometry.clamped(distance / 120, min: 0, max: 1)
        return baseAlpha + ((1 - baseAlpha) * responseBoost)
    }

    private static func normalizedStrength(_ value: CGFloat) -> CGFloat {
        Geometry.clamped(value, min: 0.0, max: 1.0)
    }
}
