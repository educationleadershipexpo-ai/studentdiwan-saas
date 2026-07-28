# Parent App — Complete Setup Guide

## 1. Install Flutter

```bash
# Windows — download from https://flutter.dev/docs/get-started/install/windows
# Then add to PATH and verify:
flutter doctor
```

Required: Flutter 3.22+, Dart 3.4+, Android Studio, Android SDK

## 2. Generate Platform Files

Run this ONCE inside the parent-app folder to generate android/ and ios/ folders:

```bash
cd parent-app
flutter create . --platforms=android,ios --org=com.studentdiwan
```

## 3. Install Dependencies

```bash
flutter pub get
```

## 4. Set Up Firebase (for Push Notifications)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Connect to your Firebase project
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This creates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Then update main.dart to pass the options:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## 5. Configure Android for Biometrics

In `android/app/src/main/AndroidManifest.xml` add:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

## 6. Generate App Icon

Place your 1024×1024 PNG icon at `assets/icons/app_icon.png`, then:

```bash
flutter pub run flutter_launcher_icons
```

## 7. Generate Splash Screen

Place your logo PNG at `assets/images/splash_logo.png` (white on transparent), then:

```bash
flutter pub run flutter_native_splash:create
```

## 8. Run the App

### Android Emulator (default — points to 10.0.2.2:3001)
```bash
flutter run
```

### Physical Android Device (same Wi-Fi as your dev machine)
```bash
# Find your machine's IP first: ipconfig
flutter run --dart-define=API_URL=http://192.168.1.X:3001
```

### Production
```bash
flutter run --dart-define=ENV=prod --dart-define=API_URL=https://api.yourschool.com
```

## 9. Build Release APK

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for Play Store)
flutter build apk --release --dart-define=ENV=prod --dart-define=API_URL=https://api.yourschool.com

# App Bundle (preferred for Play Store)
flutter build appbundle --release --dart-define=ENV=prod --dart-define=API_URL=https://api.yourschool.com
```

## 10. Backend — Start the API Server

```bash
cd diwan-main
npm run dev:api   # starts server.ts on port 3001
```

Or for production:
```bash
npm run build
node dist/server.js
```

---

## Folder Structure

```
parent-app/
├── lib/
│   ├── main.dart                 ← App entry point
│   ├── core/
│   │   ├── api_client.dart       ← Dio HTTP client
│   │   ├── biometric_service.dart← Fingerprint/Face login
│   │   ├── constants.dart        ← API entity names & storage keys
│   │   ├── environment.dart      ← Dev/prod URL config
│   │   ├── fcm_service.dart      ← Push notifications
│   │   ├── offline_cache.dart    ← Hive persistent cache
│   │   ├── router.dart           ← GoRouter navigation
│   │   └── theme.dart            ← Colors & typography
│   ├── models/models.dart        ← All data models
│   ├── providers/
│   │   ├── auth_provider.dart    ← Login state (Riverpod)
│   │   └── data_provider.dart    ← All data fetching (cached)
│   ├── screens/                  ← 24 screens
│   └── widgets/common_widgets.dart
├── assets/
│   ├── icons/app_icon.png        ← 1024×1024 app icon (ADD THIS)
│   ├── images/splash_logo.png    ← Splash logo (ADD THIS)
│   └── fonts/                    ← SF Pro Display fonts (ADD THESE)
├── pubspec.yaml
├── API_CONTRACT.md               ← Full API documentation
└── SETUP.md                      ← This file
```
