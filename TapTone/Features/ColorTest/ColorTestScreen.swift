import SwiftUI

/// Color vision screening: a 10-question number test for teens/adults, a
/// 10-question animal test for kids and a 10-question shapes test, picked
/// from a mode-selection screen.
struct ColorTestScreen: View {
    private enum RootMode { case select, adult, kid, shape }
    @State private var mode: RootMode = .select

    var body: some View {
        ZStack {
            switch mode {
            case .select:
                ModeSelectionView(
                    onSelectAdult: { go(.adult) },
                    onSelectKid: { go(.kid) },
                    onSelectShape: { go(.shape) }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            case .adult:
                AdultColorTest(onBack: { go(.select) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .kid:
                ChoiceColorTest(config: .kid, onBack: { go(.select) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .shape:
                ChoiceColorTest(config: .shape, onBack: { go(.select) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    private func go(_ next: RootMode) {
        withAnimation(.smooth(duration: 0.35)) { mode = next }
    }
}

// MARK: - Accent per test

/// Each test gets its own accent so the flows feel distinct:
/// teal (app primary) for adults, warm orange for kids, purple for shapes.
private struct TestAccent {
    let tint: Color
    let onTint: Color
    let container: Color
    let onContainer: Color

    static func adult(_ p: Palette) -> TestAccent {
        TestAccent(tint: p.primary, onTint: p.onPrimary, container: p.primaryContainer, onContainer: p.onPrimaryContainer)
    }

    static func kid(_ p: Palette) -> TestAccent {
        p.isDark
            ? TestAccent(tint: Color(argb: 0xFFFFB77C), onTint: Color(argb: 0xFF4E2600),
                         container: Color(argb: 0xFF6F3A06), onContainer: Color(argb: 0xFFFFDCC4))
            : TestAccent(tint: Color(argb: 0xFFA5520A), onTint: .white,
                         container: Color(argb: 0xFFFFDCC4), onContainer: Color(argb: 0xFF331200))
    }

    static func shape(_ p: Palette) -> TestAccent {
        p.isDark
            ? TestAccent(tint: Color(argb: 0xFFCFBCFF), onTint: Color(argb: 0xFF381E72),
                         container: Color(argb: 0xFF4F378B), onContainer: Color(argb: 0xFFEADDFF))
            : TestAccent(tint: Color(argb: 0xFF6750A4), onTint: .white,
                         container: Color(argb: 0xFFE9DDFF), onContainer: Color(argb: 0xFF22005D))
    }
}

// MARK: - Mode selection

private struct ModeSelectionView: View {
    let onSelectAdult: () -> Void
    let onSelectKid: () -> Void
    let onSelectShape: () -> Void
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 34))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(palette.primary)
                    Text(strings.t("colorTest.mode.title"))
                        .font(AppFont.headlineSmall.weight(.heavy))
                        .foregroundStyle(palette.onSurface)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)

                ModeCard(
                    badge: .adult,
                    symbol: "textformat.123",
                    title: strings.t("colorTest.mode.adultTitle"),
                    description: strings.t("colorTest.mode.adultDesc"),
                    accent: .adult(palette),
                    onTap: onSelectAdult
                )
                ModeCard(
                    badge: .kid,
                    symbol: "pawprint.fill",
                    title: strings.t("colorTest.mode.kidTitle"),
                    description: strings.t("colorTest.mode.kidDesc"),
                    accent: .kid(palette),
                    onTap: onSelectKid
                )
                ModeCard(
                    badge: .shape,
                    symbol: "triangle.fill",
                    title: strings.t("colorTest.mode.shapeTitle"),
                    description: strings.t("colorTest.mode.shapeDesc"),
                    accent: .shape(palette),
                    onTap: onSelectShape
                )

                DisclaimerCard(text: strings.t("colorTest.intro.disclaimer"))
                    .padding(.top, 4)
            }
            .padding(EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20))
            .readableWidth(640)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct ModeCard: View {
    let badge: TestBadgeKind
    let symbol: String
    let title: String
    let description: String
    let accent: TestAccent
    let onTap: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        Button(action: onTap) {
            HStack(spacing: 16) {
                TestBadgePlate(kind: badge, size: 76)
                    .padding(6)
                    .background(Circle().fill(palette.card))
                    .overlay(Circle().strokeBorder(accent.tint.opacity(0.25), lineWidth: 2))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppFont.titleLarge.weight(.bold))
                        .foregroundStyle(palette.onSurface)
                    Text(description)
                        .font(AppFont.bodyMedium)
                        .lineSpacing(AppFont.bodyLineSpacing)
                        .foregroundStyle(palette.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accent.onTint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(accent.tint))
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(alignment: .topTrailing) {
                // Large faded symbol in the corner as decoration.
                Image(systemName: symbol)
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(accent.tint.opacity(0.08))
                    .offset(x: 18, y: -22)
                    .accessibilityHidden(true)
            }
            .background(
                shape.fill(
                    LinearGradient(
                        colors: [accent.container.opacity(palette.isDark ? 0.55 : 0.75), palette.card],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .clipShape(shape)
            .overlay(shape.strokeBorder(accent.tint.opacity(0.18), lineWidth: 1))
            .shadow(color: accent.tint.opacity(palette.isDark ? 0 : 0.10), radius: 16, y: 8)
            .contentShape(shape)
        }
        .buttonStyle(BouncyPressStyle())
    }
}

// MARK: - Shared pieces

private enum TestPhase { case intro, quiz, result }

/// Scales down slightly while pressed, with a springy release.
private struct BouncyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Filled button in the test's accent color.
private struct AccentFilledButtonStyle: ButtonStyle {
    let accent: TestAccent

    func makeBody(configuration: Configuration) -> some View {
        AccentBody(configuration: configuration, accent: accent)
    }

    private struct AccentBody: View {
        let configuration: ButtonStyleConfiguration
        let accent: TestAccent
        @Environment(\.palette) private var palette
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
            configuration.label
                .font(AppFont.labelLarge)
                .foregroundStyle(isEnabled ? accent.onTint : palette.onSurface.opacity(0.38))
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(shape.fill(isEnabled ? accent.tint : palette.onSurface.opacity(0.12)))
                .overlay(shape.fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0)))
                .shadow(color: accent.tint.opacity(isEnabled && !palette.isDark ? 0.25 : 0), radius: 10, y: 5)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
                .contentShape(shape)
        }
    }
}

private struct BackBar: View {
    let onBack: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(palette.onSurface)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
    }
}

/// One segment per question: filled for answered, tinted for current.
private struct ProgressHeader: View {
    let index: Int
    let total: Int
    let accent: TestAccent
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i < index ? accent.tint : i == index ? accent.tint.opacity(0.4) : palette.surfaceContainerHighest)
                        .frame(height: 6)
                }
            }
            .animation(.easeOut(duration: 0.25), value: index)
            .accessibilityHidden(true)

            Text("\(index + 1)/\(total)")
                .font(AppFont.labelLarge)
                .monospacedDigit()
                .foregroundStyle(accent.onContainer)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(accent.container))
                .contentTransition(.numericText())
        }
    }
}

