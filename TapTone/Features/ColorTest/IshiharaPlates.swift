import SwiftUI
import UIKit

/// Color vision screening plates, inspired by Ishihara plates. Every plate
/// is generated on-device as a mosaic of colored dots: a digit, animal
/// emoji or shape symbol is rasterized to a mask, then dots are scattered inside a circle and
/// colored from a "figure" or "background" palette depending on whether they
/// fall inside the glyph's shape.

let plateSize: CGFloat = 300

struct PlateDot: Sendable {
    let center: CGPoint
    let radius: CGFloat
    let color: Color
}

struct PalettePair: Sendable {
    let figure: [UInt32]
    let background: [UInt32]
}

struct PlateSpec {
    let digits: String
    let answer: Int
    let palette: PalettePair
}

struct KidAnimal {
    let id: String
    let emoji: String
}

struct KidPlateSpec {
    let animalIndex: Int
    let palette: PalettePair
}

struct ShapeItem {
    let id: String
    let symbol: String
}

struct ShapePlateSpec {
    let shapeIndex: Int
    let palette: PalettePair
}

/// What gets rasterized into a plate's figure mask.
enum PlateGlyph: Sendable {
    /// A string (digits or emoji) drawn in the system font.
    case text(String, fontSize: CGFloat)
    /// A filled SF Symbol drawn to fit a square of `side` points.
    case symbol(String, side: CGFloat)
}

enum Plates {
    // Orange figure on olive-green background: a classic red-green confusion
    // pair, matched in lightness so only hue separates figure from ground.
    static let redOnGreen = PalettePair(
        figure: [0xFFE06B3E, 0xFFD9622F, 0xFFEB8156, 0xFFC85A2C],
        background: [0xFF8FA84C, 0xFF7C9A3E, 0xFFA3B860, 0xFF6F8C35]
    )

    static let greenOnRed = PalettePair(
        figure: [0xFF8FA84C, 0xFF7C9A3E, 0xFFA3B860, 0xFF6F8C35],
        background: [0xFFE06B3E, 0xFFD9622F, 0xFFEB8156, 0xFFC85A2C]
    )

    // High lightness contrast so everyone can read it -- the warm-up plate.
    static let control = PalettePair(
        figure: [0xFF6D4C2E, 0xFF5B3E24, 0xFF7E5735],
        background: [0xFFE7C89A, 0xFFDFBB84, 0xFFEFD3A8]
    )

    static let adult: [PlateSpec] = [
        PlateSpec(digits: "12", answer: 12, palette: control),
        PlateSpec(digits: "8", answer: 8, palette: redOnGreen),
        PlateSpec(digits: "29", answer: 29, palette: greenOnRed),
        PlateSpec(digits: "5", answer: 5, palette: redOnGreen),
        PlateSpec(digits: "3", answer: 3, palette: greenOnRed),
        PlateSpec(digits: "15", answer: 15, palette: redOnGreen),
        PlateSpec(digits: "74", answer: 74, palette: greenOnRed),
        PlateSpec(digits: "6", answer: 6, palette: redOnGreen),
        PlateSpec(digits: "45", answer: 45, palette: greenOnRed),
        PlateSpec(digits: "97", answer: 97, palette: redOnGreen),
    ]

    // Order matches the option icons kids will tap.
    static let animals: [KidAnimal] = [
        KidAnimal(id: "butterfly", emoji: "🦋"),
        KidAnimal(id: "dolphin", emoji: "🐬"),
        KidAnimal(id: "cow", emoji: "🐄"),
        KidAnimal(id: "giraffe", emoji: "🦒"),
        KidAnimal(id: "duck", emoji: "🦆"),
        KidAnimal(id: "snail", emoji: "🐌"),
        KidAnimal(id: "elephant", emoji: "🐘"),
        KidAnimal(id: "fish", emoji: "🐟"),
        KidAnimal(id: "kangaroo", emoji: "🦘"),
        KidAnimal(id: "rabbit", emoji: "🐰"),
    ]

