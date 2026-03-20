import Foundation

public struct CooldownGate {
    private let cooldown: TimeInterval
    private var lastTriggerDate: [String: Date] = [:]

    public init(cooldown: TimeInterval) {
        self.cooldown = cooldown
    }

    public mutating func reset() {
        lastTriggerDate.removeAll()
    }

    public mutating func allows(_ key: String, now: Date) -> Bool {
        guard let lastDate = lastTriggerDate[key] else {
            lastTriggerDate[key] = now
            return true
        }

        guard now.timeIntervalSince(lastDate) >= cooldown else {
            return false
        }

        lastTriggerDate[key] = now
        return true
    }
}
