import SwiftUI

@main
struct TapToneApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environment(\.strings, settings.strings)
                .environment(\.palette, settings.palette)
                .environment(\.locale, settings.language.locale)
                .environment(\.layoutDirection, settings.language.isRightToLeft ? .rightToLeft : .leftToRight)
                .preferredColorScheme(settings.darkModeEnabled ? .dark : .light)
                .tint(settings.palette.primary)
        }
    }
}

/// Equivalent of the Flutter `OnboardingGate`.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.scaffold.ignoresSafeArea()
            if settings.hasCompletedOnboarding {
                TapToneShell()
            } else {
                OnboardingScreen { settings.finishOnboarding() }
            }
        }
    }
}
