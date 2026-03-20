import CoreGraphics
import Foundation

public struct CGEventFactory {
    public init() {}

    public func keyboardEvent(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags = []) -> CGEvent? {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
        event?.flags = flags
        return event
    }

    public func mouseEvent(
        type: CGEventType,
        position: CGPoint,
        button: CGMouseButton = .left
    ) -> CGEvent? {
        CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: position,
            mouseButton: button
        )
    }

    public func scrollEvent(deltaY: Int32) -> CGEvent? {
        CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: deltaY,
            wheel2: 0,
            wheel3: 0
        )
    }
}
