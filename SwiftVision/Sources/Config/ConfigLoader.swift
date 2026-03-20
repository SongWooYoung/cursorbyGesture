import Foundation

public enum ConfigLoader {
    public static func load(from path: String = ".env") -> AppConfig {
        let fileValues = parseEnvFile(path: path)
        let environment = ProcessInfo.processInfo.environment.merging(fileValues) { current, _ in current }

        return AppConfig(
            inputMode: VideoInputMode(rawValue: environment["VIDEO_INPUT_MODE", default: "camera"].lowercased()) ?? .camera,
            cameraUniqueID: normalizedOptional(environment["CAMERA_UNIQUE_ID"]),
            rtspURL: normalizedOptional(environment["RTSP_URL"]),
            mirrorCursorHorizontally: environment["MIRROR_CURSOR_HORIZONTALLY", default: "true"] != "false",
            thresholds: ThresholdConfig(
                smoothingAlpha: cgFloat(environment["CURSOR_SMOOTHING"], default: 0.35),
                scrollStep: int32(environment["SCROLL_STEP"], default: 8),
                scrollActivationThreshold: cgFloat(environment["SCROLL_ACTIVATION_THRESHOLD"], default: 0.04),
                scrollPoseExtendedThreshold: cgFloat(environment["SCROLL_POSE_EXTENDED_THRESHOLD"], default: 0.12),
                scrollPoseFoldedThreshold: cgFloat(environment["SCROLL_POSE_FOLDED_THRESHOLD"], default: 0.08),
                clickPinchDistance: cgFloat(environment["CLICK_PINCH_DISTANCE"], default: 0.065),
                clickPinchReleaseDistance: cgFloat(environment["CLICK_PINCH_RELEASE_DISTANCE"], default: 0.09),
                overviewCompactness: cgFloat(environment["OVERVIEW_COMPACTNESS"], default: 0.12),
                zoomDeltaThreshold: cgFloat(environment["ZOOM_DELTA_THRESHOLD"], default: 0.04),
                swipeVelocityThreshold: cgFloat(environment["SWIPE_VELOCITY_THRESHOLD"], default: 0.9),
                swipeDistanceThreshold: cgFloat(environment["SWIPE_DISTANCE_THRESHOLD"], default: 0.18),
                capturePinchDistance: cgFloat(environment["CAPTURE_PINCH_DISTANCE"], default: 0.07),
                captureSpreadThreshold: cgFloat(environment["CAPTURE_SPREAD_THRESHOLD"], default: 0.16),
                minimumGestureFrames: int(environment["MINIMUM_GESTURE_FRAMES"], default: 3),
                gestureCooldownSeconds: timeInterval(environment["GESTURE_COOLDOWN_SECONDS"], default: 0.7)
            )
        )
    }

    public static func updateEnvValue(_ key: String, value: String, at path: String = ".env") throws {
        let fileURL = URL(fileURLWithPath: path)
        let contents = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
        var lines = contents.components(separatedBy: .newlines)

        if lines.count == 1, lines[0].isEmpty {
            lines = []
        }

        let renderedValue = "\(key)=\(value)"
        var didUpdate = false

        for index in lines.indices {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), let separator = trimmed.firstIndex(of: "=") else {
                continue
            }

            let currentKey = String(trimmed[..<separator]).trimmingCharacters(in: .whitespaces)
            if currentKey == key {
                lines[index] = renderedValue
                didUpdate = true
                break
            }
        }

        if !didUpdate {
            lines.append(renderedValue)
        }

        let updatedContents = lines.joined(separator: "\n") + "\n"
        try updatedContents.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static func parseEnvFile(path: String) -> [String: String] {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return [:]
        }

        var values: [String: String] = [:]
        contents.split(whereSeparator: \.isNewline).forEach { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), let separator = line.firstIndex(of: "=") else {
                return
            }

            let key = String(line[..<separator]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            values[key] = value
        }
        return values
    }

    private static func cgFloat(_ value: String?, default defaultValue: CGFloat) -> CGFloat {
        guard let value, let parsed = Double(value) else {
            return defaultValue
        }
        return CGFloat(parsed)
    }

    private static func int(_ value: String?, default defaultValue: Int) -> Int {
        guard let value, let parsed = Int(value) else {
            return defaultValue
        }
        return parsed
    }

    private static func int32(_ value: String?, default defaultValue: Int32) -> Int32 {
        guard let value, let parsed = Int32(value) else {
            return defaultValue
        }
        return parsed
    }

    private static func timeInterval(_ value: String?, default defaultValue: TimeInterval) -> TimeInterval {
        guard let value, let parsed = Double(value) else {
            return defaultValue
        }
        return parsed
    }

    private static func normalizedOptional(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