    static let kid: [KidPlateSpec] = [
        KidPlateSpec(animalIndex: 7, palette: control),
        KidPlateSpec(animalIndex: 0, palette: redOnGreen),
        KidPlateSpec(animalIndex: 1, palette: greenOnRed),
        KidPlateSpec(animalIndex: 2, palette: redOnGreen),
        KidPlateSpec(animalIndex: 3, palette: greenOnRed),
        KidPlateSpec(animalIndex: 4, palette: redOnGreen),
        KidPlateSpec(animalIndex: 5, palette: greenOnRed),
        KidPlateSpec(animalIndex: 6, palette: redOnGreen),
        KidPlateSpec(animalIndex: 8, palette: greenOnRed),
        KidPlateSpec(animalIndex: 9, palette: redOnGreen),
    ]

    // Shapes the geometry test can ask about. Picked so each one has a
    // distinct silhouette even when drawn with coarse dots.
    static let shapes: [ShapeItem] = [
        ShapeItem(id: "circle", symbol: "circle.fill"),
        ShapeItem(id: "square", symbol: "square.fill"),
        ShapeItem(id: "triangle", symbol: "triangle.fill"),
        ShapeItem(id: "star", symbol: "star.fill"),
        ShapeItem(id: "heart", symbol: "heart.fill"),
        ShapeItem(id: "diamond", symbol: "diamond.fill"),
        ShapeItem(id: "moon", symbol: "moon.fill"),
        ShapeItem(id: "cross", symbol: "cross.fill"),
        ShapeItem(id: "arrow", symbol: "arrowshape.right.fill"),
        ShapeItem(id: "hexagon", symbol: "hexagon.fill"),
    ]

    static let shape: [ShapePlateSpec] = [
        ShapePlateSpec(shapeIndex: 3, palette: control),
        ShapePlateSpec(shapeIndex: 0, palette: redOnGreen),
        ShapePlateSpec(shapeIndex: 2, palette: greenOnRed),
        ShapePlateSpec(shapeIndex: 4, palette: redOnGreen),
        ShapePlateSpec(shapeIndex: 1, palette: greenOnRed),
        ShapePlateSpec(shapeIndex: 6, palette: redOnGreen),
        ShapePlateSpec(shapeIndex: 5, palette: greenOnRed),
        ShapePlateSpec(shapeIndex: 8, palette: redOnGreen),
        ShapePlateSpec(shapeIndex: 7, palette: greenOnRed),
        ShapePlateSpec(shapeIndex: 9, palette: redOnGreen),
    ]

    static func adultDots(_ index: Int) async -> [PlateDot] {
        let spec = adult[index]
        let fontSize = spec.digits.count > 1 ? plateSize * 0.5 : plateSize * 0.62
        return await generateDots(glyph: .text(spec.digits, fontSize: fontSize), palette: spec.palette, seed: index * 7919 + 13)
    }

    static func kidDots(_ index: Int) async -> [PlateDot] {
        let spec = kid[index]
        let emoji = animals[spec.animalIndex].emoji
        return await generateDots(glyph: .text(emoji, fontSize: plateSize * 0.72), palette: spec.palette, seed: index * 6151 + 17)
    }

    static func shapeDots(_ index: Int) async -> [PlateDot] {
        let spec = shape[index]
        let symbol = shapes[spec.shapeIndex].symbol
        return await generateDots(glyph: .symbol(symbol, side: plateSize * 0.6), palette: spec.palette, seed: index * 4271 + 29)
    }

    static func kidOptions(_ index: Int) -> [Int] {
        choiceOptions(answer: kid[index].animalIndex, count: animals.count, seed: index * 97 + 3)
    }

    static func shapeOptions(_ index: Int) -> [Int] {
        choiceOptions(answer: shape[index].shapeIndex, count: shapes.count, seed: index * 131 + 7)
    }

    /// The right answer plus three seeded-random distractors, in seeded-random order.
    private static func choiceOptions(answer: Int, count: Int, seed: Int) -> [Int] {
        var random = DartRandom(seed: seed)
        var others = Array(0..<count)
        others.removeAll { $0 == answer }
        others.dartShuffle(using: &random)
        var options = [answer] + others.prefix(3)
        options.dartShuffle(using: &random)
        return options
    }

