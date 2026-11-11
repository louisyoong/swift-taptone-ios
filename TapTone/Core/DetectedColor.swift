import SwiftUI

struct RGB: Equatable {
    var r: Int
    var g: Int
    var b: Int

    var color: Color {
        Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }

    init(_ r: Int, _ g: Int, _ b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(hex: UInt32) {
        self.init(Int((hex >> 16) & 0xFF), Int((hex >> 8) & 0xFF), Int(hex & 0xFF))
    }

    static let white = RGB(255, 255, 255)
}

struct DetectedColor: Equatable {
    let name: String
    let hex: String
    let rgb: RGB

    /// Names `rgb` with the perceptually closest entry (CIEDE2000).
    ///
    /// - `previousName`: the name currently on screen. It is kept unless
    ///   another entry is clearly closer, so the label does not flicker
    ///   between two near-identical names on camera noise.
    static func from(_ rgb: RGB, previousName: String? = nil) -> DetectedColor {
        let lab = Lab(rgb)
        var best = namedColors[0]
        var bestDistance = Double.infinity
        var previousDistance: Double?
        for candidate in namedColors {
            var d = ciede2000(lab, candidate.lab)
            // Favor the plain everyday names (Red, Green, Blue...) slightly:
            // they're what most users want, and they're steadier on camera.
            if candidate.isBasic { d *= basicNameBias }
            if candidate.name == previousName { previousDistance = min(previousDistance ?? .infinity, d) }
            if d < bestDistance {
                best = candidate
                bestDistance = d
            }
        }
        let name: String
        if let previousName, let previousDistance, previousDistance - bestDistance < hysteresis {
            name = previousName
        } else {
            name = best.name
        }
        let hex = String(format: "#%02X%02X%02X", rgb.r, rgb.g, rgb.b)
        return DetectedColor(name: name, hex: hex, rgb: rgb)
    }

    private static let basicNameBias = 0.85
    /// How much closer (in ΔE00) a new name must be before it replaces the current one.
    private static let hysteresis = 1.5

    // MARK: CIELAB / CIEDE2000

    struct Lab: Equatable {
        let l: Double
        let a: Double
        let b: Double

        /// sRGB (D65) -> CIELAB.
        init(_ rgb: RGB) {
            let r = srgbToLinear(Double(rgb.r) / 255)
            let g = srgbToLinear(Double(rgb.g) / 255)
            let b = srgbToLinear(Double(rgb.b) / 255)
            let x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
            let y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
            let z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
            func f(_ t: Double) -> Double { t > 216.0 / 24389 ? cbrt(t) : (24389.0 / 27 * t + 16) / 116 }
            let fx = f(x), fy = f(y), fz = f(z)
            l = 116 * fy - 16
            a = 500 * (fx - fy)
            self.b = 200 * (fy - fz)
        }
    }

