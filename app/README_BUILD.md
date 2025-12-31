# VitalGate Build & Run Instructions

## 1. Prerequisites
- Flutter SDK installed
- Android Studio / Android SDK installed (for Android)
- Connected Android Device or Emulator

## 2. Configuration Locations
- **Firebase Configuration**: 
    - Place `google-services.json` in: `android/app/google-services.json`
- **App Logo/Icon**:
    - Update icons in: `android/app/src/main/res/` (mipmap folders) or use `flutter_launcher_icons` package.

## 3. Running the App
To run the app on a connected device:

```bash
flutter run
```

## 4. Building for Release (Android APK)
To build a release APK for manual installation:

```bash
flutter build apk --release
```
The output APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## 5. Visual Testing on Device
1. Connect your Android device via USB.
2. Enable "Developer Options" and "USB Debugging" on your device.
3. Run `flutter run --release` to install a performance-optimized version on your phone.
