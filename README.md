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

> **Development status:** The Android and iOS projects are initialized with a minimal app screen. The features below are planned and are not yet implemented.

## Planned Features

| Area | Capabilities |
| --- | --- |
| Dashboard | Total rooms, available and occupied rooms, guest count, and active bookings |
| Rooms | Add, edit, and delete rooms; manage room numbers, types, nightly rates, and occupancy |
| Guests | Manage names, contact details, CNIC, and addresses |
| Reservations | Select dates, assign rooms and guests, and check room availability |
| Check-in / Check-out | Record arrivals and departures with automatic occupancy updates |
| Search & Filters | Find rooms and guests, and filter rooms by status |
| Local Storage | Keep hotel records available offline and across app restarts |
| Adaptive Layouts | A consistent interface for Android/iOS phones and tablets |

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
└── app/
    └── app.dart              # Flutter application
android/                      # Android platform project
ios/                          # iOS platform project
pubspec.yaml                  # Dependencies and app version
pubspec.lock                  # Resolved dependency versions
analysis_options.yaml         # Dart analysis rules
```

Business rules, persistence, and feature screens will be introduced as development progresses, keeping application logic separate from the interface.

## App Identity

| Setting | Value |
| --- | --- |
| Display name | Hotel Management System |
| Dart package | `hotel_management_system` |
| Android application ID | `com.mudasir.hotelmanagementsystem` |
| iOS bundle identifier | `com.mudasir.hotelmanagementsystem` |
| Supported platforms | Android and iOS |

## Code Quality

Run static analysis with:

```sh
flutter analyze
```

Dependency resolution and static analysis passed during initialization. Native builds and device execution are pending verification. Automated tests will be added with the core functionality.
