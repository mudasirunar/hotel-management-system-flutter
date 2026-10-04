<div align="center">

# Hotel Management System

A mobile workspace for managing rooms, guests, reservations, and daily hotel operations.

![Flutter](https://img.shields.io/badge/Flutter-3.47.4-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13.3-0175C2?logo=dart&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-374151)
![Status](https://img.shields.io/badge/Status-In%20Development-D97706)

</div>

## Overview

Hotel Management System is a Flutter application designed to help hotel staff organize room inventory, maintain guest records, manage reservations, and handle arrivals and departures. The planned experience supports offline use and adapts to both phones and tablets.

## Product Scope

The project is being developed around the following capabilities:

| Area | Capabilities |
| --- | --- |
| Dashboard | Total rooms, available and occupied rooms, guest count, and active bookings |
| Rooms | Add, view, edit, and safely delete rooms; nightly prices in PKR; current occupancy |
| Guests | Manage names, contact details, CNIC, and addresses |
| Reservations | Select dates, assign rooms and guests, and check room availability |
| Check-in / Check-out | Record arrivals and departures with automatic occupancy updates |
| Search & Filters | Search rooms and guests, and filter rooms by occupancy |
| Appearance | System, Light, and Dark themes with a locally saved preference |
| Adaptive Layouts | Comfortable layouts for Android/iOS phones and tablets |

## Architecture

The application separates feature screens, application state, business rules, and local storage. Shared validation protects record relationships, prevents conflicting reservations, and preserves booking history. Room occupancy follows check-in and check-out activity.

Local persistence uses [Hive Community Edition](https://pub.dev/packages/hive_ce) with a versioned snapshot. Saves complete before updated records appear in the interface. Appearance preferences are stored separately from hotel records.

Storage is designed for a modest, single-device dataset and is not encrypted.

## Getting Started

### Prerequisites

- Flutter **3.47.4** with Dart **3.13.3**, or a compatible Flutter SDK satisfying the constraints in `pubspec.yaml`.
- **Android:** Android SDK, a compatible JDK, and an emulator or physical device.
- **iOS:** macOS, Xcode, and an iOS simulator or physical device.

### Installation

```sh
git clone https://github.com/mudasirunar/hotel-management-system-flutter.git
cd hotel-management-system-flutter
flutter pub get
```

### Run the App

List the available devices, then launch on an Android or iOS target:

```sh
flutter devices
flutter run -d <device-id>
```

For a physical iOS device, open `ios/Runner.xcworkspace` in Xcode and select your own development team under **Signing & Capabilities** before running.

## Build

### Android Debug APK

```sh
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### iOS Simulator

```sh
flutter build ios --simulator --debug
```

Release signing must be configured before distributing the app. The Android scaffold currently uses Flutter's default debug-signing fallback for release builds.

## Project Structure

```text
lib/
├── main.dart                 # Application entry point
├── app/                      # App composition and startup recovery
├── features/                 # Feature screens and presentation
├── shared/                   # Shared formatting and UI helpers
├── application/              # State controller and serialized mutations
├── domain/
│   ├── models/               # Rooms, guests, bookings, and calendar dates
│   ├── services/             # Validation and business rules
│   └── repositories/         # Persistence contract
└── data/local/               # Hive adapter and versioned snapshot codec
test/                         # Domain, storage, state, and startup tests
integration_test/             # Native storage smoke test
android/                      # Android platform project
ios/                          # iOS platform project
pubspec.yaml                  # Dependencies and app version
pubspec.lock                  # Resolved dependency versions
analysis_options.yaml         # Dart analysis rules
```

Business rules and persistence are separate from the interface. Feature screens use the shared application controller; appearance preferences have a separate controller and local store.

## App Identity

| Setting | Value |
| --- | --- |
| Display name | Hotel Management System |
| Dart package | `hotel_management_system` |
| Android application ID | `com.mudasir.hotelmanagementsystem` |
| iOS bundle identifier | `com.mudasir.hotelmanagementsystem` |
| Supported platforms | Android and iOS |

## Code Quality

Run static analysis and the automated suite:

```sh
flutter analyze
flutter test
```

The native storage smoke test is available for an Android emulator/device or iOS simulator/device:

```sh
flutter test integration_test/storage_smoke_test.dart -d <device-id>
```

Host tests and native smoke tests cover different environments. Validate core workflows and persistence on the target device before distributing a build.
