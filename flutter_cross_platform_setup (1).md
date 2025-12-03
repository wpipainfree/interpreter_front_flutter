# Flutter 크로스플랫폼 설정 가이드
## Android 우선 출시 → iOS 확장 전략

## 🎯 1. 프로젝트 초기 설정 (양쪽 플랫폼 동시 준비)

### 1.1 Flutter 프로젝트 생성
```bash
# 프로젝트 생성 시 양쪽 플랫폼 모두 포함
flutter create wpi_app \
  --org com.yourcompany \
  --project-name wpi_app \
  --platforms=android,ios \
  -a kotlin \
  -i swift
```

### 1.2 프로젝트 구조
```
wpi_app/
├── lib/                    # 공통 Dart 코드 (95% 이상)
│   ├── main.dart
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   └── models/
├── android/                # Android 전용 설정
│   ├── app/
│   └── gradle/
├── ios/                     # iOS 전용 설정
│   ├── Runner/
│   └── Podfile
├── assets/                  # 공통 리소스
└── pubspec.yaml            # 의존성 관리
```

## 📱 2. 플랫폼별 설정 최적화

### 2.1 pubspec.yaml (공통 설정)
```yaml
name: wpi_app
description: WPI 심리 검사 애플리케이션
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # 크로스플랫폼 호환 패키지만 사용
  cupertino_icons: ^1.0.6          # iOS 스타일 아이콘
  
  # UI/UX (양쪽 플랫폼 지원)
  flutter_native_splash: ^2.3.8    # 네이티브 스플래시
  flutter_launcher_icons: ^0.13.1  # 앱 아이콘
  
  # 상태 관리
  provider: ^6.1.1
  
  # 네트워킹
  dio: ^5.4.0
  
  # 로컬 저장소
  shared_preferences: ^2.2.2       # 양쪽 플랫폼 지원
  hive_flutter: ^1.1.0
  
  # 권한 관리
  permission_handler: ^11.1.0      # 양쪽 플랫폼 권한
  
  # Firebase (양쪽 플랫폼)
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_analytics: ^10.7.4
  
  # 플랫폼 감지
  device_info_plus: ^9.1.1
  platform: ^3.1.3

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.ttf
        - asset: assets/fonts/Pretendard-Bold.ttf
          weight: 700
```

### 2.2 Android 전용 설정 (우선 출시용)

#### android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.yourcompany.wpi_app"
        minSdkVersion 21        // Android 5.0 이상
        targetSdkVersion 34     // 최신 타겟
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 
                         'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

#### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- 권한 설정 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application
        android:label="WPI 마음읽기"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:theme="@style/LaunchTheme">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Firebase 설정 -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/notification_icon" />
    </application>
</manifest>
```

### 2.3 iOS 설정 (추후 출시 대비)

#### ios/Runner/Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>ko_KR</string>
    
    <key>CFBundleDisplayName</key>
    <string>WPI 마음읽기</string>
    
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <key>CFBundleName</key>
    <string>wpi_app</string>
    
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <!-- iOS 13+ 다크모드 지원 -->
    <key>UIUserInterfaceStyle</key>
    <string>Light</string>
    
    <!-- 권한 설명 (필수) -->
    <key>NSCameraUsageDescription</key>
    <string>프로필 사진 촬영을 위해 카메라 접근이 필요합니다</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>프로필 사진 선택을 위해 사진 라이브러리 접근이 필요합니다</string>
    
    <!-- 앱 전송 보안 설정 -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
    
    <!-- 지원 기기 -->
    <key>UIRequiresFullScreen</key>
    <true/>
    
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

## 🎨 3. 플랫폼 적응형 UI 코드

### 3.1 적응형 위젯 사용
```dart
// lib/widgets/adaptive_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const AdaptiveButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 플랫폼별 다른 버튼 스타일
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: onPressed,
        color: color ?? CupertinoColors.activeBlue,
        child: Text(text),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text),
      );
    }
  }
}

class AdaptiveProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const CupertinoActivityIndicator();
    } else {
      return const CircularProgressIndicator();
    }
  }
}

class AdaptiveAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<AdaptiveDialogAction> actions;

  const AdaptiveAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions.map((action) => CupertinoDialogAction(
          onPressed: action.onPressed,
          isDestructiveAction: action.isDestructive,
          child: Text(action.text),
        )).toList(),
      );
    } else {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions.map((action) => TextButton(
          onPressed: action.onPressed,
          child: Text(
            action.text,
            style: TextStyle(
              color: action.isDestructive ? Colors.red : null,
            ),
          ),
        )).toList(),
      );
    }
  }
}

class AdaptiveDialogAction {
  final String text;
  final VoidCallback onPressed;
  final bool isDestructive;

  AdaptiveDialogAction({
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
  });
}
```

### 3.2 플랫폼별 네비게이션
```dart
// lib/navigation/adaptive_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class AdaptiveNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page,
  ) {
    if (Platform.isIOS) {
      return Navigator.of(context).push<T>(
        CupertinoPageRoute(builder: (_) => page),
      );
    } else {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  static Future<T?> pushReplacement<T>(
    BuildContext context,
    Widget page,
  ) {
    if (Platform.isIOS) {
      return Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => page),
      );
    } else {
      return Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }
}
```

### 3.3 플랫폼별 테마 설정
```dart
// lib/theme/adaptive_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class AdaptiveTheme {
  static ThemeData androidTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F4C81),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      fontFamily: 'Pretendard',
    );
  }

  static CupertinoThemeData iosTheme() {
    return const CupertinoThemeData(
      primaryColor: CupertinoColors.activeBlue,
      primaryContrastingColor: CupertinoColors.white,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(fontFamily: 'Pretendard'),
      ),
    );
  }
}
```

## 🚀 4. 단계별 출시 전략

### 4.1 Phase 1: Android 출시 (1-2개월)
```yaml
1주차:
  - Android 전용 최적화
  - Material Design 3 적용
  - Google Play Console 설정

2-3주차:
  - Android 디바이스 테스트
  - 성능 최적화 (ProGuard, R8)
  - 크래시 리포트 설정

4주차:
  - 내부 테스트 트랙 배포
  - 베타 테스트 진행

5-6주차:
  - Google Play 심사 제출
  - 정식 출시
```

### 4.2 Phase 2: iOS 준비 (Android 출시 후 1개월)
```yaml
준비사항:
  - Apple Developer 계정 ($99/년)
  - Mac 개발 환경
  - iPhone 테스트 기기
  
1주차:
  - iOS 빌드 설정
  - CocoaPods 의존성 해결
  - iOS 시뮬레이터 테스트

2주차:
  - iOS 디자인 가이드라인 적용
  - Cupertino 위젯 최적화
  - iOS 전용 기능 구현

3주차:
  - TestFlight 베타 배포
  - iOS 디바이스 테스트

4주차:
  - App Store 심사 제출
  - 정식 출시
```

## 📝 5. 공통 코드 작성 원칙

### 5.1 플랫폼 독립적 비즈니스 로직
```dart
// lib/services/wpi_service.dart
class WPIService {
  // 플랫폼과 무관한 비즈니스 로직
  Future<WPIResult> analyzeProfile(Map<String, dynamic> answers) async {
    // API 호출 로직 (플랫폼 독립적)
    final response = await dio.post('/api/wpi/analyze', data: answers);
    return WPIResult.fromJson(response.data);
  }
  
  // 로컬 저장소 (플랫폼 독립적)
  Future<void> saveResult(WPIResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_result', result.toJson());
  }
}
```

### 5.2 조건부 임포트 사용
```dart
// lib/utils/platform_util.dart
import 'platform_util_stub.dart'
    if (dart.library.io) 'platform_util_mobile.dart'
    if (dart.library.html) 'platform_util_web.dart';

abstract class PlatformUtil {
  bool get isAndroid;
  bool get isIOS;
  bool get isWeb;
  
