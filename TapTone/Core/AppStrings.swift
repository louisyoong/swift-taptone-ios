import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case malay = "ms"
    case simplifiedChinese = "zh_CN"
    case traditionalChinese = "zh_TW"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case italian = "it"
    case german = "de"
    case thai = "th"
    case hindi = "hi"
    case arabic = "ar"

    var id: String { rawValue }
    var code: String { rawValue }

    var label: String {
        switch self {
        case .english: "English"
        case .malay: "Bahasa Melayu"
        case .simplifiedChinese: "中文（简体）"
        case .traditionalChinese: "中文（繁體）"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .spanish: "Español"
        case .french: "Français"
        case .italian: "Italiano"
        case .german: "Deutsch"
        case .thai: "ไทย"
        case .hindi: "हिन्दी"
        case .arabic: "العربية"
        }
    }

    var locale: Locale { Locale(identifier: code) }
    var isRightToLeft: Bool { self == .arabic }

    static func from(code: String?) -> AppLanguage {
        let normalized = code == "zh" ? "zh_CN" : code
        return AppLanguage(rawValue: normalized ?? "") ?? .english
    }
}

/// Same lookup rules as the Flutter `AppStrings`: current language, then
/// English, then the key itself. Translations live in Resources/Strings.json
/// (generated 1:1 from the Flutter app's `app_strings.dart`).
struct AppStrings {
    let language: AppLanguage

    private static let table: [String: [String: String]] = {
        guard
            let url = Bundle.main.url(forResource: "Strings", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: data)
        else { return [:] }
        return decoded
    }()

    func t(_ key: String) -> String {
        Self.table[language.code]?[key] ?? Self.table["en"]?[key] ?? key
    }

    func colorName(_ englishName: String) -> String {
        t("color.\(englishName)")
    }
}

private struct StringsKey: EnvironmentKey {
    static let defaultValue = AppStrings(language: .english)
}

extension EnvironmentValues {
    var strings: AppStrings {
        get { self[StringsKey.self] }
        set { self[StringsKey.self] = newValue }
    }
}
