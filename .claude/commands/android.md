# Android 설정 및 실행

WPI 앱의 Android 플랫폼 설정을 확인하고 실행합니다.

## 사용법
```
/android [action]
```

## 인자
$ARGUMENTS

- `action` (선택): run, build, clean, config

## 실행 명령

### 앱 실행
```bash
flutter run -d android
# 또는 특정 디바이스
flutter devices  # 디바이스 목록 확인
flutter run -d <device_id>
```

### 빌드
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store 배포용)
flutter build appbundle --release
```

### 빌드 결과물 위치
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 주요 설정 파일

### build.gradle (`android/app/build.gradle`)
```groovy
android {
    namespace "com.wpi.app"
    compileSdkVersion 34
    minSdkVersion 23
    targetSdkVersion 34
}
```

### AndroidManifest.xml (`android/app/src/main/AndroidManifest.xml`)
- 패키지명: `com.wpi.app`
- 권한 설정 (인터넷, 알림 등)
- 딥링크 스킴: `wpiapp://`
- 카카오 SDK 설정

## 소셜 로그인 설정

### 카카오
```xml
<!-- AndroidManifest.xml -->
<activity android:name="com.kakao.sdk.auth.AuthCodeHandlerActivity">
  <intent-filter>
    <data android:scheme="kakao{NATIVE_APP_KEY}" android:host="oauth"/>
  </intent-filter>
</activity>
```

### Google
- `android/app/google-services.json` 필요
- Firebase Console에서 SHA-1 등록

## 딥링크 설정 (결제 콜백)
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="wpiapp" android:host="payment"/>
</intent-filter>
```

## 문제 해결

### Gradle 빌드 실패
```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
```

### SDK 버전 오류
`android/app/build.gradle`에서 minSdkVersion 확인 (최소 23)

### 서명 설정 (릴리즈 빌드)
`android/app/build.gradle`에 signing config 설정 필요
