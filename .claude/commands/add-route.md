# 라우트 추가

새로운 라우트를 앱 라우터에 추가합니다.

## 사용법
```
/add-route [route_name] [screen_name]
```

## 인자
$ARGUMENTS

- `route_name`: 라우트 경로 (예: `/payment/result`)
- `screen_name`: 연결할 화면 클래스명 (예: `PaymentResultScreen`)

## 수정 파일

### 1. lib/router/app_routes.dart

라우트 상수 추가:
```dart
static const String paymentResult = '/payment/result';
```

Arguments 클래스 추가 (필요시):
```dart
class PaymentResultArgs {
  final String orderId;
  final bool success;

  const PaymentResultArgs({
    required this.orderId,
    required this.success,
  });
}
```

### 2. lib/router/app_router.dart

onGenerateRoute에 케이스 추가:
```dart
case AppRoutes.paymentResult:
  final args = settings.arguments as PaymentResultArgs?;
  return MaterialPageRoute(
    builder: (_) => PaymentResultScreen(
      orderId: args?.orderId ?? '',
      success: args?.success ?? false,
    ),
    settings: settings,
  );
```

## 네비게이션 사용

```dart
Navigator.pushNamed(
  context,
  AppRoutes.paymentResult,
  arguments: PaymentResultArgs(
    orderId: 'ORDER123',
    success: true,
  ),
);
```
