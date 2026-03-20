import CoreGraphics
import Foundation

public final class KeyboardController {
    private let factory = CGEventFactory()

    public init() {}

    public func sendShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        factory.keyboardEvent(keyCode: keyCode, keyDown: true, flags: flags)?.post(tap: .cghidEventTap)
        factory.keyboardEvent(keyCode: keyCode, keyDown: false, flags: flags)?.post(tap: .cghidEventTap)
    }
}
