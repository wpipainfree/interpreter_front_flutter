# WPI Mobile App Guide (Flutter MVP)

This document consolidates the initial app plan into a single guide tailored for a Codex-driven workflow. It covers the MVP screen map, Play Store review considerations, and cross-platform setup for Android-first launch with iOS follow-up.

## 1. Flutter Screen Map (MVP)

### 1.1 User Flow
```
[Splash] → [Onboarding] → [Sign-up/Login]
     ↓
[Home] → [Test Intro] → [Test]
     ↓
[Result Summary] → [Existence Detail] → [My Page]
```

### 1.2 Key Screens
- **Splash**: Animated logo + progress indicator.
- **Welcome**: Value proposition text and brief description.
- **Entry**: CTA to start WPI test, link to login.
- **Sign-up**: Email/password fields with validation, nickname, DOB picker, terms/ privacy checkboxes, submit button.
- **Test Intro**: Cards for duration, question count, method; notice about honest answers; start button.
- **Test**: Progress bar, current question indicator, 5-point Likert options with selection styling, previous/next navigation, exit dialog.
- **Result Summary**: Gradient header with existence type, cards for core message, red/blue line indicators and gap analysis, emotional and body signals, button to existence detail.
- **My Page**: Profile header, test history cards with timestamps, settings items (profile edit, notifications, help, logout).

## 2. Google Play Review Readiness

### 2.1 Strengths
- Fits **Health & Fitness** or **Lifestyle** category; explicitly not medical diagnosis.
- Clear theoretical basis (Existential Psychology by Dr. Hwang).
- Material Design–aligned Flutter UI with responsive layouts.
- Privacy measures: policy URL, consent flows, encryption, GDPR/CCPA readiness.
- Good UX: onboarding, progress feedback, visualized results, history.

### 2.2 Required Notices & Safeguards
- **Medical disclaimer**: “본 검사는 의학적 진단이나 치료를 대체하지 않습니다. 심리적 어려움이 있으신 경우 전문가의 도움을 받으시기 바랍니다.”
- **Age gate**: Recommend 13+ and youth protection language.
- **Content rating**: All users or 12+, flag mental-health topic.
- **Permissions**: Keep minimal (INTERNET, ACCESS_NETWORK_STATE) and disclose usage.

### 2.3 Submission Checklist
- App description explaining purpose/method; 5–8 screenshots; feature graphic; promo video (optional).
- targetSdkVersion ≥ 33, 64-bit, Android App Bundle (.aab), ProGuard/R8 enabled.
- Privacy policy URL, terms of service, data safety form, advertising ID disclosure.
- Testing across devices, network failure handling, zero crash reports, ANR mitigation.

### 2.4 Launch Strategy
1. **Pre-launch testing**: Internal (≤25), closed (≈100), open beta (500+), incorporate feedback.
2. **Staged rollout**: 10% → 50% → 100% after stability.
3. **Ongoing**: Respond to reviews, regular updates, monitor crashes/ANR and performance.

## 3. Cross-Platform Setup (Flutter)

### 3.1 Project Creation
```bash
flutter create wpi_app \
  --org com.yourcompany \
  --project-name wpi_app \
  --platforms=android,ios \
  -a kotlin \
  -i swift
```

### 3.2 Recommended Dependencies (extract)
```yaml
flutter: ^3.16.0
provider: ^6.1.1
riverpod: ^2.4.9
dio: ^5.4.0
retrofit: ^4.0.3
hive: ^2.2.3
shared_preferences: ^2.2.2
flutter_svg: ^2.0.9
lottie: ^3.0.0
fl_chart: ^0.65.0
firebase_auth: ^4.15.0
google_sign_in: ^6.1.6
firebase_analytics: ^10.7.4
firebase_crashlytics: ^3.4.8
```

### 3.3 Android Focus (initial release)
- `compileSdkVersion 34`, `minSdkVersion 21`, `targetSdkVersion 34`.
- Enable multidex, R8/proguard, resource shrinking; sign release builds.
- Manifest: INTERNET, ACCESS_NETWORK_STATE permissions only; cleartext traffic off.
- Material 3 theming and Google Play Console setup.

### 3.4 iOS Prep (follow-up)
- `Info.plist`: display name, bundle ID, version, light mode, camera/photos usage descriptions, ATS disabled for arbitrary loads, portrait orientation.
- Plan for Apple Developer account, TestFlight beta, CocoaPods resolution, real-device tests.

### 3.5 Adaptive UI & Navigation (concepts)
- Provide `AdaptiveButton`, `AdaptiveProgressIndicator`, and platform-aware dialogs (Cupertino on iOS, Material on Android).
- `AdaptiveNavigator` for platform-specific routes; shared business logic via services (e.g., `WPIService` for API and local storage).
- Conditional imports for platform utilities; handle permissions and notifications per OS policies.

## 4. Release Plans & Checklists

### Android Before Launch
- Min SDK confirmed, signing keys secured, ProGuard rules set, 64-bit AAB build.

### iOS Readiness
- Bundle ID reserved, iOS 12+ minimum, App Store Connect metadata, platform-specific icons/splash assets.

### Common Items
- Korean/English localization, privacy policy and terms URLs, store assets (icons, screenshots), and data safety disclosures.

## 5. Monetization & Post-MVP Ideas
- Premium subscription (월 9,900원), one-off detailed analysis (19,900원), counselor matching fee (10–20%), B2B licensing.
- Future features: result sharing, counselor matching, educational content, premium analyses.

## 6. Effort Estimates
- **Phase 1 (4–6 weeks)**: UI/UX (2w), API/logic (2w), testing/bugfix (1w), store prep (1w).
- **Phase 2 (2–3 weeks)**: Feedback-driven improvements, performance optimization, added features.
- **Phase 3 (1–2 weeks)**: Store review, marketing, full launch.

---
By adhering to the notices, privacy requirements, and staged rollout above, the current plan should have a strong chance (≈85–90%) of passing Google Play review.

## 7. Flutter Skeleton Code
The repository now includes a minimal Flutter scaffold that matches the above MVP flow:
- `lib/main.dart`: App entry with Material 3 theme.
- `lib/screens/`: Splash, welcome, entry, sign-up/login, test intro, test, result summary, existence detail, and my page screens wired with navigation.
- `lib/models/wpi_result.dart`: Simple model used to pass mock analysis results.
- All copy and mock data are embedded locally so you can run the UI without a backend. The theme now uses the default platform font to avoid missing-font asset errors on a fresh clone.

## 8. How to See the Screens Locally
The repo is ready to run as a stock Flutter app. Because this container does not include the Flutter SDK or emulators, you need Flutter installed on your machine (3.16+ recommended) to preview the UI.

1) **Install prerequisites**
   - Flutter SDK: https://docs.flutter.dev/get-started/install
   - An emulator or a physical device connected with debugging enabled.

2) **Fetch dependencies**
```bash
flutter pub get
```

3) **Choose a device**
```bash
flutter devices
# Pick the desired device ID from the list (Android emulator or iOS simulator/USB device)
```

4) **Run the app**
```bash
flutter run -d <device_id>
```
   - The app will start at the splash screen, then the welcome → entry screens.
   - Tap through: "WPI 검사 시작하기" → onboarding/auth → 검사 안내 → 검사 진행 → 결과 요약 → 존재구조 상세 → 마이페이지.

5) **Hot reload/hot restart**
```bash
r   # hot reload in the flutter run terminal
R   # hot restart
```

If you prefer web preview, you can also run `flutter run -d chrome`, though the layout was primarily designed for mobile portrait.
