import SwiftUI
import UIKit

struct SettingsScreen: View {
    private static let privacyPolicyURL = URL(string: "https://louisyoong.github.io/swift-taptone-ios/privacy-policy/")!
    private static let termsOfUseURL = URL(string: "https://louisyoong.github.io/swift-taptone-ios/terms-of-use/")!
    private static let supportURL = URL(string: "https://louisyoong.github.io/swift-taptone-ios/support/")!

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette
    @State private var toastMessage: String?

    private var version: String {
        let info = Bundle.main.infoDictionary
        guard
            let version = info?["CFBundleShortVersionString"] as? String,
            let build = info?["CFBundleVersion"] as? String
        else { return "1.0.0 (1)" }
        return "\(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle(strings.t("appearance"))
                VStack(spacing: 0) {
                    SettingsRow(
                        systemImage: settings.darkModeEnabled ? "moon.fill" : "sun.max.fill",
                        title: strings.t("darkMode"),
                        subtitle: settings.darkModeEnabled ? strings.t("darkEnabled") : strings.t("lightEnabled")
                    ) {
                        Toggle("", isOn: $settings.darkModeEnabled)
                            .labelsHidden()
                            .tint(palette.primary)
                    }
                }
                .appCard()
                .padding(4) // Material Card margin

                Spacer().frame(height: 12)

                SettingsRow(systemImage: "globe", title: strings.t("language")) {
                    Menu {
                        Picker(selection: $settings.language) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.label).tag(language)
                            }
                        } label: { EmptyView() }
                    } label: {
                        HStack(spacing: 4) {
                            Text(settings.language.label)
                                .font(AppFont.bodyMedium)
                                .foregroundStyle(palette.onSurface)
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(palette.onSurfaceVariant)
                        }
                    }
                }
                .appCard()
                .padding(4) // Material Card margin

                Spacer().frame(height: 18)
                sectionTitle(strings.t("legal"))
                VStack(spacing: 0) {
                    Button { open(Self.supportURL) } label: {
                        SettingsRow(systemImage: "questionmark.bubble", title: strings.t("support")) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(palette.onSurfaceVariant)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    Divider().overlay(palette.outlineVariant)
                    Button { open(Self.privacyPolicyURL) } label: {
                        SettingsRow(systemImage: "hand.raised", title: strings.t("privacyPolicy")) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(palette.onSurfaceVariant)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    Divider().overlay(palette.outlineVariant)
                    Button { open(Self.termsOfUseURL) } label: {
                        SettingsRow(systemImage: "doc.text", title: strings.t("termsOfUse")) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(palette.onSurfaceVariant)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                }
                .appCard()
                .padding(4) // Material Card margin

                Spacer().frame(height: 18)
                sectionTitle(strings.t("about"))
                VStack(spacing: 0) {
                    SettingsRow(systemImage: "square.grid.2x2.fill", title: strings.t("appName")) {
                        Text("TapTone")
                            .font(.system(size: 14))
                            .foregroundStyle(palette.onSurfaceVariant)
                    }
                    Divider().overlay(palette.outlineVariant)
                    SettingsRow(systemImage: "info.circle", title: strings.t("appVersion")) {
                        Text(version)
                            .font(.system(size: 14))
                            .foregroundStyle(palette.onSurfaceVariant)
                    }
                }
                .appCard()
                .padding(4) // Material Card margin
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
            .readableWidth(680)
        }
        .toast($toastMessage)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppFont.titleMedium)
            .foregroundStyle(palette.onSurface)
            .padding(.bottom, 8)
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:]) { success in
            if !success { toastMessage = strings.t("linkError") }
        }
    }
}

/// Material `ListTile` layout: leading icon, title (+ subtitle), trailing widget.
private struct SettingsRow<Trailing: View>: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    let trailing: () -> Trailing
    @Environment(\.palette) private var palette

    init(systemImage: String, title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundStyle(palette.onSurfaceVariant)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(palette.onSurface)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(palette.onSurfaceVariant)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, subtitle == nil ? 8 : 12)
        .frame(minHeight: subtitle == nil ? 56 : 72)
    }
}
