# Hotel Management System

An Android/iOS Flutter project for the ANAS TECHNOLOGIES internship assignment.

**Current stage: empty project initialization.** The app opens a minimal placeholder screen. Rooms, guests, bookings, persistence, and check-in/check-out are planned and have not been implemented.

## Project identity

| Setting | Value |
| --- | --- |
| Display name | Hotel Management System |
| Dart package | `hotel_management_system` |
| Android application ID / namespace | `com.mudasir.hotelmanagementsystem` |
| iOS app bundle identifier | `com.mudasir.hotelmanagementsystem` |
| Platforms | Android and iOS only |
| Scaffold toolchain | Flutter 3.47.4 stable, Dart 3.13.3 |

## Setup and run

Use Flutter 3.47.4 or a compatible SDK satisfying `pubspec.yaml`. Android requires the Android SDK and a compatible JDK; iOS requires macOS and Xcode. This scaffold was generated with Android SDK 37 and Xcode 27 available.

```sh
flutter pub get
flutter analyze
flutter run -d <android-or-ios-device-id>
```

For physical iOS devices, select your local signing team in Xcode before running. Personal development-team settings and credentials are not committed. Android release signing still uses the generated debug-signing fallback and must be configured before distribution.

## Native build checks

```sh
flutter build apk --debug
flutter build ios --simulator --debug
```

Dependency resolution, static analysis, native identity checks, and ignore checks passed. Native builds and runtime launch remain unverified. The commands above are available checks for the empty scaffold. Release APK delivery, installed-app verification, screenshots, business-rule tests, and persistence tests belong to later phases. No business tests exist at this stage.

## Structure

- `lib/main.dart`: application entry point.
- `lib/app/app.dart`: minimal Flutter application.
- `android/`, `ios/`: platform projects with matching native identity.

Add feature/domain/data folders when their implementation phase starts.

Generated files, caches, build packages, logs, local environment files, and signing credentials are ignored. Source, the app dependency lockfile, native configuration, and Gradle wrapper files remain trackable.