    static func srgbToLinear(_ c: Double) -> Double {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    static func linearToSrgb(_ c: Double) -> Double {
        let v = min(max(c, 0), 1)
        return v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055
    }

    /// CIEDE2000 color difference (Sharma et al. 2005 reference formulation).
    static func ciede2000(_ x: Lab, _ y: Lab) -> Double {
        let rad = Double.pi / 180
        let c1 = hypot(x.a, x.b), c2 = hypot(y.a, y.b)
        let cBar = (c1 + c2) / 2
        let cBar7 = pow(cBar, 7)
        let g = 0.5 * (1 - sqrt(cBar7 / (cBar7 + pow(25, 7))))
        let a1 = (1 + g) * x.a, a2 = (1 + g) * y.a
        let c1p = hypot(a1, x.b), c2p = hypot(a2, y.b)
        func hue(_ b: Double, _ a: Double) -> Double {
            if a == 0 && b == 0 { return 0 }
            let h = atan2(b, a) / rad
            return h < 0 ? h + 360 : h
        }
        let h1p = hue(x.b, a1), h2p = hue(y.b, a2)

        let dLp = y.l - x.l
        let dCp = c2p - c1p
        var dhp = 0.0
        if c1p * c2p != 0 {
            dhp = h2p - h1p
            if dhp > 180 { dhp -= 360 } else if dhp < -180 { dhp += 360 }
        }
        let dHp = 2 * sqrt(c1p * c2p) * sin(dhp / 2 * rad)

        let lBarP = (x.l + y.l) / 2
        let cBarP = (c1p + c2p) / 2
        var hBarP = h1p + h2p
        if c1p * c2p != 0 {
            if abs(h1p - h2p) <= 180 { hBarP /= 2 } else { hBarP = h1p + h2p < 360 ? (hBarP + 360) / 2 : (hBarP - 360) / 2 }
        }
        let t = 1 - 0.17 * cos((hBarP - 30) * rad) + 0.24 * cos(2 * hBarP * rad)
            + 0.32 * cos((3 * hBarP + 6) * rad) - 0.20 * cos((4 * hBarP - 63) * rad)
        let dTheta = 30 * exp(-pow((hBarP - 275) / 25, 2))
        let cBarP7 = pow(cBarP, 7)
        let rc = 2 * sqrt(cBarP7 / (cBarP7 + pow(25, 7)))
        let lTerm = pow(lBarP - 50, 2)
        let sl = 1 + 0.015 * lTerm / sqrt(20 + lTerm)
        let sc = 1 + 0.045 * cBarP
        let sh = 1 + 0.015 * cBarP * t
        let rt = -sin(2 * dTheta * rad) * rc

        let l = dLp / sl, c = dCp / sc, h = dHp / sh
        return sqrt(l * l + c * c + h * h + rt * c * h)
    }

    private struct NamedColor {
        let name: String
        let rgb: RGB
        let lab: Lab
        let isBasic: Bool
        init(_ name: String, _ hex: UInt32) {
            self.name = name
            rgb = RGB(hex: hex)
            lab = Lab(rgb)
            isBasic = DetectedColor.basicNames.contains(name)
        }
    }

    /// Everyday names (the first block of the list).
    fileprivate static let basicNames: Set<String> = [
        "Black", "Charcoal", "Gray", "Silver", "White", "Maroon", "Red", "Coral",
        "Orange", "Gold", "Yellow", "Olive", "Lime", "Green", "Forest Green", "Mint",
        "Teal", "Cyan", "Sky Blue", "Blue", "Navy", "Indigo", "Purple", "Lavender",
        "Magenta", "Pink", "Brown", "Beige",
    ]

    private static let namedColors: [NamedColor] = [
        NamedColor("Black", 0x111111),
        NamedColor("Charcoal", 0x37474F),
        NamedColor("Gray", 0x808080),
        NamedColor("Silver", 0xBDBDBD),
        NamedColor("White", 0xF5F5F5),
        NamedColor("Maroon", 0x800000),
        NamedColor("Red", 0xE53935),
        NamedColor("Coral", 0xFF6F61),
        NamedColor("Orange", 0xFB8C00),
        NamedColor("Gold", 0xFFC107),
        NamedColor("Yellow", 0xFDD835),
        NamedColor("Olive", 0x808000),
        NamedColor("Lime", 0x8BC34A),
        NamedColor("Green", 0x43A047),
        NamedColor("Forest Green", 0x1B5E20),
        NamedColor("Mint", 0x66CDAA),
        NamedColor("Teal", 0x00897B),
        NamedColor("Cyan", 0x00BCD4),
        NamedColor("Sky Blue", 0x42A5F5),
        NamedColor("Blue", 0x1E88E5),
        NamedColor("Navy", 0x000080),
        NamedColor("Indigo", 0x3F51B5),
        NamedColor("Purple", 0x8E24AA),
        NamedColor("Lavender", 0xB39DDB),
        NamedColor("Magenta", 0xE91E63),
        NamedColor("Pink", 0xF48FB1),
        NamedColor("Brown", 0x795548),
        NamedColor("Beige", 0xD7CCC8),
        NamedColor("Alice Blue", 0xF0F8FF),
        NamedColor("Antique White", 0xFAEBD7),
        NamedColor("Aquamarine", 0x7FFFD4),
        NamedColor("Azure", 0xF0FFFF),
        NamedColor("Bisque", 0xFFE4C4),
        NamedColor("Blanched Almond", 0xFFEBCD),
        NamedColor("Blue Violet", 0x8A2BE2),
        NamedColor("Burlywood", 0xDEB887),
        NamedColor("Cadet Blue", 0x5F9EA0),
        NamedColor("Chartreuse", 0x7FFF00),
        NamedColor("Chocolate", 0xD2691E),
        NamedColor("Cornflower Blue", 0x6495ED),
        NamedColor("Cornsilk", 0xFFF8DC),
        NamedColor("Crimson", 0xDC143C),
        NamedColor("Dark Blue", 0x00008B),
        NamedColor("Dark Cyan", 0x008B8B),
        NamedColor("Dark Goldenrod", 0xB8860B),
        NamedColor("Dark Gray", 0xA9A9A9),
        NamedColor("Dark Green", 0x006400),
        NamedColor("Dark Khaki", 0xBDB76B),
        NamedColor("Dark Magenta", 0x8B008B),
        NamedColor("Dark Olive Green", 0x556B2F),
        NamedColor("Dark Orange", 0xFF8C00),
        NamedColor("Dark Orchid", 0x9932CC),
        NamedColor("Dark Red", 0x8B0000),
        NamedColor("Dark Salmon", 0xE9967A),
        NamedColor("Dark Sea Green", 0x8FBC8F),
        NamedColor("Dark Slate Blue", 0x483D8B),
        NamedColor("Dark Slate Gray", 0x2F4F4F),
        NamedColor("Dark Turquoise", 0x00CED1),
        NamedColor("Dark Violet", 0x9400D3),
        NamedColor("Deep Pink", 0xFF1493),
        NamedColor("Deep Sky Blue", 0x00BFFF),
        NamedColor("Dim Gray", 0x696969),
        NamedColor("Dodger Blue", 0x1E90FF),
        NamedColor("Firebrick", 0xB22222),
        NamedColor("Floral White", 0xFFFAF0),
        NamedColor("Fuchsia", 0xFF00FF),
        NamedColor("Gainsboro", 0xDCDCDC),
        NamedColor("Ghost White", 0xF8F8FF),
        NamedColor("Goldenrod", 0xDAA520),
        NamedColor("Green Yellow", 0xADFF2F),
        NamedColor("Honeydew", 0xF0FFF0),
        NamedColor("Hot Pink", 0xFF69B4),
        NamedColor("Indian Red", 0xCD5C5C),
        NamedColor("Ivory", 0xFFFFF0),
        NamedColor("Khaki", 0xF0E68C),
        NamedColor("Lavender Blush", 0xFFF0F5),
        NamedColor("Lawn Green", 0x7CFC00),
        NamedColor("Lemon Chiffon", 0xFFFACD),
        NamedColor("Light Blue", 0xADD8E6),
        NamedColor("Light Coral", 0xF08080),
        NamedColor("Light Cyan", 0xE0FFFF),
        NamedColor("Light Goldenrod Yellow", 0xFAFAD2),
        NamedColor("Light Gray", 0xD3D3D3),
        NamedColor("Light Green", 0x90EE90),
        NamedColor("Light Pink", 0xFFB6C1),
        NamedColor("Light Salmon", 0xFFA07A),
        NamedColor("Light Sea Green", 0x20B2AA),
        NamedColor("Light Sky Blue", 0x87CEFA),
        NamedColor("Light Slate Gray", 0x778899),
        NamedColor("Light Steel Blue", 0xB0C4DE),
        NamedColor("Light Yellow", 0xFFFFE0),
        NamedColor("Lime Green", 0x32CD32),
        NamedColor("Linen", 0xFAF0E6),
        NamedColor("Medium Aquamarine", 0x66CDAA),
        NamedColor("Medium Blue", 0x0000CD),
        NamedColor("Medium Orchid", 0xBA55D3),
        NamedColor("Medium Purple", 0x9370DB),
        NamedColor("Medium Sea Green", 0x3CB371),
        NamedColor("Medium Slate Blue", 0x7B68EE),
        NamedColor("Medium Spring Green", 0x00FA9A),
        NamedColor("Medium Turquoise", 0x48D1CC),
        NamedColor("Medium Violet Red", 0xC71585),
        NamedColor("Midnight Blue", 0x191970),
        NamedColor("Mint Cream", 0xF5FFFA),
        NamedColor("Misty Rose", 0xFFE4E1),
        NamedColor("Moccasin", 0xFFE4B5),
        NamedColor("Navajo White", 0xFFDEAD),
        NamedColor("Old Lace", 0xFDF5E6),
        NamedColor("Olive Drab", 0x6B8E23),
        NamedColor("Orange Red", 0xFF4500),
        NamedColor("Orchid", 0xDA70D6),
        NamedColor("Pale Goldenrod", 0xEEE8AA),
        NamedColor("Pale Green", 0x98FB98),
        NamedColor("Pale Turquoise", 0xAFEEEE),
        NamedColor("Pale Violet Red", 0xDB7093),
        NamedColor("Papaya Whip", 0xFFEFD5),
        NamedColor("Peach Puff", 0xFFDAB9),
        NamedColor("Peru", 0xCD853F),
        NamedColor("Plum", 0xDDA0DD),
        NamedColor("Powder Blue", 0xB0E0E6),
        NamedColor("Rebecca Purple", 0x663399),
        NamedColor("Rosy Brown", 0xBC8F8F),
        NamedColor("Royal Blue", 0x4169E1),
        NamedColor("Saddle Brown", 0x8B4513),
        NamedColor("Salmon", 0xFA8072),
        NamedColor("Sandy Brown", 0xF4A460),
        NamedColor("Sea Green", 0x2E8B57),
        NamedColor("Seashell", 0xFFF5EE),
        NamedColor("Sienna", 0xA0522D),
        NamedColor("Slate Blue", 0x6A5ACD),
        NamedColor("Slate Gray", 0x708090),
        NamedColor("Snow", 0xFFFAFA),
        NamedColor("Spring Green", 0x00FF7F),
        NamedColor("Steel Blue", 0x4682B4),
        NamedColor("Tan", 0xD2B48C),
        NamedColor("Thistle", 0xD8BFD8),
        NamedColor("Tomato", 0xFF6347),
        NamedColor("Turquoise", 0x40E0D0),
        NamedColor("Violet", 0xEE82EE),
        NamedColor("Wheat", 0xF5DEB3),
        NamedColor("White Smoke", 0xF5F5F5),
        NamedColor("Yellow Green", 0x9ACD32),
    ]
}
