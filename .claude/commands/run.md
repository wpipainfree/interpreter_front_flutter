# Flutter 앱 실행

Flutter 앱을 실행합니다.

## 사용법
```
/run [platform]
```

## 인자
- `platform` (선택): 실행할 플랫폼 (android, ios, web, macos)
  - 미지정시 기본 연결된 디바이스에서 실행

## 실행 명령

$ARGUMENTS

플랫폼 인자에 따라 적절한 명령어를 실행하세요:

1. **인자 없음**: `flutter run`
2. **android**: `flutter run -d android`
3. **ios**: `flutter run -d ios`
4. **web**: `flutter run -d chrome`
5. **macos**: `flutter run -d macos`

실행 전 `flutter devices`로 연결된 디바이스를 확인하고, 연결된 디바이스가 없으면 사용자에게 알려주세요.

디버그 모드로 실행되며, 핫 리로드가 지원됩니다.
