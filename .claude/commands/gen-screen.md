# Flutter 화면 생성

새로운 Flutter 화면(Screen)을 생성합니다.

## 사용법
```
/gen-screen [screen_name]
```

## 인자
$ARGUMENTS

- `screen_name`: 생성할 화면 이름 (snake_case)
  - 예: `payment_result`, `user_profile`, `settings`

## 생성 위치

`lib/screens/[screen_name]_screen.dart`

## 템플릿

프로젝트의 기존 패턴을 따라 StatefulWidget 기반으로 생성하세요:

```dart
import 'package:flutter/material.dart';

class [ScreenName]Screen extends StatefulWidget {
  const [ScreenName]Screen({super.key});

  @override
  State<[ScreenName]Screen> createState() => _[ScreenName]ScreenState();
}

class _[ScreenName]ScreenState extends State<[ScreenName]Screen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[Screen Name]'),
      ),
      body: const Center(
        child: Text('[Screen Name] Screen'),
      ),
    );
  }
}
```

## 추가 작업

화면 생성 후 다음을 수행하세요:

1. `lib/router/app_routes.dart`에 라우트 상수 추가
2. `lib/router/app_router.dart`에 라우트 케이스 추가
3. 필요시 Arguments 클래스 생성

프로젝트의 기존 스타일(AppColors, AppTextStyles)을 사용하세요.
