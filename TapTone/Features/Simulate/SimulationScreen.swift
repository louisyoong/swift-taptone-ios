import SwiftUI

struct SimulationScreen: View {
    @StateObject private var camera = CameraController(mode: .simulate)
    @State private var activeFilter: SimulationFilter?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.strings) private var strings

    var body: some View {
        Group {
            switch camera.state {
            case .unavailable:
                CameraMessageView(systemImage: "video.slash", text: strings.t("cameraUnavailable"))
            case .starting:
                CameraMessageView(systemImage: "camera", text: strings.t("startingCamera"), isLoading: true)
            case .running:
                SimulationLiveView(activeFilter: $activeFilter) {
                    if let frame = camera.frame {
                        Image(decorative: frame, scale: 1).resizable()
                    }
                }
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { camera.start() } else { camera.stop() }
        }
        .onChange(of: activeFilter) { _, filter in
            camera.matrix = filter?.matrix ?? ColorMatrices.identity
        }
    }
}

/// Full-bleed filtered feed with the current-mode label and filter picker on top.
private struct SimulationLiveView<Feed: View>: View {
    @Binding var activeFilter: SimulationFilter?
    @ViewBuilder let feed: () -> Feed
    @Environment(\.strings) private var strings

    var body: some View {
        // The feed runs full screen (under the status bar and behind the glass
        // menu); the label and filter bar stay in the safe area.
        Color.clear.background {
            ZStack {
                Color.black
                GeometryReader { proxy in
                    feed()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .topLeading) {
            PreviewLabel(
                text: activeFilter?.title ?? strings.t("normal"),
                systemImage: activeFilter == nil ? "eye" : "eye.trianglebadge.exclamationmark"
            )
            .padding(14)
            .animation(.easeInOut(duration: 0.2), value: activeFilter)
        }
        .overlay(alignment: .bottom) {
            LiveSimulationFilters(
                activeFilter: activeFilter,
                onSelect: { filter in
                    withAnimation(.snappy(duration: 0.25)) { activeFilter = filter }
                }
            )
            .padding(.bottom, 16)
        }
        .sensoryFeedback(.selection, trigger: activeFilter)
    }
}

private struct LiveSimulationFilters: View {
    let activeFilter: SimulationFilter?
    let onSelect: (SimulationFilter?) -> Void
    @Environment(\.strings) private var strings
    @Namespace private var selection

    var body: some View {
        // Centered when every filter fits (iPad, unfolded, landscape); scrolls on narrow phones.
        ViewThatFits(in: .horizontal) {
            bar.padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                bar.padding(.horizontal, 16)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }

    private var bar: some View {
        HStack(spacing: 4) {
            LiveFilterButton(
                title: strings.t("normal"),
                matrix: ColorMatrices.identity,
                isSelected: activeFilter == nil,
                namespace: selection
            ) { onSelect(nil) }
            ForEach(SimulationFilter.allCases) { filter in
                LiveFilterButton(
                    title: filter.title,
                    matrix: filter.matrix,
                    isSelected: activeFilter == filter,
                    namespace: selection
                ) { onSelect(filter) }
            }
        }
        .padding(6)
        .background(Capsule().fill(Color.black.opacity(0.4)))
        .glassEffect(.clear, in: Capsule())
        .environment(\.colorScheme, .dark)
    }
}

private struct LiveFilterButton: View {
    let title: String
    let matrix: ColorMatrix
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SwatchTrio(matrix: matrix)
                Text(title)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(isSelected ? Color(argb: 0xFF123C38) : .white)
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.white)
                        .matchedGeometryEffect(id: "selected", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Red, green and blue as they look through `matrix` — a tiny preview of
/// which colors each simulation shifts.
private struct SwatchTrio: View {
    let matrix: ColorMatrix

    private static let primaries: [(Double, Double, Double)] = [(230, 57, 70), (67, 170, 80), (52, 100, 220)]

    var body: some View {
        HStack(spacing: -5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(transformed(Self.primaries[i]))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5))
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityHidden(true)
    }

    private func transformed(_ rgb: (Double, Double, Double)) -> Color {
        func channel(_ row: Int) -> Double {
            let m = matrix[(row * 5)..<(row * 5 + 5)].map { $0 }
            let value = m[0] * rgb.0 + m[1] * rgb.1 + m[2] * rgb.2 + m[3] * 255 + m[4]
            return min(max(value, 0), 255) / 255
        }
        return Color(.sRGB, red: channel(0), green: channel(1), blue: channel(2), opacity: 1)
    }
}
