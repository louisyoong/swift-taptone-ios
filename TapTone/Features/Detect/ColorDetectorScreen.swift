import SwiftUI
import UIKit

struct ColorDetectorScreen: View {
    @StateObject private var camera = CameraController(mode: .detect)
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
                DetectorLiveView(detected: camera.detected) {
                    CameraPreviewView(session: camera.session, device: camera.device)
                }
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { camera.start() } else { camera.stop() }
        }
    }
}

/// Camera feed with the aiming reticle and the result panel on top.
private struct DetectorLiveView<Feed: View>: View {
    let detected: DetectedColor
    @ViewBuilder let feed: () -> Feed

    var body: some View {
        // Feed, vignette and target run full screen (under the status bar and
        // behind the glass menu); the result panel stays in the safe area.
        Color.clear.background {
            fullScreenFeed.ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            DetectedColorPanel(detected: detected)
                .frame(maxWidth: 520)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }

    /// Centered on the whole screen, so the target sits on the frame centre
    /// that the color is sampled from.
    private var fullScreenFeed: some View {
        ZStack {
            // Overlay keeps the feed from sizing the screen wider than its container.
            Color.black.overlay { feed() }.clipped()
            // Soft vignette so the reticle and panel stand out on bright scenes.
            RadialGradient(
                colors: [.clear, .black.opacity(0.35)],
                center: .center,
                startRadius: 140,
                endRadius: 520
            )
            .allowsHitTesting(false)
            CameraTarget(color: detected.rgb.color)
        }
    }
}

/// Aiming reticle: a ring with tick marks whose center shows the sampled color.
private struct CameraTarget: View {
    let color: Color

    var body: some View {
        ZStack {
            // Corner brackets.
            ForEach(0..<4, id: \.self) { i in
                Bracket()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 18, height: 18)
                    .offset(x: -44, y: -44)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
            Circle()
                .strokeBorder(Color.white, lineWidth: 3)
                .frame(width: 64, height: 64)
            Circle()
                .fill(color)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                .frame(width: 22, height: 22)
                .animation(.easeOut(duration: 0.2), value: color)
        }
        .frame(width: 120, height: 120)
        .shadow(color: .black.opacity(0.5), radius: 4)
        .accessibilityHidden(true)
    }

    private struct Bracket: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            return path
        }
    }
}

private struct DetectedColorPanel: View {
    let detected: DetectedColor
    @Environment(\.strings) private var strings
    @State private var copied = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(detected.rgb.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
                )
                .frame(width: 64, height: 64)
                .shadow(color: detected.rgb.color.opacity(0.5), radius: 10, y: 4)
            VStack(alignment: .leading, spacing: 6) {
                Text(strings.colorName(detected.name))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.opacity)
                HStack(spacing: 6) {
                    Text(detected.hex)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.16)))
                    Text("R\(detected.rgb.r) G\(detected.rgb.g) B\(detected.rgb.b)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeOut(duration: 0.15), value: detected.name)
            copyButton
        }
        .padding(14)
        .background(shape.fill(Color.black.opacity(0.45)))
        .glassEffect(.clear, in: shape)
        .environment(\.colorScheme, .dark)
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = detected.hex
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.4))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(copied ? 0.28 : 0.14)))
        }
        .buttonStyle(PressableStyle())
        .sensoryFeedback(.success, trigger: copied) { _, new in new }
        .accessibilityLabel(detected.hex)
    }
}
