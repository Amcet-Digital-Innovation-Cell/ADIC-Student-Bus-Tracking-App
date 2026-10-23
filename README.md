# AMCET Transport App

A Flutter mobile application for college bus tracking, student login, and live route monitoring. The app is designed for students to log in, select their route, view assigned stops, and track the bus location in real time.

## Features

- Student login and registration flow
- Bus route selection and assigned stop details
- Live vehicle tracking with map view
- Morning/evening route-stop logic
- Theme toggle support
- Mobile-friendly responsive UI
- Secure local session handling with Flutter secure storage

## Tech Stack

- Flutter
- Dart
- HTTP for backend calls
- Flutter Map for route tracking
- Mobile Scanner for QR/student ID scan
- Shared Preferences + Secure Storage for local session state
- Geolocator for device location support

## App Overview

This project uses a Render-hosted backend API and is configured for Android mobile app execution. The central app entry point is in `lib/main.dart`, and the user flows are organized under `lib/screens/`.

The app currently connects to:

- Backend base URL: `https://busappbackend.onrender.com`
- Login API: `/api/students/login`
- Public bus API: `/api/public/buses`

## Project Structure

```text
trackapp/
├── android/                 # Android project configuration
├── ios/                     # iOS project configuration
├── lib/
│   ├── main.dart            # App startup and route registration
│   ├── models/              # Route and tracking models
│   ├── screens/             # Login, splash, home, tracking, and UI views
│   └── services/            # API logic and backend calls
├── assets/                  # App images and icons
├── test/                    # Widget and API tests
├── analysis_options.yaml    # Linting configuration
├── pubspec.yaml             # Flutter dependencies and assets
├── README.md                # Project documentation
├── .gitignore
└── ...
```

## Prerequisites

Before running the app, install the following:

- Flutter SDK (stable channel)
- Android Studio
- Android SDK / Android Emulator
- VS Code or Android Studio for editing
- A physical Android device or running Android emulator

### Verify Flutter installation

```bash
flutter --version
flutter doctor
```

If Android tools are not configured, complete the Android setup and accept licenses:

```bash
flutter doctor --android-licenses
```

## Setup Instructions

1. Clone the repository

```bash
git clone <repository-url>
cd trackapp
```

2. Install dependencies

```bash
flutter pub get
```

3. Check the environment

```bash
flutter doctor
```

Resolve any Android or SDK warnings before launching the app.

## Run the App on Android

### Option 1: Android Emulator

1. Open Android Studio
2. Go to Device Manager
3. Create or start an emulator
4. Run:

```bash
flutter devices
flutter run
```

### Option 2: Physical Android Device

1. Enable Developer Options on your Android phone
2. Enable USB debugging
3. Plug in the device via USB
4. Confirm the device shows up:

```bash
flutter devices
```

5. Launch the app:

```bash
flutter run
```

### Option 3: Run on a specific device

```bash
flutter run -d <device_id>
```

## Common Commands

```bash
flutter clean
flutter pub get
flutter run
flutter test
```

## Hot Reload

While the app is running, use:

- `r` for hot reload
- `R` for hot restart
- `q` to quit

## Notes

- The app is configured for Android mobile usage and uses Android-specific setup.
- The project currently depends on a live backend service, so internet access is required for login and tracking data.
- If the app shows API or connection issues, confirm the backend is reachable and the device/emulator has network access.
- If Android licenses are not accepted, run `flutter doctor --android-licenses` and accept the prompts.

## Troubleshooting

### Flutter doctor shows Android issues

```bash
flutter doctor --android-licenses
flutter doctor
```

### Device not detected

```bash
adb devices
```

If the device is not visible, reconnect the USB cable, enable USB debugging, or restart the emulator.

### App fails to launch

Try:

```bash
flutter clean
flutter pub get
flutter run
```

## License

This project is for internal college transport app usage unless otherwise specified.

## Contact

For setup assistance or app maintenance, contact the project owner or team responsible for the application.

## Additional Notes

- There is no `.env` file in this workspace by default.
- If the app requires API keys or tokens, store them securely and do not commit them to source control.
- Use `flutter clean` to remove build artifacts before rebuilding.
- `local.properties` is machine-specific and should not be committed to source control.

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

## 13. Contributions

Contributions are welcome. Improve documentation, add features, fix bugs, or update UI/UX behavior as needed.