/// The plate sitting on a soft colored halo.
private struct PlateStage: View {
    let dots: [PlateDot]?
    let size: CGFloat
    let index: Int
    let accent: TestAccent

    var body: some View {
        PlateCard(dots: dots, size: size)
            .id(index)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.easeOut(duration: 0.25), value: dots == nil)
            .padding(14)
            .background(
                Circle().fill(
                    RadialGradient(
                        colors: [accent.container.opacity(0.9), accent.container.opacity(0)],
                        center: .center,
                        startRadius: size * 0.35,
                        endRadius: size * 0.62
                    )
                )
            )
    }
}

private struct IntroView: View {
    let badge: TestBadgeKind
    let title: String
    let text: String
    let disclaimer: String
    let startLabel: String
    let accent: TestAccent
    let onStart: () -> Void
    @Environment(\.palette) private var palette
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    TestBadgePlate(kind: badge, size: 150)
                        .padding(8)
                        .background(Circle().fill(palette.card))
                        .padding(24)
                        .background(
                            Circle().fill(
                                RadialGradient(
                                    colors: [accent.container, accent.container.opacity(0)],
                                    center: .center,
                                    startRadius: 60,
                                    endRadius: 120
                                )
                            )
                        )
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)
                    Spacer().frame(height: 8)
                    Text(title)
                        .font(AppFont.headlineSmall.weight(.heavy))
                        .foregroundStyle(palette.onSurface)
                        .multilineTextAlignment(.center)
                    Spacer().frame(height: 10)
                    Text(text)
                        .font(AppFont.bodyMedium)
                        .lineSpacing(AppFont.bodyLineSpacing)
                        .foregroundStyle(palette.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    Spacer().frame(height: 24)
                    DisclaimerCard(text: disclaimer)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            Spacer().frame(height: 12)
            Button(action: onStart) {
                IconLabel(systemImage: "play.fill", title: startLabel)
            }
            .buttonStyle(AccentFilledButtonStyle(accent: accent))
        }
        .padding(EdgeInsets(top: 8, leading: 20, bottom: 20, trailing: 20))
        .readableWidth(640)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

