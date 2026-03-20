import AppKit
import CoreGraphics
import Foundation
import Support

final class CursorSmoothingPanelController: NSWindowController {
    private let smoothingSlider: NSSlider
    private let scrollSpeedSlider: NSSlider
    private let scrollActivationSlider: NSSlider
    private let scrollPoseExtendedSlider: NSSlider
    private let scrollPoseFoldedSlider: NSSlider
    private let smoothingValueLabel = NSTextField(labelWithString: "")
    private let scrollSpeedValueLabel = NSTextField(labelWithString: "")
    private let scrollActivationValueLabel = NSTextField(labelWithString: "")
    private let scrollPoseExtendedValueLabel = NSTextField(labelWithString: "")
    private let scrollPoseFoldedValueLabel = NSTextField(labelWithString: "")
    private let onSmoothingChanged: (CGFloat) -> Void
    private let onScrollSpeedChanged: (Int32) -> Void
    private let onScrollActivationChanged: (CGFloat) -> Void
    private let onScrollPoseExtendedChanged: (CGFloat) -> Void
    private let onScrollPoseFoldedChanged: (CGFloat) -> Void

    init(
        initialSmoothingValue: CGFloat,
        initialScrollSpeed: Int32,
        initialScrollActivationThreshold: CGFloat,
        initialScrollPoseExtendedThreshold: CGFloat,
        initialScrollPoseFoldedThreshold: CGFloat,
        onSmoothingChanged: @escaping (CGFloat) -> Void,
        onScrollSpeedChanged: @escaping (Int32) -> Void,
        onScrollActivationChanged: @escaping (CGFloat) -> Void,
        onScrollPoseExtendedChanged: @escaping (CGFloat) -> Void,
        onScrollPoseFoldedChanged: @escaping (CGFloat) -> Void
    ) {
        self.onSmoothingChanged = onSmoothingChanged
        self.onScrollSpeedChanged = onScrollSpeedChanged
        self.onScrollActivationChanged = onScrollActivationChanged
        self.onScrollPoseExtendedChanged = onScrollPoseExtendedChanged
        self.onScrollPoseFoldedChanged = onScrollPoseFoldedChanged
        smoothingSlider = NSSlider(value: Double(initialSmoothingValue), minValue: 0.01, maxValue: 1.0, target: nil, action: nil)
        scrollSpeedSlider = NSSlider(value: Double(initialScrollSpeed), minValue: 1, maxValue: 40, target: nil, action: nil)
        scrollActivationSlider = NSSlider(value: Double(initialScrollActivationThreshold), minValue: 0.01, maxValue: 0.12, target: nil, action: nil)
        scrollPoseExtendedSlider = NSSlider(value: Double(initialScrollPoseExtendedThreshold), minValue: 0.04, maxValue: 0.25, target: nil, action: nil)
        scrollPoseFoldedSlider = NSSlider(value: Double(initialScrollPoseFoldedThreshold), minValue: 0.02, maxValue: 0.20, target: nil, action: nil)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 520),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Gesture Controls"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: panel)

        configureContent(
            initialSmoothingValue: initialSmoothingValue,
            initialScrollSpeed: initialScrollSpeed,
            initialScrollActivationThreshold: initialScrollActivationThreshold,
            initialScrollPoseExtendedThreshold: initialScrollPoseExtendedThreshold,
            initialScrollPoseFoldedThreshold: initialScrollPoseFoldedThreshold
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func showPanel() {
        guard let window else {
            return
        }

        window.center()
        showWindow(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureContent(
        initialSmoothingValue: CGFloat,
        initialScrollSpeed: Int32,
        initialScrollActivationThreshold: CGFloat,
        initialScrollPoseExtendedThreshold: CGFloat,
        initialScrollPoseFoldedThreshold: CGFloat
    ) {
        guard let window else {
            return
        }

        let descriptionLabel = NSTextField(labelWithString: "Adjust cursor stabilization and scroll recognition in real time.")
        descriptionLabel.textColor = .secondaryLabelColor

        let smoothingHintLabel = NSTextField(labelWithString: "Higher smoothing reduces tremor more. 1.00 = strongest stabilization")
        smoothingHintLabel.textColor = .secondaryLabelColor
        smoothingHintLabel.lineBreakMode = .byWordWrapping
        smoothingHintLabel.maximumNumberOfLines = 2

        let smoothingSectionLabel = NSTextField(labelWithString: "Cursor Smoothing")
        smoothingSectionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)

        let scrollSectionLabel = NSTextField(labelWithString: "Scroll Speed")
        scrollSectionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)

        let scrollHintLabel = NSTextField(labelWithString: "Higher values send larger scroll deltas per gesture step")
        scrollHintLabel.textColor = .secondaryLabelColor
        scrollHintLabel.lineBreakMode = .byWordWrapping
        scrollHintLabel.maximumNumberOfLines = 2

        let scrollActivationSectionLabel = NSTextField(labelWithString: "Scroll Activation Threshold")
        scrollActivationSectionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)

        let scrollActivationHintLabel = NSTextField(labelWithString: "Lower values make smaller wrist movements trigger scroll")
        scrollActivationHintLabel.textColor = .secondaryLabelColor
        scrollActivationHintLabel.lineBreakMode = .byWordWrapping
        scrollActivationHintLabel.maximumNumberOfLines = 2

        let scrollPoseExtendedSectionLabel = NSTextField(labelWithString: "Pose Extended Threshold")
        scrollPoseExtendedSectionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)

        let scrollPoseExtendedHintLabel = NSTextField(labelWithString: "Lower values make index and middle count as extended more easily")
        scrollPoseExtendedHintLabel.textColor = .secondaryLabelColor
        scrollPoseExtendedHintLabel.lineBreakMode = .byWordWrapping
        scrollPoseExtendedHintLabel.maximumNumberOfLines = 2

