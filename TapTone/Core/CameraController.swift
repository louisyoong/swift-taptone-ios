import AVFoundation
import CoreImage
import SwiftUI
import UIKit

/// AVFoundation replacement for the Flutter `camera` plugin.
///
/// - `.detect`: medium (640x480) preset, shows a native preview layer and
///   samples the centre of BGRA frames every 100 ms to find the color name.
///   Exposure and focus are metered on the centre target, and readings are
///   smoothed over time.
/// - `.simulate`: high (1280x720) preset, every frame goes through the
///   selected color matrix and is published as a `CGImage`.
final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum Mode { case detect, simulate }
    enum CameraState: Equatable { case starting, running, unavailable }

    @Published private(set) var state: CameraState = .starting
    @Published private(set) var detected = DetectedColor.from(.white)
    @Published private(set) var frame: CGImage?

    let session = AVCaptureSession()
    let mode: Mode

    private let sessionQueue = DispatchQueue(label: "taptone.camera.session")
    private let videoQueue = DispatchQueue(label: "taptone.camera.frames")
    private var configured = false

    // Detect mode throttling.
    private var lastSample = Date(timeIntervalSince1970: 0)
    private var processingFrame = false
    /// Smoothed linear-light reading (frame queue only).
    private var smoothed: (r: Double, g: Double, b: Double)?
    private var currentName: String?

    // Simulate mode: matrix is read on the frame queue.
    private let matrixLock = NSLock()
    private var _matrix: ColorMatrix = ColorMatrices.identity
    var matrix: ColorMatrix {
        get { matrixLock.lock(); defer { matrixLock.unlock() }; return _matrix }
        set { matrixLock.lock(); _matrix = newValue; matrixLock.unlock() }
    }

    init(mode: Mode) {
        self.mode = mode
        super.init()
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted { self.startSession() } else { self.publish(.unavailable) }
            }
        default:
            publish(.unavailable)
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func publish(_ newState: CameraState) {
        DispatchQueue.main.async { self.state = newState }
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                guard self.configure() else {
                    self.publish(.unavailable)
                    return
                }
                self.configured = true
            }
            if !self.session.isRunning { self.session.startRunning() }
            self.publish(self.session.isRunning ? .running : .unavailable)
        }
    }

    private func configure() -> Bool {
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
        guard let device, let input = try? AVCaptureDeviceInput(device: device) else { return false }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        let preset: AVCaptureSession.Preset = mode == .detect ? .vga640x480 : .hd1280x720
        session.sessionPreset = session.canSetSessionPreset(preset) ? preset : .high

        guard session.canAddInput(input) else { return false }
        session.addInput(input)
        if mode == .detect { meterOnCenter(device) }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else { return false }
        session.addOutput(output)

        if mode == .simulate, let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90 // portrait frames
        }
        return true
    }

    /// Points auto exposure / focus at the centre target. By default the
    /// camera meters the whole scene, so a mid-tone target in front of a
    /// bright window would come out too dark (and vice versa).
    private func meterOnCenter(_ device: AVCaptureDevice) {
        guard (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        let center = CGPoint(x: 0.5, y: 0.5)
        if device.isFocusPointOfInterestSupported { device.focusPointOfInterest = center }
        if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
        if device.isExposurePointOfInterestSupported { device.exposurePointOfInterest = center }
        if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { device.whiteBalanceMode = .continuousAutoWhiteBalance }
        if device.isSmoothAutoFocusSupported { device.isSmoothAutoFocusEnabled = true }
    }

    // MARK: - Frames

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        switch mode {
        case .detect: processDetectFrame(pixelBuffer)
        case .simulate: processSimulationFrame(pixelBuffer)
        }
    }

    private func processDetectFrame(_ pixelBuffer: CVPixelBuffer) {
        let now = Date()
        if processingFrame || now.timeIntervalSince(lastSample) < 0.1 { return }
        processingFrame = true
        lastSample = now
        defer { processingFrame = false }
        guard let sample = Self.sampleCenterColor(pixelBuffer) else { return }

        // Exponential smoothing in linear light; snap straight to the new
        // reading when the camera moves onto a clearly different color.
        if let previous = smoothed {
            let jump = DetectedColor.ciede2000(
                DetectedColor.Lab(Self.rgb(fromLinear: previous)),
                DetectedColor.Lab(Self.rgb(fromLinear: sample))
            )
            let alpha = jump > 12 ? 1.0 : 0.35
            smoothed = (
                previous.r + (sample.r - previous.r) * alpha,
                previous.g + (sample.g - previous.g) * alpha,
                previous.b + (sample.b - previous.b) * alpha
            )
        } else {
            smoothed = sample
        }
        guard let smoothed else { return }
        let detected = DetectedColor.from(Self.rgb(fromLinear: smoothed), previousName: currentName)
        currentName = detected.name
        DispatchQueue.main.async {
            if self.detected != detected { self.detected = detected }
        }
    }

    private static func rgb(fromLinear c: (r: Double, g: Double, b: Double)) -> RGB {
        func channel(_ v: Double) -> Int { Int((DetectedColor.linearToSrgb(v) * 255).rounded()) }
        return RGB(channel(c.r), channel(c.g), channel(c.b))
    }

    /// sRGB byte -> linear light lookup table.
    private static let linearLUT: [Double] = (0...255).map { DetectedColor.srgbToLinear(Double($0) / 255) }

    /// Reads every pixel in a disc (radius 10 px, about the size of the
    /// on-screen target dot) at the frame centre, drops the brightest and
    /// darkest 20% (specular glare, shadows, texture) and averages the rest in
    /// linear light. Returns linear RGB in 0...1.
    static func sampleCenterColor(_ pixelBuffer: CVPixelBuffer) -> (r: Double, g: Double, b: Double)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let length = bytesPerRow * height
        let bytes = base.assumingMemoryBound(to: UInt8.self)

        let radius = 10
        let centerX = width / 2, centerY = height / 2
        var pixels: [(luma: Double, r: Double, g: Double, b: Double)] = []
        pixels.reserveCapacity((2 * radius + 1) * (2 * radius + 1))
        for offsetY in -radius...radius {
            for offsetX in -radius...radius where offsetX * offsetX + offsetY * offsetY <= radius * radius {
                let x = min(max(centerX + offsetX, 0), width - 1)
                let y = min(max(centerY + offsetY, 0), height - 1)
                let index = y * bytesPerRow + x * 4
                guard index + 2 < length else { continue }
                let b = linearLUT[Int(bytes[index])]
                let g = linearLUT[Int(bytes[index + 1])]
                let r = linearLUT[Int(bytes[index + 2])]
                pixels.append((0.2126 * r + 0.7152 * g + 0.0722 * b, r, g, b))
            }
        }
        guard !pixels.isEmpty else { return nil }
        pixels.sort { $0.luma < $1.luma }
        let trim = pixels.count / 5
        let kept = pixels[trim..<(pixels.count - trim)]
        var red = 0.0, green = 0.0, blue = 0.0
        for p in kept {
            red += p.r
            green += p.g
            blue += p.b
        }
        let n = Double(kept.count)
        return (red / n, green / n, blue / n)
    }

    private func processSimulationFrame(_ pixelBuffer: CVPixelBuffer) {
        let renderer = ColorMatrixRenderer.shared
        let input = CIImage(cvPixelBuffer: pixelBuffer, options: [.colorSpace: NSNull()])
        let output = renderer.apply(matrix, to: input)
        guard let cgImage = renderer.context.createCGImage(
            output,
            from: input.extent,
            format: .BGRA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        ) else { return }
        DispatchQueue.main.async { self.frame = cgImage }
    }
}

/// Native camera preview (used by the Detect tab, which shows unfiltered video).
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

/// Shared "Starting camera..." / "Camera unavailable" message.
struct CameraMessageView: View {
    let systemImage: String
    let text: String
    var isLoading = false
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(palette.primaryContainer.opacity(palette.isDark ? 0.5 : 0.7))
                    .frame(width: 120, height: 120)
                Circle()
                    .strokeBorder(palette.primary.opacity(0.18), lineWidth: 1)
                    .frame(width: 150, height: 150)
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(palette.primary)
                    .symbolEffect(.pulse, isActive: isLoading)
            }
            Text(text)
                .font(AppFont.bodyMedium.weight(.medium))
                .lineSpacing(AppFont.bodyLineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.onSurfaceVariant)
                .frame(maxWidth: 300)
            if isLoading {
                ProgressView().tint(palette.primary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Pill label shown over previews ("Original", filter name, "Normal").
struct PreviewLabel: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
            }
            Text(text)
                .font(.system(size: 14, weight: .heavy))
                .contentTransition(.opacity)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.35)))
        .glassEffect(.clear, in: Capsule())
        .environment(\.colorScheme, .dark)
    }
}
