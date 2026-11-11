import SwiftUI

struct OnboardingScreen: View {
    let onFinished: () -> Void
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    Spacer().frame(height: 20)
                    Text("TapTone")
                        .font(AppFont.headlineLarge.weight(.heavy))
                        .foregroundStyle(Color(argb: 0xFF123C38))
                    Spacer().frame(height: 10)
                    Text(strings.t("tagline"))
                        .font(AppFont.titleMedium)
                        .lineSpacing(5)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.onSurfaceVariant)
                    Spacer().frame(height: 30)
                    OnboardingFeature(
                        systemImage: "wand.and.stars",
                        title: strings.t("onboarding.enhance.title"),
                        text: strings.t("onboarding.enhance.text")
                    )
                    Spacer().frame(height: 14)
                    OnboardingFeature(
                        systemImage: "eyedropper",
                        title: strings.t("onboarding.identify.title"),
                        text: strings.t("onboarding.identify.text")
                    )
                    Spacer().frame(height: 14)
                    OnboardingFeature(
                        systemImage: "eye.fill",
                        title: strings.t("onboarding.understand.title"),
                        text: strings.t("onboarding.understand.text")
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            Spacer().frame(height: 18)
            Button(action: onFinished) {
                IconLabel(systemImage: "arrow.right", title: strings.t("getStarted"))
            }
            .buttonStyle(FilledButtonStyle())
        }
        .padding(EdgeInsets(top: 22, leading: 24, bottom: 24, trailing: 24))
    }
}

private struct OnboardingFeature: View {
    let systemImage: String
    let title: String
    let text: String
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(palette.onPrimaryContainer)
                .frame(width: 24, height: 24)
                .padding(11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(palette.primaryContainer)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFont.titleMedium)
                    .foregroundStyle(palette.onSurface)
                Text(text)
                    .font(.system(size: 15))
                    .lineSpacing(AppFont.bodyLineSpacing)
                    .foregroundStyle(Color(argb: 0xFF52615E))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
