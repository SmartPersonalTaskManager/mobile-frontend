# sptm

SPTM is a Flutter-based mobile frontend for the OOAD project. It provides the user-facing app experience and integrates with the project's backend APIs and shared assets. This README is a practical manual for getting the app running, understanding the structure, and contributing safely.

## Table of Contents

- [Project Overview](#project-overview)
- [App Features and Usage](#app-features-and-usage)
- [Tech Stack](#tech-stack)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Project Structure](#project-structure)
- [Common Workflows](#common-workflows)
- [Running and Debugging](#running-and-debugging)
- [Testing and Quality](#testing-and-quality)
- [Build and Release](#build-and-release)
- [Assets and Localization](#assets-and-localization)
- [Troubleshooting](#troubleshooting)

## Project Overview

This repository contains the mobile frontend built with Flutter. It targets Android, iOS, and optionally desktop/web platforms depending on build configuration. The codebase is organized by Flutter conventions, with platform-specific folders for native integration and a shared Dart UI layer.

Primary goals:

- Provide a clean, responsive user experience
- Keep UI logic modular and testable
- Integrate with backend APIs reliably
- Support multiple platforms with a shared codebase

## App Features and Usage

This section describes what the app does from a user perspective and how core flows work.

### Authentication and Account Access

- Users can register a new account and log in with email and password.
- A "forgot password" flow allows password resets from the login screen.
- Sessions are required to access personal tasks, missions, and insights.

### Dashboard and Task Overview

- The dashboard shows your active tasks grouped by urgency and importance.
- Tasks appear with title, mission/sub-mission labels, context tags, and due dates.
- A quick-add flow lets you create tasks directly from the dashboard.
- Tasks can be toggled complete/incomplete from the list with immediate visual updates.

### Task Creation and Editing

- Create tasks with title, description, due date, urgency, importance, and context.
- Assign tasks to a mission or sub-mission when applicable.
- Edit task details at any time, including due dates and context.
- Delete tasks you no longer need.

### Task Details and Checklist

- Each task has a dedicated detail view for rich editing.
- Add descriptive notes to capture requirements or reminders.
- Create a checklist to break the task into smaller steps.
- Archive a task from the detail view when it is no longer active.

### Missions and Sub-Missions

- Missions represent larger goals; sub-missions break them into smaller milestones.
- A missions list shows all missions and sub-mission counts.
- Each mission detail page shows linked tasks for each sub-mission.
- Tasks can be created, updated, and completed within a sub-mission context.

### Calendar and Due Dates

- A calendar view lets users browse tasks by day.
- Selecting a date shows all tasks due on that day.
- Quick toggles let users mark tasks done without leaving the calendar.

### Inbox, Notifications, and Follow-Ups

- Notifications include due-soon reminders and weekly insights.
- Inbox tasks can be assigned details like due date, urgency, and context.
- Users can act on a notification to open and update the related task.

### Insights and Progress

- Weekly insights summarize completed tasks and mission progress.
- Progress views help spot momentum and backlog areas.

### Archive Management

- Archived tasks are hidden from daily views.
- The archive screen allows restoring or permanently deleting tasks.

### Settings and Profile

- Settings provide access to profile information and app actions.
- Use settings to review account data and sign out when needed.

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
