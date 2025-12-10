# Firebase Setup Guide for Fast Delivery

This guide covers the configuration needed for social login (Google/Apple) and Firestore rules.

## 1. Deploy Firestore Security Rules

The security rules are in `firestore.rules`. Deploy them with:

```bash
# On Windows, you may need to run PowerShell as Administrator first and run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then deploy:
firebase deploy --only firestore:rules
```

---

## 2. Google Sign-In Setup

### Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com) → Your Project → Authentication
2. Click **Sign-in method** → **Google** → **Enable**
3. Add your support email

### Android Configuration
1. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Add SHA-1 to Firebase Console → Project Settings → Android app
3. Download updated `google-services.json` → place in `android/app/`

### iOS Configuration
1. Go to Firebase Console → Project Settings → iOS app
2. Download `GoogleService-Info.plist` → place in `ios/Runner/`

---

## 3. Apple Sign-In Setup

### Requirements
- Apple Developer account ($99/year)
- macOS for iOS builds

### Apple Developer Portal
1. Go to [Apple Developer](https://developer.apple.com)
2. Create **App ID** with Sign In with Apple capability
3. Create **Service ID** for web (if needed)
4. Create **Key** for Sign in with Apple

### Firebase Console
1. Go to Authentication → Sign-in method → Apple → Enable
2. Add your Service ID and Team ID

### Xcode (for iOS)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Add **Sign in with Apple** capability

---

## 4. Paystack Configuration

1. Get your keys from [Paystack Dashboard](https://dashboard.paystack.com/#/settings/developers)
2. Update `lib/core/services/paystack_service.dart`:
   ```dart
   static const String _publicKey = 'pk_live_xxxxx'; // Your public key
   ```

### Server-Side Verification (Required for Production)
Create a backend endpoint to verify transactions:
- Endpoint: `GET https://api.paystack.co/transaction/verify/:reference`
- Header: `Authorization: Bearer sk_live_xxxxx` (secret key)

---

## 5. Quick Checklist

- [ ] Firebase Authentication → Enable Google provider
- [ ] Firebase Authentication → Enable Apple provider (requires Apple Developer account)
- [ ] Add SHA-1 to Firebase (Android)
- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Add Sign in with Apple capability in Xcode (iOS)
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Replace Paystack test key with live key
- [ ] Implement server-side payment verification
