import AppKit
import Capture
import CoreGraphics
import CoreImage
import CoreMedia
import Foundation
import VisionPipeline

@MainActor
final class HandDebugPreviewPanelController: NSWindowController, NSWindowDelegate {
    private let frameBuffer: FrameBuffer
    private let pipelineState: PipelineState
    private let previewView = HandDebugPreviewView(frame: .zero)
    private let statusLabel = NSTextField(labelWithString: "Waiting for camera frames…")
    private let mirrorHorizontally: Bool
    private let ciContext = CIContext(options: nil)
    private var refreshTimer: Timer?

    init(
        frameBuffer: FrameBuffer,
        pipelineState: PipelineState,
        mirrorHorizontally: Bool
    ) {
        self.frameBuffer = frameBuffer
        self.pipelineState = pipelineState
        self.mirrorHorizontally = mirrorHorizontally

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 760),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Hand Debug Preview"
        panel.isFloatingPanel = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: panel)

        configureWindow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func showPanel() {
        guard let window else {
            return
        }

        window.setFrameAutosaveName("HandDebugPreviewPanel")
        showWindow(nil)
        window.orderFrontRegardless()
        startRefreshing()
    }

    private func configureWindow() {
        guard let window else {
            return
        }

        window.delegate = self

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.mirrorHorizontally = mirrorHorizontally

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previewView)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            previewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            previewView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            previewView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -8),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])

        window.contentView = contentView
    }

    func windowWillClose(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func startRefreshing() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30.0, target: self, selector: #selector(handleRefreshTimer), userInfo: nil, repeats: true)
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc private func handleRefreshTimer() {
        refreshPreview()
    }

    private func refreshPreview() {
        let frame = frameBuffer.snapshot()
        let result = pipelineState.snapshot()
        let image = frame.flatMap(makeCGImage)
        previewView.update(image: image, observations: result?.observations ?? [])

        let handCount = result?.observations.count ?? 0
        let jointCount = result?.observations.reduce(0) { partial, observation in
            partial + observation.landmarks.count
        } ?? 0
        statusLabel.stringValue = "hands=\(handCount) joints=\(jointCount) mirrored=\(mirrorHorizontally)"
    }

    private func makeCGImage(from frame: VideoFrame) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(frame.sampleBuffer) else {
            return nil
        }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        return ciContext.createCGImage(image, from: image.extent)
    }
}

private final class HandDebugPreviewView: NSView {
    var mirrorHorizontally = false

    private var frameImage: CGImage?
    private var observations: [HandObservation] = []

    override var isFlipped: Bool {
        true
    }

    func update(image: CGImage?, observations: [HandObservation]) {
        frameImage = image
        self.observations = observations
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        dirtyRect.fill()

        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        let renderRect = bounds.insetBy(dx: 0, dy: 0)
        let imageRect = resolvedImageRect(in: renderRect)
        drawFrame(in: context, imageRect: imageRect)
        drawSkeleton(in: context, imageRect: imageRect)
    }

    private func drawFrame(in context: CGContext, imageRect: CGRect) {
        guard let frameImage else {
            return
        }

        context.saveGState()
        context.translateBy(x: imageRect.minX, y: imageRect.maxY)
        context.scaleBy(x: mirrorHorizontally ? -1 : 1, y: -1)

        let drawRect = CGRect(
            x: mirrorHorizontally ? -imageRect.width : 0,
            y: 0,
            width: imageRect.width,
            height: imageRect.height
        )
        context.draw(frameImage, in: drawRect)
        context.restoreGState()
    }

    private func drawSkeleton(in context: CGContext, imageRect: CGRect) {
        let colors: [NSColor] = [.systemGreen, .systemOrange]

        for (index, observation) in observations.enumerated() {
            let color = colors[index % colors.count]
            drawConnections(for: observation, color: color, in: context, imageRect: imageRect)
            drawPoints(for: observation, color: color, in: context, imageRect: imageRect)
        }
    }

    private func drawConnections(
        for observation: HandObservation,
        color: NSColor,
        in context: CGContext,
        imageRect: CGRect
    ) {
        context.saveGState()
        context.setStrokeColor(color.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(2)

        for (startName, endName) in HandLandmarkName.skeletonConnections {
            guard let start = observation.point(startName), let end = observation.point(endName) else {
                continue
            }

            context.move(to: convert(point: start, in: imageRect))
            context.addLine(to: convert(point: end, in: imageRect))
            context.strokePath()
        }

        context.restoreGState()
    }

    private func drawPoints(
        for observation: HandObservation,
        color: NSColor,
        in context: CGContext,
        imageRect: CGRect
    ) {
        for name in HandLandmarkName.allCases {
            guard let point = observation.point(name) else {
                continue
            }

            let resolvedPoint = convert(point: point, in: imageRect)
            let radius: CGFloat = HandLandmarkName.fingertipNames.contains(name) ? 6 : 4
            let pointRect = CGRect(
                x: resolvedPoint.x - radius,
                y: resolvedPoint.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.setFillColor(color.cgColor)
            context.fillEllipse(in: pointRect)
            context.setStrokeColor(NSColor.white.withAlphaComponent(0.7).cgColor)
            context.setLineWidth(1)
            context.strokeEllipse(in: pointRect)
        }
    }

    private func convert(point: CGPoint, in imageRect: CGRect) -> CGPoint {
        let x = mirrorHorizontally ? (1 - point.x) : point.x
        return CGPoint(
            x: imageRect.minX + (x * imageRect.width),
            y: imageRect.minY + ((1 - point.y) * imageRect.height)
        )
    }

    private func resolvedImageRect(in container: CGRect) -> CGRect {
        guard let frameImage else {
            return container
        }

        let imageSize = CGSize(width: frameImage.width, height: frameImage.height)
        return aspectFitRect(for: imageSize, in: container)
    }

    private func aspectFitRect(for imageSize: CGSize, in container: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return container
        }

        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: container.midX - (width / 2),
            y: container.midY - (height / 2),
            width: width,
            height: height
        )
    }
}