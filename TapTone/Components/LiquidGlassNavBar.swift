import SwiftUI

/// SwiftUI port of the app's forked `LiquidGlassNavBar` (liquid_glass_bar):
/// a glass pill with a sliding indicator that can be dragged between tabs,
/// selected icon scales up and its label collapses. Uses the native iOS 26
/// Liquid Glass material for the bar body.
struct LiquidGlassNavBar: View {
    struct Item: Identifiable {
        let systemImage: String
        let label: String
        var id: String { systemImage }
    }

    let items: [Item]
    let currentIndex: Int
    let onTap: (Int) -> Void
    let isDark: Bool
    let activeColor: Color
    let inactiveColor: Color
    let glassColor: Color

    // LiquidGlassBarStyle defaults.
    private let barHeight: CGFloat = 60
    private let borderRadius: CGFloat = 32
    private let iconSize: CGFloat = 24
    private let selectedIconScale: CGFloat = 1.2
    private let animation = Animation.easeOut(duration: 0.3)

    @State private var dragAlignment: CGFloat?
    @State private var dragStartAlignment: CGFloat = 0
    @State private var isDragging = false

    private var lastIndex: Int { max(items.count - 1, 0) }

    private func alignment(for index: Int) -> CGFloat {
        lastIndex == 0 ? 0 : -1 + CGFloat(index) * 2 / CGFloat(lastIndex)
    }

    private func nearestIndex(for alignment: CGFloat) -> Int {
        let normalized = (alignment + 1) / 2
        return min(max(Int((normalized * CGFloat(lastIndex)).rounded()), 0), lastIndex)
    }

    private var highlightedIndex: Int? {
        guard isDragging, let dragAlignment else { return nil }
        return nearestIndex(for: dragAlignment)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: borderRadius, style: .continuous)
        GeometryReader { proxy in
            let width = proxy.size.width
            let itemWidth = width / CGFloat(max(items.count, 1))
            let totalDragWidth = max(width - itemWidth, 1)
            let currentAlignment = isDragging ? (dragAlignment ?? 0) : alignment(for: currentIndex)

            ZStack(alignment: .leading) {
                indicator
                    .frame(width: itemWidth, height: 50)
                    .offset(x: (currentAlignment + 1) / 2 * totalDragWidth)
                    .animation(isDragging ? nil : animation, value: currentAlignment)

                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        NavBarItemView(
                            item: item,
                            isSelected: currentIndex == index,
                            isHighlighted: highlightedIndex == index,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            iconSize: iconSize,
                            selectedIconScale: selectedIconScale
                        )
                        .frame(width: itemWidth)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(index) }
                    }
                }
            }
            .frame(width: width, height: barHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartAlignment = alignment(for: currentIndex)
                        }
                        let delta = value.translation.width / totalDragWidth * 2
                        dragAlignment = min(max(dragStartAlignment + delta, -1), 1)
                    }
                    .onEnded { _ in
                        let target = nearestIndex(for: dragAlignment ?? alignment(for: currentIndex))
                        isDragging = false
                        dragAlignment = nil
                        onTap(target)
                    }
            )
        }
        .frame(height: barHeight)
        .padding(6)
        .background {
            shape
                .fill(.clear)
                .glassEffect(.regular.tint(glassColor), in: shape)
                .shadow(color: Color(argb: 0x1A000000), radius: 10, x: 0, y: 10)
        }
        .overlay {
            shape
                .strokeBorder(isDark ? Color.black.opacity(0.5) : Color(argb: 0xE6FFFFFF), lineWidth: 2)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        // Indicator math assumes left-to-right, so keep the bar LTR in Arabic too.
        .environment(\.layoutDirection, .leftToRight)
    }

    private var indicator: some View {
        NavIndicator(isDark: isDark, activeColor: activeColor)
    }
}

/// The glossy capsule that marks the selected tab (shared by the bar and rail).
private struct NavIndicator: View {
    let isDark: Bool
    let activeColor: Color

