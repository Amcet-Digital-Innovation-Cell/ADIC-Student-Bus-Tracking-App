
# Annai Mira College Bus Tracking App 🚌

A mobile-first real-time college bus tracking and route management application built with **Flutter** and **Dart**. This application allows students to view active bus routes, check ordered stops dynamically for morning and evening travel modes, and track bus locations in real-time.

---

## 📋 Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Flutter Installation & Environment Setup](#2-flutter-installation--environment-setup)
3. [Android Command-Line Tools Configuration](#3-android-command-line-tools-configuration)
4. [Project Folder Structure](#4-project-folder-structure)
5. [Getting Started & Dependencies](#5-getting-started--dependencies)
6. [Running the App on an Emulator](#6-running-the-app-on-an-emulator)
7. [Important Notes](#7-important-notes)

---

## 1. Prerequisites

Before you begin, ensure your development machine meets the following requirements:

- **Operating System:** Windows 10/11, macOS, or Linux.
- **Hardware:** Minimum 8GB RAM (16GB recommended) with hardware virtualization enabled in BIOS.
- **Tools:** Git, Android Studio (or VS Code), and the Android SDK.

---

## 2. Flutter Installation & Environment Setup

### Step A: Download Flutter SDK

1. Visit the official Flutter installation guide and download the latest stable release for your OS.
   - **URL:** https://docs.flutter.dev/get-started/install
2. Extract the downloaded archive and place the files in a suitable location:
   - Windows example: `C:\src\flutter`
   - macOS/Linux example: `/Users/<username>/development/flutter`

### Step B: Configure Environment Variables (PATH)

To run Flutter commands from any terminal, add the Flutter `bin` directory to your `PATH`.

#### Windows
1. Open **Environment Variables** from Windows search.
2. Click **Edit the system environment variables**.
3. Click **Environment Variables...**.
4. Under **User variables** or **System variables**, select `Path` and click **Edit**.
5. Click **New** and add `C:\src\flutter\bin`.
6. Click **OK** and restart your terminal.

#### macOS / Linux
1. Open your shell profile file, such as `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`.
2. Add the following line, replacing the path with your Flutter installation location:

```bash
export PATH="$PATH:/Users/<username>/development/flutter/bin"
```

3. Save the file and reload your terminal profile:

```bash
source ~/.zshrc
```

---

## 3. Android Command-Line Tools Configuration

To build and run the app on Android emulators, configure the Android SDK and command-line tools.

1. Install Android Studio from https://developer.android.com/studio.
2. Open Android Studio and go to **Tools > SDK Manager**.
3. In **SDK Platforms**, ensure at least one Android SDK version is selected (for example, Android 14.0 / API 34).
4. In **SDK Tools**, enable for LIKE this path (C:\Users\lokesh\AppData\Local\Android\Sdk):
   - Android SDK Command-line Tools (latest)
   - Android SDK Build-Tools
5. Click **Apply** to install the chosen tools.

### Accept Android Licenses

Run the following command in a terminal:

```bash
flutter doctor --android-licenses
```

### Verify Your Setup

Run:

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor` before continuing.

---

## 4. Project Folder Structure

The project follows a clean, modular structure separating models, screens, and network services:

```text
lib/
  main.dart
  models/
    bus_model.dart          # Data entities for routes and stops
  screens/
    home_screen.dart        # Main dashboard with morning/evening mode controls
    tracking_screen.dart    # Live map tracking screen
    stops_bottom_sheet.dart # Ordered stop list for selected routes
  services/
    api_service.dart        # API client and backend communication
pubspec.yaml                # Flutter dependencies and assets
README.md                   # Project documentation
```

## 4.1 How the App Works

The app is structured so the UI, data models, and backend calls are separated for clarity.

- `main.dart` — app entry point. Registers routes and bootstraps `SplashScreen` → `HomeScreen`.
- `screens/splash_screen.dart` — small startup splash (seen on app launch).
- `screens/home_screen.dart` — lists available bus routes (searchable). Loads routes from `ApiService.fetchRoutes()` and falls back to a built-in `fallbackRoutes` list when the backend is unavailable. Shows route cards with origin/destination preview, stop count, and `Stops` / `Track` actions.
- `screens/stops_bottom_sheet.dart` — modal bottom sheet that displays the ordered list of stops. `BusRouteModel.getStops(isEveningReturn)` reverses the stop order for evening/return mode.
- `screens/tracking_screen.dart` — map screen using `flutter_map` with OpenStreetMap tiles. It polls `ApiService.fetchVehicleTracking()` every 10 seconds to update the bus marker and shows status, last-updated time, and quick actions (recenter, refresh).
- `models/bus_model.dart` — `BusRouteModel` holds route metadata and stop lists; provides `getStops()` to return morning or evening order.
- `models/vehicle_tracking_model.dart` — model for live vehicle tracking payload (latitude, longitude, speed, status, updatedAt).
- `services/api_service.dart` — HTTP client helpers. Current base URL: `https://bus-tracking-backend-8s.onrender.com`. Functions:
  - `fetchRoutes()` — GETs the routes JSON, parses payloads, and returns a `List<BusRouteModel>`. Returns an empty list on timeout or non-200 responses so the UI may fall back to local routes.
  - `fetchVehicleTracking(routeId, mode)` — GETs the tracking endpoint `/api/routes/<routeId>/tracking?mode=<morning|evening>` and returns a `VehicleTrackingModel` (or `null` on errors/timeouts).

Key behaviors to know:

- Travel mode (morning / evening) is derived from the current time (`hour >= 12` is treated as evening). Screens pass `isEveningReturn` to show reversed stops and request tracking with a `mode` query parameter.
- Route list search filters by route name, bus number, and stop names (client-side filtering).
- Tracking shows a single bus marker, recent status text, and gracefully falls back to the last-known location or a static initial location when live data is unavailable.
- Map tiles are provided by OpenStreetMap (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) via the `flutter_map` package.

If you update API contract shapes, update `models/` and `ApiService` parsing accordingly.

## 4.2 Where to Make Changes

- Update data models in `lib/models/bus_model.dart` when route or stop structures change.
- Modify UI screens in `lib/screens/` to change app layout or user interactions.
- Adjust network requests in `lib/services/api_service.dart` if the API changes.

---

## 5. Getting Started & Dependencies

1. Clone the repository:

```bash
git clone <repository-url>
cd fluttermobileapp
```

2. Install dependencies:

```bash
flutter pub get
```

3. Verify the project setup:

```bash
flutter pub outdated
flutter doctor
```

---

## 6. Running the App on an Emulator

### Launch an Android Emulator

1. Open Android Studio and go to **Tools > Device Manager**.
2. Create a virtual device (for example, Pixel 6 with Android API 34).
3. Start the emulator using the **Play** button.

Alternatively, launch an emulator from the terminal:

```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

### Run the Application

With the emulator running, run:

```bash
flutter run
```

### Hot Reload / Hot Restart

While the app is running in the terminal:

- Press `r` for Hot Reload
- Press `R` for Hot Restart

---

## 7. Important Notes

- This README is designed for easy understanding by anyone copying this folder.
- Open the project root in VS Code or Android Studio to edit and run the app.
- There is no `.env` file in this workspace by default.
- If the app requires API keys or tokens, store them securely and do not commit them to source control.
- Use `flutter clean` to remove build artifacts before rebuilding.

## 7.1 Quick Troubleshooting

- If `flutter doctor` reports missing tools, install the missing SDK components or accept licenses.
- If the emulator does not start, confirm the virtual device exists in Android Studio Device Manager.
- If the app fails to build, run `flutter clean` and then `flutter pub get` before retrying.
- If map or location data is unavailable, verify the API service URL and network connectivity.

---

## Contribution

## 8. Additional Files & Important Paths

This project contains platform, build, and generated folders in addition to the app sources. Important top-level paths:

- `android/`: Native Android project and Gradle build files. Modify `android/app/src/main/AndroidManifest.xml` and Gradle settings here.
- `ios/`: iOS Xcode project and configuration. Update `ios/Runner/Info.plist` for iOS-specific keys and entitlements.
- `lib/`: Main Dart/Flutter source files (models, screens, services).
- `assets/`: Static assets bundled with the app (images, fonts, JSON). See `pubspec.yaml` for declared assets.
- `build/`: Generated build artifacts (do not commit).
- `test/`: Unit and widget tests. See `flutter test` to run them.
- `pubspec.yaml`: Dependency declarations, fonts, assets, and other Flutter metadata.
- `local.properties`: Machine-specific Android SDK locations (not committed).

## 9. Environment Variables & API Keys

This app may require API keys (for maps, backend, etc.). Recommended approaches:

- Use a local, untracked file or use a package such as `flutter_dotenv` to load keys from `.env`.
- For Android, add map API keys to `android/app/src/main/AndroidManifest.xml` as `<meta-data>` or use gradle `manifestPlaceholders`.
- For iOS, add keys to `ios/Runner/Info.plist` or configure at runtime from a secure source.

Example (Google Maps API key) AndroidManifest.xml snippet:

```xml
<application>
  <meta-data android:name="com.google.android.geo.API_KEY"
             android:value="YOUR_API_KEY_HERE"/>
</application>
```

DO NOT commit API keys to source control. Add them to `.gitignore` or use CI secret management.

## 10. Running Tests & CI

- Run unit and widget tests:

```bash
flutter test
```

- For integration tests, use `flutter drive` or the integration_test package (see `test_driver/` or `integration_test/` if present).
- Add `flutter analyze` and `flutter test` to CI pipelines to enforce static checks and tests.

## 11. Formatting & Linting

- Format the codebase:

```bash
flutter format .
```

- Run static analysis:

```bash
flutter analyze
```

Consider enabling `analysis_options.yaml` rules and adding a `lint` step to CI.

## 12. Developer Tips

- To run on a physical Android device, enable developer options and USB debugging, then run `flutter run` with the device connected.
- If using Google Maps, enable the relevant APIs in Google Cloud Console and restrict the key to your app's package name and SHA-1 (Android).
- If you need per-environment configuration (dev/stage/prod), maintain separate `.env` files and load the correct one at build time.

Contributions are welcome. Improve documentation, add features, fix bugs, or update UI/UX behavior as needed.