        let scrollPoseFoldedSectionLabel = NSTextField(labelWithString: "Pose Folded Threshold")
        scrollPoseFoldedSectionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)

        let scrollPoseFoldedHintLabel = NSTextField(labelWithString: "Higher values make ring and little count as folded more easily")
        scrollPoseFoldedHintLabel.textColor = .secondaryLabelColor
        scrollPoseFoldedHintLabel.lineBreakMode = .byWordWrapping
        scrollPoseFoldedHintLabel.maximumNumberOfLines = 2

        smoothingSlider.target = self
        smoothingSlider.action = #selector(handleSmoothingSliderChange(_:))
        smoothingSlider.isContinuous = true

        scrollSpeedSlider.target = self
        scrollSpeedSlider.action = #selector(handleScrollSpeedSliderChange(_:))
        scrollSpeedSlider.isContinuous = true
        scrollSpeedSlider.allowsTickMarkValuesOnly = true
        scrollSpeedSlider.numberOfTickMarks = 8

        scrollActivationSlider.target = self
        scrollActivationSlider.action = #selector(handleScrollActivationSliderChange(_:))
        scrollActivationSlider.isContinuous = true

        scrollPoseExtendedSlider.target = self
        scrollPoseExtendedSlider.action = #selector(handleScrollPoseExtendedSliderChange(_:))
        scrollPoseExtendedSlider.isContinuous = true

        scrollPoseFoldedSlider.target = self
        scrollPoseFoldedSlider.action = #selector(handleScrollPoseFoldedSliderChange(_:))
        scrollPoseFoldedSlider.isContinuous = true

        smoothingValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        scrollSpeedValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        scrollActivationValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        scrollPoseExtendedValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        scrollPoseFoldedValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        let stackView = NSStackView(views: [
            descriptionLabel,
            smoothingSectionLabel,
            smoothingHintLabel,
            smoothingSlider,
            smoothingValueLabel,
            scrollSectionLabel,
            scrollHintLabel,
            scrollSpeedSlider,
            scrollSpeedValueLabel,
            scrollActivationSectionLabel,
            scrollActivationHintLabel,
            scrollActivationSlider,
            scrollActivationValueLabel,
            scrollPoseExtendedSectionLabel,
            scrollPoseExtendedHintLabel,
            scrollPoseExtendedSlider,
            scrollPoseExtendedValueLabel,
            scrollPoseFoldedSectionLabel,
            scrollPoseFoldedHintLabel,
            scrollPoseFoldedSlider,
            scrollPoseFoldedValueLabel,
        ])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 520))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            smoothingSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            scrollSpeedSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            scrollActivationSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            scrollPoseExtendedSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            scrollPoseFoldedSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])

        window.contentView = contentView
        updateSmoothingValueLabel(initialSmoothingValue)
        updateScrollSpeedValueLabel(initialScrollSpeed)
        updateScrollActivationValueLabel(initialScrollActivationThreshold)
        updateScrollPoseExtendedValueLabel(initialScrollPoseExtendedThreshold)
        updateScrollPoseFoldedValueLabel(initialScrollPoseFoldedThreshold)
    }

    private func updateSmoothingValueLabel(_ value: CGFloat) {
        smoothingValueLabel.stringValue = String(format: "CURSOR_SMOOTHING = %.2f", Double(value))
    }

    private func updateScrollSpeedValueLabel(_ value: Int32) {
        scrollSpeedValueLabel.stringValue = "SCROLL_STEP = \(value)"
    }

    private func updateScrollActivationValueLabel(_ value: CGFloat) {
        scrollActivationValueLabel.stringValue = String(format: "SCROLL_ACTIVATION_THRESHOLD = %.3f", Double(value))
    }

    private func updateScrollPoseExtendedValueLabel(_ value: CGFloat) {
        scrollPoseExtendedValueLabel.stringValue = String(format: "SCROLL_POSE_EXTENDED_THRESHOLD = %.3f", Double(value))
    }

    private func updateScrollPoseFoldedValueLabel(_ value: CGFloat) {
        scrollPoseFoldedValueLabel.stringValue = String(format: "SCROLL_POSE_FOLDED_THRESHOLD = %.3f", Double(value))
    }

    @objc private func handleSmoothingSliderChange(_ sender: NSSlider) {
        let value = Geometry.clamped(CGFloat(sender.doubleValue), min: 0.01, max: 1.0)
        updateSmoothingValueLabel(value)
        onSmoothingChanged(value)
    }

    @objc private func handleScrollSpeedSliderChange(_ sender: NSSlider) {
        let value = Int32(max(1, Int(sender.doubleValue.rounded())))
        sender.doubleValue = Double(value)
        updateScrollSpeedValueLabel(value)
        onScrollSpeedChanged(value)
    }

    @objc private func handleScrollActivationSliderChange(_ sender: NSSlider) {
        let value = Geometry.clamped(CGFloat(sender.doubleValue), min: 0.01, max: 0.12)
        updateScrollActivationValueLabel(value)
        onScrollActivationChanged(value)
    }

    @objc private func handleScrollPoseExtendedSliderChange(_ sender: NSSlider) {
        let value = Geometry.clamped(CGFloat(sender.doubleValue), min: 0.04, max: 0.25)
        updateScrollPoseExtendedValueLabel(value)
        onScrollPoseExtendedChanged(value)
    }

    @objc private func handleScrollPoseFoldedSliderChange(_ sender: NSSlider) {
        let value = Geometry.clamped(CGFloat(sender.doubleValue), min: 0.02, max: 0.20)
        updateScrollPoseFoldedValueLabel(value)
        onScrollPoseFoldedChanged(value)
    }
}