import CoreImage
import UIKit

/// A Flutter-style 4x5 color matrix (row-major, 20 values; the 5th column is an
/// offset in the 0–255 range, as in `ColorFilter.matrix`).
typealias ColorMatrix = [Double]

enum ColorMatrices {
    static let identity: ColorMatrix = [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
    ]
}

/// Assistive (daltonization-style) filters applied to photos.
enum AssistFilter: String, CaseIterable, Identifiable {
    case deuteranomaly = "Deuteranomaly"
    case protanopia = "Protanopia"
    case tritanopia = "Tritanopia"

    var id: String { rawValue }
    var title: String { rawValue }

    var matrix: ColorMatrix {
        switch self {
        case .deuteranomaly:
            [0.885, 0.115, 0, 0, 0,
             0, 1, 0, 0, 0,
             -0.490, 0.190, 1.300, 0, 0,
             0, 0, 0, 1, 0]
        case .protanopia:
            [1, 0, 0, 0, 0,
             -0.255, 1.255, 0, 0, 0,
             0.303, -0.545, 1.242, 0, 0,
             0, 0, 0, 1, 0]
        case .tritanopia:
            [1.050, -0.383, 0.333, 0, 0,
             0, 1.235, -0.235, 0, 0,
             0, 0, 1, 0, 0,
             0, 0, 0, 1, 0]
        }
    }

    static func byTitle(_ title: String) -> AssistFilter? {
        allCases.first { $0.title == title }
    }
}

/// Color-vision simulation filters used on the live camera.
enum SimulationFilter: String, CaseIterable, Identifiable {
    case deuteranomaly = "Deuteranomaly"
    case protanopia = "Protanopia"
    case tritanopia = "Tritanopia"

    var id: String { rawValue }
    var title: String { rawValue }

    var matrix: ColorMatrix {
        switch self {
        case .deuteranomaly:
            [0.80, 0.20, 0, 0, 0,
             0.258, 0.742, 0, 0, 0,
             0, 0.142, 0.858, 0, 0,
             0, 0, 0, 1, 0]
        case .protanopia:
            [0.567, 0.433, 0, 0, 0,
             0.558, 0.442, 0, 0, 0,
             0, 0.242, 0.758, 0, 0,
             0, 0, 0, 1, 0]
        case .tritanopia:
            [0.95, 0.05, 0, 0, 0,
             0, 0.433, 0.567, 0, 0,
             0, 0.475, 0.525, 0, 0,
             0, 0, 0, 1, 0]
        }
    }

    static func byTitle(_ title: String) -> SimulationFilter? {
        allCases.first { $0.title == title }
    }
}

/// Applies a Flutter-style color matrix with Core Image.
///
/// The context has color management disabled so the matrix operates on the
/// encoded sRGB channel values directly — the same space Flutter's
/// `ColorFilter.matrix` works in — and results are clamped to 0…1.
final class ColorMatrixRenderer: @unchecked Sendable {
    static let shared = ColorMatrixRenderer()

    let context = CIContext(options: [
        .workingColorSpace: NSNull(),
        .outputColorSpace: NSNull(),
        .cacheIntermediates: false,
    ])

    func apply(_ matrix: ColorMatrix, to image: CIImage) -> CIImage {
        guard matrix != ColorMatrices.identity, matrix.count == 20 else { return image }
        func vector(_ row: Int) -> CIVector {
            let o = row * 5
            return CIVector(x: matrix[o], y: matrix[o + 1], z: matrix[o + 2], w: matrix[o + 3])
        }
        let filtered = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": vector(0),
            "inputGVector": vector(1),
            "inputBVector": vector(2),
            "inputAVector": vector(3),
            "inputBiasVector": CIVector(
                x: matrix[4] / 255, y: matrix[9] / 255, z: matrix[14] / 255, w: matrix[19] / 255
            ),
        ])
        return filtered.applyingFilter("CIColorClamp")
    }

    func cgImage(_ matrix: ColorMatrix, from cgImage: CGImage) -> CGImage? {
        let input = CIImage(cgImage: cgImage, options: [.colorSpace: NSNull()])
        let output = apply(matrix, to: input)
        return context.createCGImage(output, from: input.extent, format: .RGBA8, colorSpace: cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB))
    }

    func uiImage(_ matrix: ColorMatrix, from image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        if matrix == ColorMatrices.identity { return image }
        guard let out = cgImage(matrix, from: cg) else { return nil }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
}

extension UIImage {
    /// Redraws the image upright (orientation .up) and limits its width, like
    /// image_picker's `maxWidth`.
    func normalized(maxWidth: CGFloat) -> UIImage {
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let factor = pixelWidth > maxWidth ? maxWidth / pixelWidth : 1
        let target = CGSize(width: (pixelWidth * factor).rounded(), height: (pixelHeight * factor).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// Square, center-cropped thumbnail used for the filter tiles.
    func squareThumbnail(side: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let target = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            let aspect = max(side / size.width, side / size.height)
            let drawSize = CGSize(width: size.width * aspect, height: size.height * aspect)
            draw(in: CGRect(
                x: (side - drawSize.width) / 2,
                y: (side - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
        }
    }
}
