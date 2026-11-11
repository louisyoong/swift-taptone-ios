import SwiftUI

struct TapToneShell: View {
    @State private var selectedIndex = 0
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            currentPage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            LiquidGlassNavBar(
                items: [
                    .init(systemImage: "wand.and.stars", label: strings.t("tab.assist")),
                    .init(systemImage: "eyedropper", label: strings.t("tab.detect")),
                    .init(systemImage: "eye.fill", label: strings.t("tab.simulate")),
                    .init(systemImage: "questionmark.square.fill", label: strings.t("tab.colorTest")),
                    .init(systemImage: "gearshape.fill", label: strings.t("tab.settings")),
                ],
                currentIndex: selectedIndex,
                onTap: { selectedIndex = $0 },
                isDark: palette.isDark,
                activeColor: palette.primary,
                inactiveColor: palette.onSurfaceVariant,
                glassColor: palette.isDark ? Color(argb: 0xF00E1513) : Color(argb: 0xCCFFFFFF)
            )
        }
        .background(palette.scaffold.ignoresSafeArea())
    }

    @ViewBuilder
    private var currentPage: some View {
        switch selectedIndex {
        case 1: ColorDetectorScreen()
        case 2: SimulationScreen()
        case 3: ColorTestScreen()
        case 4: SettingsScreen()
        default: ColorAssistScreen()
        }
    }
}
