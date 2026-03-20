import CoreGraphics
import Foundation

public final class MouseController {
    private let factory = CGEventFactory()
    private var isDragging = false

    public init() {}

    public func move(to point: CGPoint) {
        let eventType: CGEventType = isDragging ? .leftMouseDragged : .mouseMoved
        factory.mouseEvent(type: eventType, position: point)?.post(tap: .cghidEventTap)
    }

    public func leftClick(at point: CGPoint) {
        factory.mouseEvent(type: .leftMouseDown, position: point)?.post(tap: .cghidEventTap)
        factory.mouseEvent(type: .leftMouseUp, position: point)?.post(tap: .cghidEventTap)
    }

    public func scroll(deltaY: Int32) {
        factory.scrollEvent(deltaY: deltaY)?.post(tap: .cghidEventTap)
    }

    public func beginDrag(at point: CGPoint) {
        isDragging = true
        factory.mouseEvent(type: .leftMouseDown, position: point)?.post(tap: .cghidEventTap)
    }

    public func updateDrag(to point: CGPoint) {
        factory.mouseEvent(type: .leftMouseDragged, position: point)?.post(tap: .cghidEventTap)
    }

    public func endDrag(at point: CGPoint) {
        factory.mouseEvent(type: .leftMouseUp, position: point)?.post(tap: .cghidEventTap)
        isDragging = false
    }

    public func currentCursorPosition() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }
}
