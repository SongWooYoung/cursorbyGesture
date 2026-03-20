import CoreGraphics
import Foundation

public final class ScreenCaptureController {
    private let keyboardController: KeyboardController
    private let mouseController: MouseController
    private var isCapturing = false

    public init(
        keyboardController: KeyboardController,
        mouseController: MouseController
    ) {
        self.keyboardController = keyboardController
        self.mouseController = mouseController
    }

    public func begin(at point: CGPoint) {
        guard !isCapturing else {
            return
        }

        keyboardController.sendShortcut(keyCode: 21, flags: [.maskCommand, .maskShift])
        Thread.sleep(forTimeInterval: 0.05)
        mouseController.beginDrag(at: point)
        isCapturing = true
    }

    public func update(to point: CGPoint) {
        guard isCapturing else {
            return
        }
        mouseController.updateDrag(to: point)
    }

    public func end(at point: CGPoint) {
        guard isCapturing else {
            return
        }
        mouseController.endDrag(at: point)
        isCapturing = false
    }
}
