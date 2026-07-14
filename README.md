# FlipMeet – Flutter WebView App

A fully-featured Android app for **flipmeet.fun** built with Flutter.

## Features

- 🖥️ Full-screen WebView — no browser chrome, no title bar
- 📡 Offline detection — shows a branded "No Internet" screen with Retry
- ⌨️ Keyboard fix — chat input scrolls into view when keyboard opens
- 🎥 Camera + microphone auto-granted for video calls
- 💜 Animated splash screen
- 🔒 Status bar kept (dark); Android nav buttons hidden via immersive-sticky

---

## Quick Build (one command)

```bash
# Prerequisites: Flutter SDK installed and in PATH
bash build.sh
# APK → build/app/outputs/flutter-apk/app-release.apk
```

The script automatically:
1. Scaffolds a temp Flutter project to copy the default launcher icons
2. Runs `flutter pub get`
3. Runs `flutter build apk --release`

---

## Manual Build Steps

```bash
# 1. Install Flutter: https://flutter.dev/docs/get-started/install
# 2. Verify setup
flutter doctor

# 3. Install dependencies
flutter pub get

# 4. Generate launcher icons (optional — add your own 1024x1024 icon.png first)
# flutter pub add flutter_launcher_icons
# flutter pub run flutter_launcher_icons

# 5. Build
flutter build apk --release

# 6. Install to connected device
flutter install
```

---

## Signing a Release APK for the Play Store

The default build uses Flutter's debug keystore. For production:

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore flipmeet.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias flipmeet
   ```

2. Add to `android/app/build.gradle` inside the `android {}` block:
   ```groovy
   signingConfigs {
       release {
           storeFile file('../../flipmeet.jks')
           storePassword 'YOUR_STORE_PASS'
           keyAlias 'flipmeet'
           keyPassword 'YOUR_KEY_PASS'
       }
   }
   buildTypes {
       release { signingConfig signingConfigs.release }
   }
   ```

3. Rebuild: `flutter build apk --release`

---

## Project Structure

```
flutter_flipmeet/
├── build.sh                          ← one-shot build script
├── pubspec.yaml                      ← Flutter + package deps
├── lib/
│   └── main.dart                     ← all app logic (splash + webview + offline)
└── android/
    ├── settings.gradle
    ├── build.gradle
    ├── gradle.properties
    ├── gradle/wrapper/
    │   └── gradle-wrapper.properties
    └── app/
        ├── build.gradle
        └── src/main/
            ├── AndroidManifest.xml
            ├── kotlin/com/flipmeet/app/MainActivity.kt
            └── res/
                ├── values/styles.xml
                ├── values/colors.xml
                └── drawable/launch_background.xml
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `webview_flutter` | ^4.10.0 | Embedded WebView |
| `connectivity_plus` | ^6.0.3 | Network detection |

---

## Minimum Requirements

- Flutter SDK 3.16+
- Android SDK 21+ (Android 5.0 Lollipop)
- Target SDK 35