    // Mode/intro badges are tiny real plates, generated once per session.
    static let adultBadge = Task { await Plates.generateDots(glyph: .text("8", fontSize: plateSize * 0.62), palette: control, seed: 4242) }
    static let kidBadge = Task { await Plates.generateDots(glyph: .text("🐟", fontSize: plateSize * 0.72), palette: control, seed: 8484) }
    static let shapeBadge = Task { await Plates.generateDots(glyph: .symbol("star.fill", side: plateSize * 0.6), palette: control, seed: 2121) }

    static func generateDots(glyph: PlateGlyph, palette: PalettePair, seed: Int) async -> [PlateDot] {
        await Task.detached(priority: .userInitiated) {
            Plates.makeDots(glyph: glyph, palette: palette, seed: seed)
        }.value
    }

    private static func renderMask(glyph: PlateGlyph) -> [UInt8] {
        let size = Int(plateSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { _ in
            switch glyph {
            case let .text(string, fontSize):
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .black),
                    .foregroundColor: UIColor.white,
                ]
                let text = NSAttributedString(string: string, attributes: attributes)
                let textSize = text.size()
                text.draw(at: CGPoint(x: (plateSize - textSize.width) / 2, y: (plateSize - textSize.height) / 2))
            case let .symbol(name, side):
                let config = UIImage.SymbolConfiguration(pointSize: side, weight: .black)
                guard let symbol = UIImage(systemName: name, withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                else { return }
                // Aspect-fit the symbol into a centered side x side box.
                let scale = side / max(symbol.size.width, symbol.size.height)
                let drawSize = CGSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
                symbol.draw(in: CGRect(
                    x: (plateSize - drawSize.width) / 2,
                    y: (plateSize - drawSize.height) / 2,
                    width: drawSize.width,
                    height: drawSize.height
                ))
            }
        }
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        guard let cgImage = image.cgImage,
              let context = CGContext(
                data: &pixels,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: size * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return pixels }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        return pixels
    }

    fileprivate static func makeDots(glyph: PlateGlyph, palette: PalettePair, seed: Int) -> [PlateDot] {
        let size = plateSize
        let sizeInt = Int(size)
        let mask = renderMask(glyph: glyph)

        func isInsideGlyph(_ x: Int, _ y: Int) -> Bool {
            if x < 0 || y < 0 || x >= sizeInt || y >= sizeInt { return false }
            return mask[(y * sizeInt + x) * 4 + 3] > 120
        }

        var random = DartRandom(seed: seed)
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius = size / 2 - 6
        let cellSize: CGFloat = 12

        var dots: [PlateDot] = []
        var grid: [Int: [CGPoint]] = [:]
        func key(_ x: Int, _ y: Int) -> Int { (x + 1000) * 10_000 + (y + 1000) }

        func overlapsExisting(_ point: CGPoint, _ dotRadius: CGFloat) -> Bool {
            let cellX = Int((point.x / cellSize).rounded(.down))
            let cellY = Int((point.y / cellSize).rounded(.down))
            for gx in (cellX - 1)...(cellX + 1) {
                for gy in (cellY - 1)...(cellY + 1) {
                    guard let neighbors = grid[key(gx, gy)] else { continue }
                    for existing in neighbors where hypot(existing.x - point.x, existing.y - point.y) < dotRadius + 4.2 {
                        return true
                    }
                }
            }
            return false
        }

        var attempts = 0
        while dots.count < 1300 && attempts < 18000 {
            attempts += 1
            let angle = random.nextDouble() * 2 * .pi
            let distance = radius * sqrt(random.nextDouble())
            let point = CGPoint(x: center.x + distance * cos(angle), y: center.y + distance * sin(angle))
            let dotRadius = 2.6 + random.nextDouble() * 3.4
            if hypot(point.x - center.x, point.y - center.y) + dotRadius > radius { continue }
            if overlapsExisting(point, dotRadius) { continue }

            let swatch = isInsideGlyph(Int(point.x.rounded()), Int(point.y.rounded())) ? palette.figure : palette.background
            let base = swatch[random.nextInt(swatch.count)]
            let jitter = (random.nextDouble() - 0.5) * 0.08
            let color = HSL(argb: base).withLightness(min(max(HSL(argb: base).lightness + jitter, 0.2), 0.85)).color

            dots.append(PlateDot(center: point, radius: dotRadius, color: color))
            let cellX = Int((point.x / cellSize).rounded(.down))
            let cellY = Int((point.y / cellSize).rounded(.down))
            grid[key(cellX, cellY), default: []].append(point)
        }
        return dots
    }
}

