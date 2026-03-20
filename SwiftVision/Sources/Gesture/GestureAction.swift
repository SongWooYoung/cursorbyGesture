import CoreGraphics
import Foundation

public enum SystemCommand: Equatable, Sendable {
    case previousPage
    case nextPage
    case windowOverview
    case zoomIn
    case zoomOut
}

public enum GestureAction: Equatable, Sendable {
    case moveCursor(CGPoint)
    case leftClick
    case scroll(deltaY: Int32)
    case command(SystemCommand)
    case beginAreaCapture(CGPoint)
    case updateAreaCapture(CGPoint)
    case endAreaCapture(CGPoint)
}
