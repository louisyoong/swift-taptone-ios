import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Builds a color from a Flutter-style 0xAARRGGBB literal.
    init(argb: UInt32) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }
}

// MARK: - Palette

/// Mirrors the Material 3 `ColorScheme.fromSeed(seedColor: 0xFF126A63)` scheme the
/// Flutter app used (tonal-spot variant), plus the app's own scaffold/card overrides.
struct Palette {
    let isDark: Bool
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondaryContainer: Color
    let tertiaryContainer: Color
    let surface: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let surfaceContainerLow: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let outline: Color
    let outlineVariant: Color
    let error: Color
    let inverseSurface: Color
    let onInverseSurface: Color
    // App-level overrides from ThemeData.
    let scaffold: Color
    let card: Color
    let cardBorder: Color

    static let light = Palette(
        isDark: false,
        primary: Color(argb: 0xFF006A63),
        onPrimary: Color(argb: 0xFFFFFFFF),
        primaryContainer: Color(argb: 0xFF9DF2E8),
        onPrimaryContainer: Color(argb: 0xFF00504A),
        secondaryContainer: Color(argb: 0xFFCCE8E4),
        tertiaryContainer: Color(argb: 0xFFCEE5FF),
        surface: Color(argb: 0xFFF4FBF9),
        onSurface: Color(argb: 0xFF161D1C),
        onSurfaceVariant: Color(argb: 0xFF3F4947),
        surfaceContainerLow: Color(argb: 0xFFEFF5F3),
        surfaceContainerHigh: Color(argb: 0xFFE3EAE7),
        surfaceContainerHighest: Color(argb: 0xFFDDE4E2),
        outline: Color(argb: 0xFF6F7977),
        outlineVariant: Color(argb: 0xFFBEC9C6),
        error: Color(argb: 0xFFBA1A1A),
        inverseSurface: Color(argb: 0xFF2B3231),
        onInverseSurface: Color(argb: 0xFFECF2F0),
        scaffold: Color(argb: 0xFFF7FAF9),
        card: Color(argb: 0xFFFFFFFF),
        cardBorder: Color(argb: 0xFFE2EAE7)
    )

    static let dark = Palette(
        isDark: true,
        primary: Color(argb: 0xFF81D5CC),
        onPrimary: Color(argb: 0xFF003733),
        primaryContainer: Color(argb: 0xFF00504A),
        onPrimaryContainer: Color(argb: 0xFF9DF2E8),
        secondaryContainer: Color(argb: 0xFF324B48),
        tertiaryContainer: Color(argb: 0xFF2F4961),
        surface: Color(argb: 0xFF0E1514),
        onSurface: Color(argb: 0xFFDDE4E2),
        onSurfaceVariant: Color(argb: 0xFFBEC9C6),
        surfaceContainerLow: Color(argb: 0xFF161D1C),
        surfaceContainerHigh: Color(argb: 0xFF252B2A),
        surfaceContainerHighest: Color(argb: 0xFF303635),
        outline: Color(argb: 0xFF899391),
        outlineVariant: Color(argb: 0xFF3F4947),
        error: Color(argb: 0xFFFFB4AB),
        inverseSurface: Color(argb: 0xFFDDE4E2),
        onInverseSurface: Color(argb: 0xFF2B3231),
        scaffold: Color(argb: 0xFF111817),
        card: Color(argb: 0xFF1B2624),
        cardBorder: Color(argb: 0xFF33433F)
    )
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.light
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

// MARK: - Typography (Material 3 text theme + the app's overrides)

enum AppFont {
    static let headlineLarge = Font.system(size: 32)
    static let headlineMedium = Font.system(size: 28)
    static let headlineSmall = Font.system(size: 24)
    static let titleLarge = Font.system(size: 22)
    static let titleMedium = Font.system(size: 18, weight: .bold)
    static let titleSmall = Font.system(size: 14, weight: .medium)
    static let bodyMedium = Font.system(size: 16)
    static let bodySmall = Font.system(size: 12)
    static let labelLarge = Font.system(size: 16, weight: .bold)
    /// Extra spacing that approximates Flutter's `height: 1.35` on 16pt body text.
    static let bodyLineSpacing: CGFloat = 2.5
}

// MARK: - Buttons

/// Material 3 `FilledButton` (min height 52, radius 14 by default).
struct FilledButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        FilledButtonBody(configuration: configuration, cornerRadius: cornerRadius)
    }

    private struct FilledButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let cornerRadius: CGFloat
        @Environment(\.palette) private var palette
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(AppFont.labelLarge)
                .foregroundStyle(isEnabled ? palette.onPrimary : palette.onSurface.opacity(0.38))
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isEnabled ? palette.primary : palette.onSurface.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0))
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

/// Material 3 `OutlinedButton` (min height 52, radius 14 by default).
struct OutlinedButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        OutlinedButtonBody(configuration: configuration, cornerRadius: cornerRadius)
    }

    private struct OutlinedButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let cornerRadius: CGFloat
        @Environment(\.palette) private var palette

        var body: some View {
            configuration.label
                .font(AppFont.labelLarge)
                .foregroundStyle(palette.primary)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(palette.primary.opacity(configuration.isPressed ? 0.12 : 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(palette.outline, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

/// Plain press feedback used for InkWell-style tappable areas.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Icon + label row used by `FilledButton.icon` / `OutlinedButton.icon`.
struct IconLabel: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Card

/// The app's `CardTheme`: flat, radius 18, 1pt border.
struct AppCard: ViewModifier {
    @Environment(\.palette) private var palette
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.card)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(palette.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func appCard(cornerRadius: CGFloat = 18) -> some View {
        modifier(AppCard(cornerRadius: cornerRadius))
    }
}
