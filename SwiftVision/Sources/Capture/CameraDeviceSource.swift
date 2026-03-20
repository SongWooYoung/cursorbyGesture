import AVFoundation
import Config
import Foundation
import Support

public enum CameraDeviceSourceError: Error, LocalizedError {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput

    public var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "No compatible camera input was found."
        case .cannotAddInput:
            return "Failed to attach the selected camera input."
        case .cannotAddOutput:
            return "Failed to attach the sample buffer output."
        }
    }
}

public final class CameraDeviceSource: NSObject, VideoSource {
    public weak var delegate: (any VideoSourceDelegate)?

    private let config: AppConfig
    private let session = AVCaptureSession()
    private let outputQueue = DispatchQueue(label: "visualagent.capture.output")

    public init(config: AppConfig) {
        self.config = config
    }

    public func start() throws {
        session.beginConfiguration()
        session.sessionPreset = .high

        var configuredInput: AVCaptureDeviceInput?
        var configuredOutput: AVCaptureVideoDataOutput?

        do {
            logAvailableDevices()

            guard let device = resolveDevice() else {
                throw CameraDeviceSourceError.cameraUnavailable
            }

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CameraDeviceSourceError.cannotAddInput
            }
            session.addInput(input)
            configuredInput = input

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            ]
            output.setSampleBufferDelegate(self, queue: outputQueue)

            guard session.canAddOutput(output) else {
                throw CameraDeviceSourceError.cannotAddOutput
            }
            session.addOutput(output)
            configuredOutput = output

            session.commitConfiguration()

            Logger.info("Starting camera source: \(device.localizedName)")
            session.startRunning()
        } catch {
            if let configuredOutput {
                session.removeOutput(configuredOutput)
            }
            if let configuredInput {
                session.removeInput(configuredInput)
            }
            session.commitConfiguration()
            throw error
        }
    }

    public func stop() {
        session.stopRunning()
    }

    private func resolveDevice() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .continuityCamera,
                .external,
                .builtInWideAngleCamera,
            ],
            mediaType: .video,
            position: .unspecified
        )

        if let cameraUniqueID = config.cameraUniqueID {
            return discovery.devices.first(where: { $0.uniqueID == cameraUniqueID })
        }

        return discovery.devices.first
    }

    private func logAvailableDevices() {
        let allVideoDevices = AVCaptureDevice.devices(for: .video)
        if allVideoDevices.isEmpty {
            Logger.warning("AVFoundation reports no video capture devices.")
            return
        }

        Logger.info("Detected video devices: \(allVideoDevices.count)")
        allVideoDevices.forEach { device in
            Logger.info(
                """
                Camera device:
                - name: \(device.localizedName)
                - type: \(device.deviceType.rawValue)
                - id: \(device.uniqueID)
                - connected: \(device.isConnected)
                - suspended: \(device.isSuspended)
                """
            )
        }

        let filteredDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .continuityCamera,
                .external,
                .builtInWideAngleCamera,
            ],
            mediaType: .video,
            position: .unspecified
        )

        Logger.info("Compatible filtered devices: \(filteredDiscovery.devices.count)")
        filteredDiscovery.devices.forEach { device in
            Logger.info("Filtered match: \(device.localizedName) [\(device.deviceType.rawValue)]")
        }
    }
}

extension CameraDeviceSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.videoSource(self, didOutput: VideoFrame(sampleBuffer: sampleBuffer))
    }
}
