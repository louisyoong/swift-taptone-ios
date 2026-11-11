import SwiftUI

struct TapToneShell: View {
    @State private var selectedIndex = 0
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        GeometryReader { proxy in
            let placement = RailPlacement(size: proxy.size, insets: proxy.safeAreaInsets, direction: layoutDirection)
            // The menu is a safe-area inset rather than a sibling, so camera
            // pages can run full screen behind the glass menu while other pages
            // keep their content clear of it. The modifier chain stays the same
            // for every placement, so the current page (camera, test progress)
            // survives fold/unfold and rotation.
            currentPage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.layoutDirection, layoutDirection)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if placement == .none {
                        LiquidGlassNavBar(
                            items: items,
                            currentIndex: selectedIndex,
                            onTap: { selectedIndex = $0 },
                            isDark: palette.isDark,
                            activeColor: palette.primary,
                            inactiveColor: palette.onSurfaceVariant,
                            glassColor: glassColor
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .environment(\.layoutDirection, layoutDirection)
                    }
                }
                // Physical right / left (the container below is pinned to LTR).
                .safeAreaInset(edge: .trailing, spacing: 0) {
                    if placement == .right {
                        rail(compact: false)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .safeAreaInset(edge: .leading, spacing: 0) {
                    if placement == .left {
                        rail(compact: false)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .overlay {
                    if case let .inStatusColumn(onRight, width) = placement {
                        // Folded iPhone Duo: sit inside the system's status column,
                        // lined up under the clock and Wi-Fi icon, at the bottom end.
                        rail(compact: true)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: width)
                            .padding(.bottom, 8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: onRight ? .bottomTrailing : .bottomLeading)
                            .offset(x: onRight ? width : -width)
                            .transition(.opacity)
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
                .animation(.smooth(duration: 0.3), value: placement)
        }
        .background(palette.scaffold.ignoresSafeArea())
    }

    private func rail(compact: Bool) -> some View {
        LiquidGlassNavRail(
            items: items,
            currentIndex: selectedIndex,
            onTap: { selectedIndex = $0 },
            isDark: palette.isDark,
            activeColor: palette.primary,
            inactiveColor: palette.onSurfaceVariant,
            glassColor: glassColor,
            compact: compact
        )
        .environment(\.layoutDirection, layoutDirection)
    }

    /// Where the tab menu goes.
    ///
    /// - The folded iPhone Duo cover screen is portrait for the app, but the
    ///   system puts its camera, clock and status icons in a column down one
    ///   side instead of across the top. A compact menu goes inside that
    ///   column, lined up with the status icons.
    /// - Landscape screens (iPad, or an iPhone held sideways) get the side
    ///   rail on the trailing edge.
    /// - Everything else (portrait iPhones, the unfolded Duo, iPad portrait)
    ///   keeps the bottom bar.
    private enum RailPlacement: Equatable {
        case none, left, right
        case inStatusColumn(onRight: Bool, width: CGFloat)

        init(size: CGSize, insets: EdgeInsets, direction: LayoutDirection) {
            let isLTR = direction == .leftToRight
            let leftInset = isLTR ? insets.leading : insets.trailing
            let rightInset = isLTR ? insets.trailing : insets.leading
            let sideChrome = max(leftInset, rightInset)

            if sideChrome > insets.top + 8, abs(leftInset - rightInset) > 8 {
                // System chrome lives in a column on one side (folded Duo).
                self = .inStatusColumn(onRight: rightInset > leftInset, width: sideChrome)
            } else if size.width > size.height {
                self = isLTR ? .right : .left
            } else {
                self = .none
            }
        }
    }

    private var items: [LiquidGlassNavBar.Item] {
        [
            .init(systemImage: "wand.and.stars", label: strings.t("tab.assist")),
            .init(systemImage: "eyedropper", label: strings.t("tab.detect")),
            .init(systemImage: "eye.fill", label: strings.t("tab.simulate")),
            .init(systemImage: "questionmark.square.fill", label: strings.t("tab.colorTest")),
            .init(systemImage: "gearshape.fill", label: strings.t("tab.settings")),
        ]
    }

    private var glassColor: Color {
        palette.isDark ? Color(argb: 0xF00E1513) : Color(argb: 0xCCFFFFFF)
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
