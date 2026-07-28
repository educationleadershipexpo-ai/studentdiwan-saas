# Diwan Parent Portal — Flutter App

A Flutter mobile app for parents/guardians to monitor their child's school life in real time.  
Consumes the existing **Node.js + MySQL** backend — no backend changes required.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10+ (Dart 3.0+) |
| State | Riverpod (StateNotifierProvider + FutureProvider.family) |
| Navigation | GoRouter |
| HTTP | Dio with auth interceptor |
| Storage | SharedPreferences (token + user session) |
| Fonts | Google Fonts — Inter |
| Charts | fl_chart |
| Push Notifications | Firebase Cloud Messaging |

---

## Quick Start

### 1. Prerequisites

- Flutter SDK 3.10 or later: https://docs.flutter.dev/get-started/install
- Android Studio or VS Code with Flutter/Dart extensions
- Android emulator or physical device (Android 8+)

Verify your setup:
```bash
flutter doctor
```

### 2. Create a new Flutter project (if starting fresh)

```bash
flutter create parent_app
cd parent_app
```

### 3. Copy the source files

Copy the following into your project:
```
lib/          → lib/
pubspec.yaml  → pubspec.yaml
```

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Configure the API base URL

Edit `lib/core/constants.dart`:

```dart
// Android emulator → uses 10.0.2.2 to reach localhost on host machine
static const String baseUrl = 'http://10.0.2.2:3001';

// Physical Android device → use your machine's LAN IP
// static const String baseUrl = 'http://192.168.1.x:3001';

// iOS simulator → localhost works directly
// static const String baseUrl = 'http://localhost:3001';
```

### 6. Run the app

Make sure the Node.js backend is running on port 3001, then:

```bash
# Android emulator
flutter run

# Specific device
flutter devices
flutter run -d <device-id>

# Release build
flutter build apk --release
```

---

## Project Structure

```
lib/
├── core/
│   ├── api_client.dart      # Dio singleton with auth interceptor
│   ├── constants.dart       # API base URL, entity names, storage keys
│   ├── router.dart          # GoRouter with 26 routes + auth redirect
│   └── theme.dart           # AppColors, AppTheme, text styles
├── models/
│   └── models.dart          # 21 data models (defensive camelCase + snake_case)
├── providers/
│   ├── auth_provider.dart   # Login, logout, role validation
│   └── data_provider.dart   # FutureProvider.family for all entities + cache
├── screens/                 # 26 screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── attendance_screen.dart
│   ├── fees_screen.dart
│   ├── assignments_screen.dart
│   ├── gradebook_screen.dart
│   ├── timetable_screen.dart
│   ├── messages_screen.dart
│   ├── announcements_screen.dart
│   ├── transport_screen.dart
│   ├── calendar_screen.dart
│   ├── exams_screen.dart
│   ├── report_cards_screen.dart
│   ├── results_screen.dart
│   ├── behaviour_screen.dart
│   ├── achievements_screen.dart
│   ├── health_screen.dart
│   ├── library_screen.dart
│   ├── ptm_screen.dart
│   ├── notifications_screen.dart
│   ├── study_materials_screen.dart
│   ├── documents_screen.dart
│   ├── children_screen.dart
│   ├── settings_screen.dart
│   └── more_screen.dart
└── widgets/
    └── common_widgets.dart  # Shared UI components
```

---

## Authentication

The app calls `POST /api/session/login` with `{ email, password }`.

Only users with `role === 'parent'` or `role === 'guardian'` can log in.  
The JWT token is stored in SharedPreferences under the key `pm_token` and injected
automatically into every API request via the Dio interceptor.

---

## Student Linking

The app finds children linked to the logged-in parent by filtering the `students` table
where `fatherEmail`, `motherEmail`, or `guardianEmail` matches the parent's login email.

---

## API Endpoints Used

| Purpose | Endpoint |
|---|---|
| Login | `POST /api/session/login` |
| All data | `GET /api/data/<entity>` |

All data fetching uses a single generic endpoint. The entity names match the database
table names defined in `AppConstants` (e.g. `students`, `invoices`, `attendance`, etc.).

---

## Firebase Setup (Push Notifications)

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with your package name (default: `com.example.parent_app`)
3. Download `google-services.json` and place it in `android/app/`
4. Follow the FlutterFire setup: https://firebase.flutter.dev/docs/overview

Push notifications will work automatically once the backend sends FCM messages to
the parent's device token.
