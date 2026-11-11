import SwiftUI
import Combine

/// Replaces the Flutter `ThemeSettingsScope` + `shared_preferences` storage.
final class AppSettings: ObservableObject {
    static let themeModePreferenceKey = "dark_mode_enabled"
    static let languagePreferenceKey = "app_language"
    static let onboardingCompletedPreferenceKey = "onboarding_completed"

    private let defaults: UserDefaults

    @Published var darkModeEnabled: Bool {
        didSet { defaults.set(darkModeEnabled, forKey: Self.themeModePreferenceKey) }
    }

    @Published var language: AppLanguage {
        didSet { defaults.set(language.code, forKey: Self.languagePreferenceKey) }
    }

    @Published private(set) var hasCompletedOnboarding: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        darkModeEnabled = Self.bool(defaults, Self.themeModePreferenceKey) ?? false
        language = AppLanguage.from(code: Self.string(defaults, Self.languagePreferenceKey))
        hasCompletedOnboarding = Self.bool(defaults, Self.onboardingCompletedPreferenceKey) ?? false
    }

    var strings: AppStrings { AppStrings(language: language) }
    var palette: Palette { darkModeEnabled ? .dark : .light }

    func finishOnboarding() {
        defaults.set(true, forKey: Self.onboardingCompletedPreferenceKey)
        hasCompletedOnboarding = true
    }

    // Flutter's shared_preferences stores keys in UserDefaults with a
    // "flutter." prefix. Reading those as a fallback means users upgrading
    // from the Flutter build (same bundle ID) keep their settings.
    private static func bool(_ defaults: UserDefaults, _ key: String) -> Bool? {
        for candidate in [key, "flutter." + key] where defaults.object(forKey: candidate) != nil {
            return defaults.bool(forKey: candidate)
        }
        return nil
    }

    private static func string(_ defaults: UserDefaults, _ key: String) -> String? {
        for candidate in [key, "flutter." + key] {
            if let value = defaults.string(forKey: candidate) { return value }
        }
        return nil
    }
}