  factory PlatformUtil() => getPlatformUtil();
}
```

## 🔧 6. 플랫폼별 기능 차이 처리

### 6.1 권한 처리
```dart
// lib/utils/permission_handler.dart
class PermissionHandler {
  static Future<bool> requestCameraPermission() async {
    if (Platform.isAndroid) {
      // Android는 런타임 권한
      final status = await Permission.camera.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS는 Info.plist + 런타임 권한
      final status = await Permission.camera.request();
      return status.isGranted;
    }
    return false;
  }
  
  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 필요
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      // iOS는 항상 필요
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }
}
```

### 6.2 푸시 알림
```dart
// lib/services/notification_service.dart
class NotificationService {
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      // Android 채널 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      await flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(android: initializationSettingsAndroid),
      );
    } else if (Platform.isIOS) {
      // iOS 설정
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      await flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(iOS: initializationSettingsIOS),
      );
    }
  }
}
```

## 💰 7. 비용 최적화 전략

### 7.1 개발 비용
```yaml
Android 우선 출시:
  - Google Play 개발자 등록: $25 (일회성)
  - 테스트 디바이스: 기존 Android 폰 활용
  - 개발 환경: Windows/Mac/Linux 모두 가능
  
iOS 추후 출시:
  - Apple Developer: $99/년
  - Mac 필수 (M1 Mac mini 추천)
  - TestFlight 무료
  - 실제 iPhone 테스트 필요
```

### 7.2 시간 절약 팁
```dart
// 한 번 작성으로 양쪽 플랫폼 지원
class WPIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WPI 마음읽기',
      theme: AdaptiveTheme.androidTheme(),
      // iOS에서도 Material 디자인 사용 가능
      // 또는 Platform.isIOS로 분기 처리
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## 📊 8. 플랫폼별 분석 도구

### 8.1 Firebase 설정 (양쪽 지원)
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (플랫폼 자동 감지)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Crashlytics 설정
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(WPIApp());
}
```

### 8.2 플랫폼별 분석
```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  static void logEvent(String name, Map<String, dynamic> parameters) {
    // 플랫폼 정보 자동 추가
    parameters['platform'] = Platform.operatingSystem;
    parameters['platform_version'] = Platform.operatingSystemVersion;
    
    FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  static void setUserProperties() {
    FirebaseAnalytics.instance.setUserProperty(
      name: 'platform',
      value: Platform.isAndroid ? 'android' : 'ios',
    );
  }
}
```

## ✅ 9. 체크리스트

### Android 출시 전
- [ ] Android 최소 버전 확인 (minSdkVersion 21)
- [ ] 앱 서명 키 생성 및 보관
- [ ] ProGuard 규칙 설정
- [ ] 64비트 지원 확인
- [ ] Android App Bundle(.aab) 빌드

### iOS 출시 대비
- [ ] Apple Developer 계정 준비
- [ ] Bundle ID 예약 (com.yourcompany.wpiapp)
- [ ] iOS 최소 버전 설정 (iOS 12.0+)
- [ ] App Store Connect 정보 준비
- [ ] iOS 아이콘/스플래시 준비 (다양한 크기)

### 공통
- [ ] 다국어 지원 준비 (한국어/영어)
- [ ] 개인정보 처리방침 URL
- [ ] 서비스 이용약관
- [ ] 앱 설명 및 스크린샷
- [ ] 앱 아이콘 (각 플랫폼별 크기)

## 🎯 결론

Flutter로 개발하면 **95% 이상의 코드를 공유**하면서 양쪽 플랫폼을 지원할 수 있습니다.

**추천 전략:**
1. Android 먼저 출시 → 시장 반응 확인
2. 사용자 피드백 반영 → 앱 개선
3. iOS 버전 준비 → 추가 출시

**예상 추가 작업 (iOS):**
- 플랫폼별 UI 미세 조정: 1-2일
- iOS 전용 설정: 1일
- TestFlight 테스트: 3-5일
- App Store 심사: 3-7일

총 **2주 이내**에 iOS 버전도 출시 가능합니다!