/// Port of Flutter's `HSLColor` round trip.
private struct HSL {
    var hue: Double
    var saturation: Double
    var lightness: Double

    init(argb: UInt32) {
        let r = Double((argb >> 16) & 0xFF) / 255
        let g = Double((argb >> 8) & 0xFF) / 255
        let b = Double(argb & 0xFF) / 255
        let maxC = max(r, g, b), minC = min(r, g, b)
        let delta = maxC - minC
        var h: Double = 0
        if maxC == 0 || delta == 0 {
            h = 0
        } else if maxC == r {
            h = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxC == g {
            h = 60 * ((b - r) / delta + 2)
        } else {
            h = 60 * ((r - g) / delta + 4)
        }
        h = h.isNaN ? 0 : h
        hue = h < 0 ? h + 360 : h
        lightness = (maxC + minC) / 2
        saturation = lightness == 1 ? 0 : min(max(delta / (1 - abs(2 * lightness - 1)), 0), 1)
    }

    func withLightness(_ l: Double) -> HSL {
        var copy = self
        copy.lightness = l
        return copy
    }

    var color: Color {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let secondary = chroma * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let match = lightness - chroma / 2
        var r = 0.0, g = 0.0, b = 0.0
        switch hue {
        case ..<60: (r, g, b) = (chroma, secondary, 0)
        case ..<120: (r, g, b) = (secondary, chroma, 0)
        case ..<180: (r, g, b) = (0, chroma, secondary)
        case ..<240: (r, g, b) = (0, secondary, chroma)
        case ..<300: (r, g, b) = (secondary, 0, chroma)
        default: (r, g, b) = (chroma, 0, secondary)
        }
        func channel(_ v: Double) -> Double { ((v + match) * 255).rounded() / 255 }
        return Color(.sRGB, red: channel(r), green: channel(g), blue: channel(b), opacity: 1)
    }
}

/// Draws a plate (in 300x300 plate space, scaled to fit).
struct IshiharaCanvas: View {
    let dots: [PlateDot]

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / plateSize
            context.scaleBy(x: scale, y: scale)
            for dot in dots {
                let rect = CGRect(x: dot.center.x - dot.radius, y: dot.center.y - dot.radius, width: dot.radius * 2, height: dot.radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(dot.color))
            }
        }
    }
}

enum TestBadgeKind {
    case adult, kid, shape

    fileprivate var dots: Task<[PlateDot], Never> {
        switch self {
        case .adult: Plates.adultBadge
        case .kid: Plates.kidBadge
        case .shape: Plates.shapeBadge
        }
    }
}

/// The small circular badge plate used on the mode cards and intro screens.
struct TestBadgePlate: View {
    let kind: TestBadgeKind
    var size: CGFloat = 56
    @State private var dots: [PlateDot]?
    @Environment(\.palette) private var palette

    var body: some View {
        Group {
            if let dots {
                IshiharaCanvas(dots: dots)
                    .background(Circle().fill(Color.black.opacity(0.18)).blur(radius: 6).offset(y: 4))
            } else {
                Circle().fill(palette.surfaceContainerHighest)
            }
        }
        .frame(width: size, height: size)
        .task {
            dots = await kind.dots.value
        }
    }
}

/// Full-size plate card with progress spinner while generating.
struct PlateCard: View {
    let dots: [PlateDot]?
    let size: CGFloat
    @Environment(\.palette) private var palette

    var body: some View {
        Group {
            if let dots {
                IshiharaCanvas(dots: dots)
                    .padding(6)
                    .background(Circle().fill(palette.surface))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 10)
            } else {
                ProgressView().tint(palette.primary)
            }
        }
        .frame(width: size, height: size)
    }
}
