<!-- Copilot / AI agent guidance for CourseMate Flutter app -->
# CourseMate — Copilot Instructions

Purpose: help AI coding agents be immediately productive in this Flutter repository.

- Quick context: This is a Flutter mobile app. Entry point: [lib/main.dart](lib/main.dart#L1-L40) → `SplashScreen`.
- Screen layout: UI code lives under [lib/screens/](lib/screens/) grouped by area: `auth`, `student`, `staff`.
- Build system: standard Flutter tooling. See `pubspec.yaml` for assets and lints.

Build & run (Windows host):
- Install Flutter SDK and run `flutter pub get`.
- Run on a device/emulator: `flutter devices` then `flutter run -d <device-id>`.
- Build APK: `flutter build apk`.
- Run tests: `flutter test` and static analysis: `flutter analyze`.

Project-specific patterns and conventions:
- Navigation uses imperative `Navigator.push` / `Navigator.pushReplacement` with `MaterialPageRoute` (example: [lib/screens/auth/splash_screen.dart](lib/screens/auth/splash_screen.dart#L1-L80)). Follow this pattern rather than switching to named routes.
- Top-level pages are often `StatefulWidget`s with a `_currentIndex` + `_pages` list for `BottomNavigationBar` (example: [lib/screens/student/student_home_screen.dart](lib/screens/student/student_home_screen.dart#L1-L200)). Add new tabs by appending to `_pages` and `BottomNavigationBarItem`.
- Visual styling: gradients and hard-coded color hexes are used widely (see AppBar gradient in `StudentHomeScreen`). Reuse colors exactly when matching existing visuals.
- Assets: declared in `pubspec.yaml` (e.g. `assets/images/logo.png`). Update `pubspec.yaml` when adding assets.
- Linting: `flutter_lints` is enabled; keep code style compatible with Dart/Flutter idioms and run `flutter format .` after edits.

Integration cautions:
- There are native Android/iOS directories already; avoid renaming Android package or iOS bundle identifiers without also updating any platform configs (Firebase, Google services) that may exist under `android/` and `ios/`.
- The repository currently has minimal pubspec dependencies. If adding packages, update `pubspec.yaml` and run `flutter pub get`.

Where to make typical changes:
- New screens: add under `lib/screens/<area>/` and follow existing file-naming and class naming patterns (e.g. `StudentHomeScreen`, `TimetableHomeScreen`).
- Shared widgets: follow local placement (if none, add a `lib/widgets/` folder and keep usages import-relative).

Small code examples (follow style exactly):
- Push a new screen:
  ```dart
  Navigator.push(context, MaterialPageRoute(builder: (_) => NewScreen()));
  ```
- Bottom nav pattern (follow `_pages` and `_currentIndex`) — see [lib/screens/student/student_home_screen.dart](lib/screens/student/student_home_screen.dart#L1-L200).

If this file already exists, merge preserving any custom notes. Keep guidance short and concrete — reference the specific files above rather than generic Flutter docs.

If anything is unclear or you want additional examples (e.g., how to add a network service, or where to centralize theme/colors), say which area to expand.
