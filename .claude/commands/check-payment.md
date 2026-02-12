# 결제 시스템 확인

현재 결제 시스템 구현을 확인합니다.

## 사용법
```
/check-payment
```

## 확인 사항

### 1. PaymentService 확인
`lib/services/payment_service.dart` 파일을 읽어서:
- INICIS 결제 연동 상태
- 결제 요청/결과 처리 로직
- WebView 콜백 처리

### 2. 결제 화면 확인
`lib/screens/payment/payment_webview_screen.dart`:
- WebView 설정
- 딥링크 핸들링
- 결제 완료/취소 처리

### 3. 결제 플로우

1. 결제 요청 생성 (백엔드)
2. WebView로 INICIS 결제 폼 로드
3. 사용자 결제 진행
4. 결제 결과 콜백 (딥링크)
5. 결과 화면 표시

### 4. 딥링크 설정

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <data android:scheme="wpiapp" android:host="payment"/>
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>wpiapp</string>
    </array>
  </dict>
</array>
```
