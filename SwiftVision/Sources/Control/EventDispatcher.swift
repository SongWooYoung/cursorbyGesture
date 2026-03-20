import Config
import CoreGraphics
import Foundation
import Gesture
import Support

public final class EventDispatcher {
    private let mouseController: MouseController
    private let keyboardController: KeyboardController
    private let screenCaptureController: ScreenCaptureController

    public init() {
        mouseController = MouseController()
        keyboardController = KeyboardController()
        screenCaptureController = ScreenCaptureController(
            keyboardController: keyboardController,
            mouseController: mouseController
        )
    }

    public func dispatch(_ actions: [GestureAction]) {
        for action in actions {
            switch action {
            case .moveCursor(let point):
                mouseController.move(to: point)
            case .leftClick:
                mouseController.leftClick(at: mouseController.currentCursorPosition())
            case .scroll(let deltaY):
                mouseController.scroll(deltaY: deltaY)
            case .command(let command):
                dispatch(command)
            case .beginAreaCapture(let point):
                screenCaptureController.begin(at: point)
            case .updateAreaCapture(let point):
                screenCaptureController.update(to: point)
            case .endAreaCapture(let point):
                screenCaptureController.end(at: point)
            }
        }
    }

    private func dispatch(_ command: SystemCommand) {
        switch command {
        case .previousPage:
            keyboardController.sendShortcut(keyCode: 123, flags: .maskControl)
        case .nextPage:
            keyboardController.sendShortcut(keyCode: 124, flags: .maskControl)
        case .windowOverview:
            keyboardController.sendShortcut(keyCode: 126, flags: .maskControl)
        case .zoomIn:
            keyboardController.sendShortcut(keyCode: 24, flags: .maskCommand)
        case .zoomOut:
            keyboardController.sendShortcut(keyCode: 27, flags: .maskCommand)
        }
    }
}