    var body: some View {
        let gradient = isDark
            ? [activeColor.opacity(0.28), activeColor.opacity(0.08), Color.black.opacity(0.35)]
            : [activeColor.opacity(0.15), Color(argb: 0x4DFFFFFF), Color(argb: 0x1AFFFFFF)]
        let border = isDark ? activeColor.opacity(0.45) : Color(argb: 0x99FFFFFF)
        let innerShadow = isDark ? Color.black.opacity(0.4) : Color(argb: 0xCCFFFFFF)
        let capsule = RoundedRectangle(cornerRadius: 30, style: .continuous)

        capsule
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: gradient[0], location: 0),
                        .init(color: gradient[1], location: 0.4),
                        .init(color: gradient[2], location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(capsule.strokeBorder(border, lineWidth: 1.5))
            .shadow(color: activeColor.opacity(0.25), radius: 6, x: 0, y: 4)
            .shadow(color: innerShadow, radius: 4, x: -2, y: -2)
    }
}

/// Vertical version of `LiquidGlassNavBar`, shown on the trailing side of
/// wide screens (unfolded iPhone Duo, iPad, iPhone in landscape).
struct LiquidGlassNavRail: View {
    let items: [LiquidGlassNavBar.Item]
    let currentIndex: Int
    let onTap: (Int) -> Void
    let isDark: Bool
    let activeColor: Color
    let inactiveColor: Color
    let glassColor: Color
    /// Smaller variant that fits inside the folded iPhone Duo's status column.
    var compact = false

    @Namespace private var indicatorSpace

    private var itemSize: CGSize { compact ? CGSize(width: 62, height: 52) : CGSize(width: 76, height: 62) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: compact ? 28 : 32, style: .continuous)
        VStack(spacing: compact ? 2 : 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isSelected = currentIndex == index
                NavBarItemView(
                    item: item,
                    isSelected: isSelected,
                    isHighlighted: false,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    iconSize: compact ? 20 : 24,
                    selectedIconScale: 1.2,
                    labelSize: compact ? 9 : 10,
                    horizontalPadding: compact ? 3 : 8
                )
                .frame(width: itemSize.width, height: itemSize.height)
                .background {
                    if isSelected {
                        NavIndicator(isDark: isDark, activeColor: activeColor)
                            .matchedGeometryEffect(id: "indicator", in: indicatorSpace)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) { onTap(index) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.label)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(compact ? 4 : 6)
        .background {
            shape
                .fill(.clear)
                .glassEffect(.regular.tint(glassColor), in: shape)
                .shadow(color: Color(argb: 0x1A000000), radius: 10, x: -4, y: 6)
        }
        .overlay {
            shape
                .strokeBorder(isDark ? Color.black.opacity(0.5) : Color(argb: 0xE6FFFFFF), lineWidth: 2)
                .allowsHitTesting(false)
        }
        .padding(.leading, compact ? 0 : 8)
        .padding(.trailing, compact ? 0 : 12)
        .frame(maxHeight: .infinity)
    }
}

private struct NavBarItemView: View {
    let item: LiquidGlassNavBar.Item
    let isSelected: Bool
    let isHighlighted: Bool
    let activeColor: Color
    let inactiveColor: Color
    let iconSize: CGFloat
    let selectedIconScale: CGFloat
    var labelSize: CGFloat = 10
    var horizontalPadding: CGFloat = 8

    var body: some View {
        let isActive = isSelected || isHighlighted
        VStack(spacing: 0) {
            Image(systemName: item.systemImage)
                .font(.system(size: iconSize * 0.85))
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(isActive ? activeColor : inactiveColor)
                .scaleEffect(isSelected ? selectedIconScale : 1)
                .animation(.spring(response: 0.45, dampingFraction: 0.45), value: isSelected)
            if !isSelected {
                Text(item.label)
                    .font(.system(size: labelSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)
                    .foregroundStyle(isActive ? activeColor : inactiveColor)
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeOut(duration: 0.3), value: isActive)
    }
}
