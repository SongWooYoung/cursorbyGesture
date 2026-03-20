import Foundation

public enum Logger {
    public static func info(_ message: @autoclosure () -> String) {
        print("[INFO] \(message())")
    }

    public static func warning(_ message: @autoclosure () -> String) {
        fputs("[WARN] \(message())\n", stderr)
    }

    public static func error(_ message: @autoclosure () -> String) {
        fputs("[ERROR] \(message())\n", stderr)
    }
}
