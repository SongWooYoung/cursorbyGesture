import Foundation

struct GestureStateChange<Value: Equatable>: Equatable {
    let previous: Value
    let current: Value
}

final class GestureStateTracker<Value: Equatable> {
    private(set) var currentValue: Value

    init(initialValue: Value) {
        currentValue = initialValue
    }

    @discardableResult
    func update(_ newValue: Value) -> GestureStateChange<Value>? {
        guard newValue != currentValue else {
            return nil
        }

        let change = GestureStateChange(previous: currentValue, current: newValue)
        currentValue = newValue
        return change
    }

    func reset(to value: Value) {
        currentValue = value
    }
}