private struct DisclaimerCard: View {
    let text: String
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(palette.onSurfaceVariant)
                .frame(width: 20, height: 20)
            Text(text)
                .font(AppFont.bodySmall)
                .lineSpacing(1.5)
                .foregroundStyle(palette.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.surfaceContainerLow)
        )
    }
}

// MARK: - Adult (number) test

private struct AdultColorTest: View {
    let onBack: () -> Void
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    @State private var phase: TestPhase = .intro
    @State private var index = 0
    @State private var answers: [Int?] = Array(repeating: nil, count: Plates.adult.count)
    @State private var text = ""
    @State private var cantSee = false
    @State private var dotCache: [Int: [PlateDot]] = [:]

    private var results: [Bool] {
        Plates.adult.indices.map { answers[$0] == Plates.adult[$0].answer }
    }

    var body: some View {
        let accent = TestAccent.adult(palette)
        VStack(spacing: 0) {
            BackBar(onBack: onBack)
            ZStack {
                switch phase {
                case .intro:
                    IntroView(
                        badge: .adult,
                        title: strings.t("colorTest.intro.title"),
                        text: strings.t("colorTest.intro.text"),
                        disclaimer: strings.t("colorTest.intro.disclaimer"),
                        startLabel: strings.t("colorTest.start"),
                        accent: accent,
                        onStart: { setPhase(.quiz) }
                    )
                    .transition(.opacity)
                case .quiz:
                    QuizView(
                        index: index,
                        total: Plates.adult.count,
                        dots: dotCache[index],
                        accent: accent,
                        text: $text,
                        cantSee: cantSee,
                        onCantSeeChanged: setCantSee,
                        onSubmit: submit
                    )
                    .transition(.opacity)
                    .task(id: index) {
                        if dotCache[index] == nil {
                            let current = index
                            let dots = await Plates.adultDots(current)
                            dotCache[current] = dots
                        }
                    }
                case .result:
                    ResultView(results: results, accent: accent, onRetake: retake)
                        .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func setPhase(_ next: TestPhase) {
        withAnimation(.easeInOut(duration: 0.3)) { phase = next }
    }

    private func setCantSee(_ value: Bool) {
        withAnimation(.snappy(duration: 0.2)) { cantSee = value }
        if value { text = "" }
    }

    private func submit() {
        answers[index] = cantSee ? nil : Int(text.trimmingCharacters(in: .whitespaces))
        text = ""
        cantSee = false
        if index == Plates.adult.count - 1 {
            setPhase(.result)
        } else {
            withAnimation(.snappy(duration: 0.3)) { index += 1 }
        }
    }

    private func retake() {
        setPhase(.intro)
        index = 0
        answers = Array(repeating: nil, count: Plates.adult.count)
        text = ""
        cantSee = false
        dotCache = [:]
    }
}

private struct QuizView: View {
    let index: Int
    let total: Int
    let dots: [PlateDot]?
    let accent: TestAccent
    @Binding var text: String
    let cantSee: Bool
    let onCantSeeChanged: (Bool) -> Void
    let onSubmit: () -> Void

    @FocusState private var fieldFocused: Bool
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    private var canSubmit: Bool {
        cantSee || !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        let keyboardVisible = fieldFocused
        GeometryReader { proxy in
            if AdaptiveLayout.isWideLandscape(proxy.size) {
                // iPad landscape / unfolded sideways: plate left, answer controls right.
                let plateSize = max(160, min(proxy.size.height - 110, proxy.size.width * 0.44 - 36, 440))
                HStack(spacing: 32) {
                    VStack(spacing: 14) {
                        ProgressHeader(index: index, total: total, accent: accent)
                        PlateStage(dots: dots, size: plateSize, index: index, accent: accent)
                    }
                    .frame(width: plateSize + 28)
                    ScrollView {
                        controls.frame(maxWidth: 380)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .defaultScrollAnchor(.center)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(dismissKeyboardTarget)
            } else {
                // Fit plate + answer controls on one screen without scrolling.
                let cap: CGFloat = AdaptiveLayout.isRoomy(proxy.size) ? 400 : 270
                let plateSize = max(140, min(proxy.size.width - 48, keyboardVisible ? 150 : cap, proxy.size.height - 330))
                ScrollView {
                    VStack(spacing: 0) {
                        ProgressHeader(index: index, total: total, accent: accent)
                        Spacer().frame(height: keyboardVisible ? 6 : 12)
                        PlateStage(dots: dots, size: plateSize, index: index, accent: accent)
                        Spacer().frame(height: keyboardVisible ? 6 : 12)
                        controls.frame(maxWidth: 520)
                    }
                    .frame(width: proxy.size.width)
                    .background(dismissKeyboardTarget)
                    .animation(.easeOut(duration: 0.2), value: keyboardVisible)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(EdgeInsets(top: 14, leading: 20, bottom: 16, trailing: 20))
        .sensoryFeedback(.selection, trigger: index)
    }

    /// Tap outside the field to dismiss the keyboard.
    private var dismissKeyboardTarget: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { fieldFocused = false }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            Text(strings.t("colorTest.prompt"))
                .font(AppFont.titleMedium)
                .foregroundStyle(palette.onSurface)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 12)
            answerField
            Spacer().frame(height: 12)
            cantSeeToggle
            Spacer().frame(height: 16)
            Button(action: onSubmit) {
                IconLabel(
                    systemImage: index == total - 1 ? "checkmark" : "arrow.forward",
                    title: index == total - 1 ? strings.t("colorTest.finish") : strings.t("colorTest.next")
                )
            }
            .buttonStyle(AccentFilledButtonStyle(accent: accent))
            .disabled(!canSubmit)
        }
    }

    private var answerField: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return ZStack(alignment: .trailing) {
            TextField(strings.t("colorTest.inputHint"), text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(text.isEmpty ? AppFont.titleMedium.weight(.medium) : .system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(palette.onSurface)
                .focused($fieldFocused)
                .disabled(cantSee)
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter(\.isASCIIDigitCharacter)
                    if digits != newValue { text = digits }
                }
                .padding(.horizontal, 52)
                .frame(height: 64)
            if fieldFocused {
                Button { fieldFocused = false } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 18))
                        .foregroundStyle(palette.onSurfaceVariant)
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel(strings.t("colorTest.hideKeyboard"))
                .padding(.trailing, 6)
            }
        }
        .background(shape.fill(palette.card))
        .overlay(
            shape.strokeBorder(
                fieldFocused ? accent.tint : palette.cardBorder,
                lineWidth: fieldFocused ? 2 : 1
            )
        )
        .opacity(cantSee ? 0.5 : 1)
        .animation(.easeOut(duration: 0.15), value: fieldFocused)
    }

    private var cantSeeToggle: some View {
        Button { onCantSeeChanged(!cantSee) } label: {
            HStack(spacing: 8) {
                Image(systemName: cantSee ? "checkmark.circle.fill" : "eye.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                Text(strings.t("colorTest.cantSee"))
                    .font(AppFont.titleSmall.weight(.semibold))
            }
            .foregroundStyle(cantSee ? accent.onContainer : palette.onSurfaceVariant)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(cantSee ? accent.container : palette.surfaceContainerHigh))
            .overlay(Capsule().strokeBorder(cantSee ? accent.tint.opacity(0.6) : .clear, lineWidth: 1.5))
            .contentShape(Capsule())
        }
        .buttonStyle(BouncyPressStyle())
        .accessibilityAddTraits(cantSee ? .isSelected : [])
    }
}

private extension Character {
    var isASCIIDigitCharacter: Bool { ("0"..."9").contains(self) }
}

// MARK: - Multiple-choice tests (kids animals, shapes)

/// An answer option: an emoji (animals) or an SF Symbol (shapes) plus its name.
private struct ChoiceItem {
    enum Icon { case emoji(String), symbol(String) }
    let icon: Icon
    let labelKey: String
}

/// Everything that differs between the tap-the-answer tests.
private struct ChoiceTestConfig {
    let badge: TestBadgeKind
    let titleKey: String
    let textKey: String
    let promptKey: String
    let accent: (Palette) -> TestAccent
    let items: [ChoiceItem]
    let questionCount: Int
    let answer: (Int) -> Int
    let options: (Int) -> [Int]
    let dots: @Sendable (Int) async -> [PlateDot]

    static let kid = ChoiceTestConfig(
        badge: .kid,
        titleKey: "colorTest.kid.intro.title",
        textKey: "colorTest.kid.intro.text",
        promptKey: "colorTest.kid.prompt",
        accent: TestAccent.kid,
        items: Plates.animals.map { ChoiceItem(icon: .emoji($0.emoji), labelKey: "animal.\($0.id)") },
        questionCount: Plates.kid.count,
        answer: { Plates.kid[$0].animalIndex },
        options: Plates.kidOptions,
        dots: { await Plates.kidDots($0) }
    )

    static let shape = ChoiceTestConfig(
        badge: .shape,
        titleKey: "colorTest.shape.intro.title",
        textKey: "colorTest.shape.intro.text",
        promptKey: "colorTest.shape.prompt",
        accent: TestAccent.shape,
        items: Plates.shapes.map { ChoiceItem(icon: .symbol($0.symbol), labelKey: "shape.\($0.id)") },
        questionCount: Plates.shape.count,
        answer: { Plates.shape[$0].shapeIndex },
        options: Plates.shapeOptions,
        dots: { await Plates.shapeDots($0) }
    )
}

private struct ChoiceColorTest: View {
    let config: ChoiceTestConfig
    let onBack: () -> Void
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    @State private var phase: TestPhase = .intro
    @State private var index = 0
    @State private var correctAnswers: [Bool]
    @State private var dotCache: [Int: [PlateDot]] = [:]

    init(config: ChoiceTestConfig, onBack: @escaping () -> Void) {
        self.config = config
        self.onBack = onBack
        _correctAnswers = State(initialValue: Array(repeating: false, count: config.questionCount))
    }

    var body: some View {
        let accent = config.accent(palette)
        VStack(spacing: 0) {
            BackBar(onBack: onBack)
            ZStack {
                switch phase {
                case .intro:
                    IntroView(
                        badge: config.badge,
                        title: strings.t(config.titleKey),
                        text: strings.t(config.textKey),
                        disclaimer: strings.t("colorTest.intro.disclaimer"),
                        startLabel: strings.t("colorTest.start"),
                        accent: accent,
                        onStart: { setPhase(.quiz) }
                    )
                    .transition(.opacity)
                case .quiz:
                    ChoiceQuizView(
                        index: index,
                        total: config.questionCount,
                        dots: dotCache[index],
                        prompt: strings.t(config.promptKey),
                        items: config.items,
                        options: config.options(index),
                        accent: accent,
                        onSelect: select
                    )
                    .transition(.opacity)
                    .task(id: index) {
                        if dotCache[index] == nil {
                            let current = index
                            let dots = await config.dots(current)
                            dotCache[current] = dots
                        }
                    }
                case .result:
                    ResultView(results: correctAnswers, accent: accent, onRetake: retake)
                        .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func setPhase(_ next: TestPhase) {
        withAnimation(.easeInOut(duration: 0.3)) { phase = next }
    }

    private func select(_ itemIndex: Int) {
        correctAnswers[index] = itemIndex == config.answer(index)
        if index == config.questionCount - 1 {
            setPhase(.result)
        } else {
            withAnimation(.snappy(duration: 0.3)) { index += 1 }
        }
    }

    private func retake() {
        setPhase(.intro)
        index = 0
        correctAnswers = Array(repeating: false, count: config.questionCount)
        dotCache = [:]
    }
}

private struct ChoiceQuizView: View {
    let index: Int
    let total: Int
    let dots: [PlateDot]?
    let prompt: String
    let items: [ChoiceItem]
    let options: [Int]
    let accent: TestAccent
    let onSelect: (Int) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { proxy in
            if AdaptiveLayout.isWideLandscape(proxy.size) {
                // iPad landscape / unfolded sideways: plate left, choices right.
                let plateSize = max(160, min(proxy.size.height - 110, proxy.size.width * 0.44 - 36, 440))
                HStack(spacing: 32) {
                    VStack(spacing: 14) {
                        ProgressHeader(index: index, total: total, accent: accent)
                        PlateStage(dots: dots, size: plateSize, index: index, accent: accent)
                    }
                    .frame(width: plateSize + 28)
                    ScrollView {
                        choices.frame(maxWidth: 420)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .defaultScrollAnchor(.center)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                let cap: CGFloat = AdaptiveLayout.isRoomy(proxy.size) ? 380 : 230
                let plateSize = max(140, min(proxy.size.width - 48, cap, proxy.size.height - 250))
                ScrollView {
                    VStack(spacing: 0) {
                        ProgressHeader(index: index, total: total, accent: accent)
                        Spacer().frame(height: 12)
                        PlateStage(dots: dots, size: plateSize, index: index, accent: accent)
                        Spacer().frame(height: 12)
                        choices.frame(maxWidth: 560)
                    }
                    .frame(width: proxy.size.width)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(EdgeInsets(top: 14, leading: 20, bottom: 16, trailing: 20))
        .sensoryFeedback(.selection, trigger: index)
    }

    private var choices: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        let optionColors = [accent.container, palette.primaryContainer, palette.tertiaryContainer, palette.secondaryContainer]
        return VStack(spacing: 0) {
            Text(prompt)
                .font(AppFont.titleMedium)
                .foregroundStyle(palette.onSurface)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 14)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, itemIndex in
                    ChoiceOptionButton(
                        item: items[itemIndex],
                        color: optionColors[i % 4],
                        onTap: { onSelect(itemIndex) }
                    )
                }
            }
            .id(index)
            .transition(.opacity)
        }
    }
}

private struct ChoiceOptionButton: View {
    let item: ChoiceItem
    let color: Color
    let onTap: () -> Void
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        Button(action: onTap) {
            HStack(spacing: 10) {
                icon
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(palette.card.opacity(palette.isDark ? 0.25 : 0.8)))
                Text(strings.t(item.labelKey))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(shape.fill(color))
            .overlay(shape.strokeBorder(palette.onSurface.opacity(0.06), lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(BouncyPressStyle())
    }

    @ViewBuilder
    private var icon: some View {
        switch item.icon {
        case let .emoji(emoji):
            Text(emoji).font(.system(size: 30))
        case let .symbol(name):
            // Neutral ink so the option itself gives no color hint.
            Image(systemName: name)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(palette.onSurface)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Result

private struct ResultView: View {
    /// Whether each question was answered correctly, in order.
    let results: [Bool]
    let accent: TestAccent
    let onRetake: () -> Void
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette
    @State private var progress: CGFloat = 0

    private var correct: Int { results.filter { $0 }.count }
    private var total: Int { results.count }

    var body: some View {
        let percentage = Int((Double(correct) / Double(total) * 100).rounded())
        let messageKey = percentage >= 90
            ? "colorTest.result.good"
            : percentage >= 70 ? "colorTest.result.moderate" : "colorTest.result.poor"
        let style = resultStyle(for: messageKey)

        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text(strings.t("colorTest.resultTitle"))
                        .font(AppFont.headlineSmall.weight(.heavy))
                        .foregroundStyle(palette.onSurface)
                    Spacer().frame(height: 20)
                    scoreRing(percentage: percentage, color: style.color)
                    Spacer().frame(height: 20)
                    breakdown
                    Spacer().frame(height: 16)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: style.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(style.color)
                        Text(strings.t(messageKey))
                            .font(AppFont.bodyMedium.weight(.semibold))
                            .lineSpacing(AppFont.bodyLineSpacing)
                            .foregroundStyle(palette.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(style.color.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(style.color.opacity(0.3), lineWidth: 1)
                    )
                    Spacer().frame(height: 12)
                    DisclaimerCard(text: strings.t("colorTest.intro.disclaimer"))
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            Spacer().frame(height: 12)
            Button(action: onRetake) {
                IconLabel(systemImage: "arrow.clockwise", title: strings.t("colorTest.retake"))
            }
            .buttonStyle(AccentFilledButtonStyle(accent: accent))
        }
        .padding(EdgeInsets(top: 8, leading: 20, bottom: 20, trailing: 20))
        .readableWidth(640)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                progress = CGFloat(correct) / CGFloat(total)
            }
        }
        .sensoryFeedback(.success, trigger: progress > 0)
    }

    private func scoreRing(percentage: Int, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.08))
                .padding(-14)
            Circle()
                .stroke(palette.surfaceContainerHighest, lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.55), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(progress, 0.01))
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(percentage)%")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.onSurface)
                Text(
                    strings.t("colorTest.scoreCorrect")
                        .replacingFirst("{n}", with: "\(correct)")
                        .replacingFirst("{total}", with: "\(total)")
                )
                .font(AppFont.bodySmall.weight(.medium))
                .foregroundStyle(palette.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
        }
        .frame(width: 168, height: 168)
        .padding(14)
    }

    /// One chip per question. Correct and wrong differ by shape (filled check
    /// vs. outlined cross), not just by color, so it reads without red/green.
    private var breakdown: some View {
        let good = Color(argb: palette.isDark ? 0xFF81C784 : 0xFF2E7D32)
        return HStack(spacing: 6) {
            ForEach(Array(results.enumerated()), id: \.offset) { i, ok in
                VStack(spacing: 4) {
                    Image(systemName: ok ? "checkmark" : "xmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(ok ? (palette.isDark ? palette.onPrimary : .white) : palette.error)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Circle().fill(ok ? good : .clear))
                        .overlay(Circle().strokeBorder(ok ? .clear : palette.error.opacity(0.7), lineWidth: 1.5))
                    Text("\(i + 1)")
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(palette.onSurfaceVariant)
                }
                .frame(maxWidth: 30)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.surfaceContainerLow)
        )
    }

    private func resultStyle(for messageKey: String) -> (color: Color, icon: String) {
        switch messageKey {
        case "colorTest.result.good": return (Color(argb: palette.isDark ? 0xFF81C784 : 0xFF2E7D32), "checkmark.circle.fill")
        case "colorTest.result.moderate": return (Color(argb: 0xFFF9A825), "info.circle.fill")
        default: return (palette.error, "exclamationmark.circle.fill")
        }
    }
}

private extension String {
    func replacingFirst(_ target: String, with replacement: String) -> String {
        guard let range = range(of: target) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
}
