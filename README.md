# TapTone (Swift / SwiftUI)

Native iOS port of the Flutter app in `../TapTone`. Same screens, same logic, same strings.

## Open & run
1. Open `TapTone.xcodeproj` in Xcode 26 or later. The deployment target is iOS 26, same as the Flutter build, and it uses native Liquid Glass.
2. Pick your team under *Signing & Capabilities* if needed. It's already set to `M9VG7M352C`.
3. Run it on a device. The Simulator has no camera, so the Detect and Simulate tabs will say "Camera unavailable".

The project uses Xcode folder-synced groups, so any file you add under `TapTone/` is picked up automatically.

## Flutter → Swift map
| Flutter | Swift |
|---|---|
| `main.dart` `ColorAssistApp`, `ThemeSettingsScope`, `OnboardingGate` | `App/TapToneApp.swift`, `Core/AppSettings.swift` |
| `TapToneShell` + `liquid_glass_nav_bar.dart` | `App/TapToneShell.swift`, `Components/LiquidGlassNavBar.swift` |
| `OnboardingScreen` | `Features/Onboarding/OnboardingScreen.swift` |
| `ColorAssistScreen` (image_picker + ColorFiltered) | `Features/Assist/ColorAssistScreen.swift`, `Components/ImagePickers.swift`, `Core/ColorFilters.swift` |
| `ColorDetectorScreen` (camera stream, centre sampling) | `Features/Detect/ColorDetectorScreen.swift`, `Core/CameraController.swift` |
| `DetectedColor` + 142 named colors | `Core/DetectedColor.swift` |
| `SimulationScreen` | `Features/Simulate/SimulationScreen.swift` |
| `color_test.dart` | `Features/ColorTest/*` |
| `SettingsScreen` (url_launcher, package_info) | `Features/Settings/SettingsScreen.swift` |
| `app_strings.dart` (13 languages) | `Core/AppStrings.swift` + `Resources/Strings.json` |
| `ThemeData` / `ColorScheme.fromSeed(0xFF126A63)` | `Core/Theme.swift` (exact M3 tonal-spot colors) |

## Notes
- The bundle ID (`com.example.colorVisionSimulator`) and version (1.2.0) match the Flutter app, so this build can ship as an App Store update. Raise the build number before uploading.
- Saved settings carry over. Flutter's `shared_preferences` stored them as `flutter.<key>` in UserDefaults, and this app reads those keys as a fallback.
- Color matrices run with Core Image color management turned off, so they work on raw sRGB values the same way Flutter's `ColorFilter.matrix` does.
- Plates use a port of Dart's seeded `Random`, so dot layouts and kid-answer order follow the same seeds.
- To regenerate `Strings.json` after editing `app_strings.dart`, convert the `_translations` map to JSON with the same structure: language code → key → text.
