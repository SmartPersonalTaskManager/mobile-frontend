# sptm

SPTM is a Flutter-based mobile frontend for the OOAD project. It provides the user-facing app experience and integrates with the project's backend APIs and shared assets. This README is a practical manual for getting the app running, understanding the structure, and contributing safely.

## Table of Contents

- Project Overview
- Features at a Glance
- Tech Stack
- Requirements
- Quick Start
- Environment Configuration
- Project Structure
- Common Workflows
- Running and Debugging
- Testing and Quality
- Build and Release
- Assets and Localization
- Troubleshooting
- Contributing
- License

## Project Overview

This repository contains the mobile frontend built with Flutter. It targets Android, iOS, and optionally desktop/web platforms depending on build configuration. The codebase is organized by Flutter conventions, with platform-specific folders for native integration and a shared Dart UI layer.

Primary goals:

- Provide a clean, responsive user experience
- Keep UI logic modular and testable
- Integrate with backend APIs reliably
- Support multiple platforms with a shared codebase

## Features at a Glance

- Flutter UI with platform-specific builds
- Asset management for images and other resources
- API integration layer (see `API_DOCUMENTAION.md`)
- Configurable build targets for Android/iOS and other platforms

## Tech Stack

- Flutter 3.38.5
- Dart 3.10.4
- DevTools 2.51.1
- Platform targets: Android, iOS (with optional desktop/web folders present)

## Requirements

Install the following tools before running the app:

- Flutter SDK (version noted above)
- Android Studio and Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)
- CocoaPods (for iOS dependencies)

Optional:

- Chrome (for web builds)
- Desktop toolchains for macOS/Windows/Linux if you plan to build those targets

## Quick Start

1. Install Flutter and ensure it is on your PATH.
2. Clone this repository and open it in your IDE.
3. Fetch dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Environment Configuration

The app may require environment-specific settings (API base URL, feature flags, etc.). If your team uses local configuration files or flavors, document them here. Typical options include:

- Dart defines: `--dart-define=KEY=VALUE`
- Flutter flavors for dev/staging/prod
- Platform-specific configuration in `android/` and `ios/`

If you are unsure, check with your team or review `API_DOCUMENTAION.md` for backend expectations.

## Project Structure

Key folders:

- `lib/`: Main Dart source code (UI, state, services, models)
- `assets/`: Images, fonts, and other bundled resources
- `android/`: Android native project
- `ios/`: iOS native project
- `web/`, `macos/`, `windows/`, `linux/`: Optional platform targets
- `API_DOCUMENTAION.md`: API reference for backend integration

## Common Workflows

### Run on a Specific Device

List devices:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <device_id>
```

### Hot Reload and Hot Restart

- Hot reload: `r` in the running terminal
- Hot restart: `R` in the running terminal

## Running and Debugging

- Use Flutter DevTools for widget inspection and performance profiling.
- For Android, use Android Studio logcat.
- For iOS, use Xcode console logs.

## Testing and Quality

Recommended testing commands:

```bash
flutter analyze
flutter test
```

Consider adding integration tests if user flows are critical.

## Build and Release

### Android

```bash
flutter build apk
flutter build appbundle
```

### iOS

```bash
flutter build ios
```

Use Xcode to archive and distribute when targeting the App Store.

## Assets and Localization

- Add assets under `assets/` and register them in `pubspec.yaml`.
- If localization is used, keep ARB files in a dedicated folder and update generated localization files accordingly.

## Troubleshooting

- Run `flutter doctor` to validate setup.
- If iOS pods fail, run `pod install` in `ios/` (or `pod repo update` if needed).
- If builds fail after dependency changes, try `flutter clean` followed by `flutter pub get`.

## Contributing

1. Create a feature branch.
2. Keep changes scoped and well-tested.
3. Run formatting and tests before opening a PR.
4. Document any new environment variables or build steps in this README.

## License

Add license information here if applicable.
