# 결제 시스템 (INICIS)

WPI 앱의 INICIS 모바일 결제 시스템을 확인합니다.

## 사용법
```
/payment
```

## 결제 플로우

```
1. 프론트: PaymentService.createPayment() 호출
2. 백엔드: POST /api/v1/mobile-payments → payment_id, webview_url 반환
3. 프론트: PaymentWebViewScreen에서 WebView로 결제 폼 로드
4. 사용자: 카드사/은행 앱으로 결제 진행
5. INICIS: 결제 완료 후 백엔드 콜백 호출
6. 백엔드: 결제 상태 업데이트
7. INICIS: 딥링크(wpiapp://payment?status=success)로 앱 복귀
8. 프론트: 결제 결과 확인 및 화면 전환
```

## 프론트엔드 구현

### PaymentService (`lib/services/payment_service.dart`)

```dart
// 결제 생성
Future<PaymentInfo> createPayment(CreatePaymentRequest request)

// 상태 조회
Future<PaymentInfo> getPaymentStatus(int paymentId)
```

### CreatePaymentRequest

```dart
CreatePaymentRequest(
  userId: int,
  amount: int,
  productName: 'WPI검사',
  buyerName: '구매자명',
  buyerEmail: 'email@example.com',
  buyerTel: '01012345678',
  callbackUrl: 'wpiapp://payment',
  testId: int?,
  paymentType: int?,  // 20: 카드, 21: 이체, 22: 가상계좌
)
```

### PaymentWebViewScreen (`lib/screens/payment/payment_webview_screen.dart`)

```dart
// 결제 화면 열기
PaymentWebViewScreen.open(
  context,
  webviewUrl: paymentInfo.webviewUrl,
  paymentId: paymentInfo.paymentId,
)

// 결제 결과
PaymentResult.success(paymentId)
PaymentResult.failed(message)
PaymentResult.cancelled()
```

## 백엔드 API

- `POST /api/v1/mobile-payments` - 결제 생성
- `GET /api/v1/mobile-payments/{id}` - 상태 조회
- `GET /api/v1/mobile-payments/{id}/inicis/mobile/form` - 결제 폼 HTML
- `POST /api/v1/mobile-payments/{id}/inicis/mobile/return` - INICIS 콜백

## 딥링크 설정

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="wpiapp" android:host="payment"/>
</intent-filter>
```

### iOS (`ios/Runner/Info.plist`)
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

## 결제 상태 코드

| 코드 | 상태 | 설명 |
|------|------|------|
| 0, 1 | pending | 결제 대기/진행 중 |
| 2 | paid | 결제 완료 |
| 5, 9 | failed | 결제 실패/취소 |

## 외부 앱 처리

WebView에서 카드사/은행 앱 스킴 자동 처리:
- `intent://` → 카드사 앱
- `kftc-bankpay://` → 뱅크페이
- `ispmobile://` → ISP 결제
- 기타 custom scheme → url_launcher로 실행
