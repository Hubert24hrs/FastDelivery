# Fast Delivery App - Lagos Edition

## Setup Instructions

### 1. Firebase Configuration
This app uses Firebase for Authentication and Database. You must add your Firebase configuration files:

- **Android**: Download `google-services.json` from Firebase Console and place it in `android/app/`.
- **iOS**: Download `GoogleService-Info.plist` from Firebase Console and place it in `ios/Runner/`.

**Note**: If you haven't run `flutterfire configure`, you may need to do so to generate `firebase_options.dart`.

### 2. Mapbox Configuration
The Mapbox Access Token is configured in `lib/core/constants/app_constants.dart`.
Ensure your token has the `downloads:read` scope for the Mobile SDK.

### 3. Assets
Assets are located in `assets/images/`. Ensure `logo.png`, `login_bg.png`, and `reference_ui.png` are present.

## Architecture
- **Frontend**: Flutter (Riverpod, GoRouter)
- **Backend**: Firebase (Auth, Firestore)
- **Maps**: Mapbox Maps Flutter

## Running the App
```bash
flutter pub get
flutter run
```
