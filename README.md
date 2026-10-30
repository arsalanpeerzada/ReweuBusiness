# Reweu Business

Companion app for Reweu business owners and branch managers: a live feed of customer incidents raised from low-scoring reviews, incident triage (acknowledge, internal notes, resolve with an optional service-recovery voucher), push alerts, and incident analytics.

Flutter 3.47, Dart 3.12. Android (`com.teniqs.reweu_business`) and iOS (`com.teniqs.reweuBusiness`).

## Features

- Email/password sign-in against the Reweu backend; token kept only in the Keystore/Keychain.
- Optional biometric unlock (fingerprint, face or device passcode) on launch and after 60 seconds in the background.
- Incident feed with status tabs, branch filter, search, paging, pull to refresh and swipe to acknowledge.
- Incident detail with customer feedback, call / WhatsApp / email hand-off, team notes, timeline and resolution with a validated voucher.
- Push notifications (FCM) that open the incident when tapped.
- Analytics: incident count, resolution rate, average time to review and resolve, daily severity trend, branch and staff tables (7 / 30 / 90 days).
- Offline mode: the last loaded feed page and viewed incidents are cached encrypted and shown read-only when the network is down.
- English and Urdu (right-to-left), switchable in Profile.
- Screenshots blocked on the incident screen (Android) and app-switcher snapshot hidden on both platforms.
- Crash reporting with Firebase Crashlytics in release builds.

## Run locally

```bash
flutter pub get
flutter run
```

The app talks to `https://api.reweu.app` by default. Point it at another environment at build time:

```bash
flutter run --dart-define=API_BASE_URL=https://staging-api.reweu.app
```

## Firebase (push and Crashlytics)

The app builds and runs without Firebase; push and crash reporting are simply off. To switch them on:

1. In the Firebase console, add the Android app `com.teniqs.reweu_business` and the iOS app `com.teniqs.reweuBusiness`.
2. Android: save `google-services.json` to `android/app/`. The Gradle build detects it and applies the Google Services and Crashlytics plugins.
3. iOS: add `GoogleService-Info.plist` to the `Runner` target in Xcode (drag it into `Runner/`, tick "Copy items if needed" and the Runner target).
4. iOS: upload an APNs authentication key under Project settings > Cloud Messaging, and enable the Push Notifications capability for the App ID in the Apple Developer portal.

Both files are git-ignored so each environment can use its own Firebase project.

## Release signing

### Android

Create an upload keystore once and keep it outside the repository:

```bash
keytool -genkey -v -keystore ~/reweu-business-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` and fill it in (the file is git-ignored). Without it, release builds fall back to the debug key, which Play rejects.

### iOS

Open `ios/Runner.xcworkspace`, select the Runner target, and set your Team under Signing & Capabilities. The push entitlement (`Runner/Runner.entitlements`) is already wired in.

## Tests and CI

```bash
flutter analyze
flutter test
```

`.github/workflows/ci.yml` runs analysis and tests on every pull request, builds a debug APK and an unsigned iOS build, and on `v*` tags builds a signed, obfuscated Play bundle. Repository secrets used:

| Secret | Purpose |
|---|---|
| `REWEU_BUSINESS_KEYSTORE_BASE64` | Upload keystore, base64-encoded |
| `REWEU_BUSINESS_KEYSTORE_PASSWORD` | Keystore password |
| `REWEU_BUSINESS_KEY_ALIAS` | Key alias |
| `REWEU_BUSINESS_KEY_PASSWORD` | Key password |
| `GOOGLE_SERVICES_JSON` | Optional, contents of `google-services.json` |

Set the repository variable `API_BASE_URL` to override the production API for tagged builds.

## Regenerating icons and splash screens

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Sources: `assets/images/app_icon.png` (iOS icon), `assets/images/logo.png` and `assets/images/splash_android12.png` (splash). Android launcher icons are the hand-made adaptive icons under `android/app/src/main/res`.

## Known gaps and backend dependencies

- **Critical tab:** the backend has no severity filter on `GET /api/incidents/business/{id}`, so the app filters loaded pages client-side and reads ahead up to five pages. A `severity` query parameter on the backend would make this exact.
- **Search** runs over loaded incidents only, for the same reason.
- **Push in production:** the backend reads `firebase.admin.config.path` only in its local profile, so production does not send pushes until that is configured there. It also only pushes for CRITICAL incidents today.
- **Fonts** (Outfit, Plus Jakarta Sans, Noto Nastaliq Urdu) are fetched at runtime by `google_fonts` and cached; first launch offline falls back to the system font. To bundle them, add the font files under `assets/google_fonts/` and declare that folder in `pubspec.yaml`.
- **Urdu strings** in `assets/languages/ur-PK.json` need review by a native speaker before release.
