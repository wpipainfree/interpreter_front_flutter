# Flutter 서비스 생성

새로운 Flutter 서비스를 생성합니다.

## 사용법
```
/gen-service [service_name]
```

## 인자
$ARGUMENTS

- `service_name`: 생성할 서비스 이름 (snake_case)
  - 예: `analytics`, `cache`, `file_upload`

## 생성 위치

`lib/services/[service_name]_service.dart`

## 템플릿

프로젝트의 기존 패턴(싱글톤, ChangeNotifier)을 따르세요:

```dart
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class [ServiceName]Service extends ChangeNotifier {
  // 싱글톤 패턴
  static final [ServiceName]Service _instance = [ServiceName]Service._internal();
  factory [ServiceName]Service() => _instance;
  [ServiceName]Service._internal();

  final ApiClient _apiClient = ApiClient();

  // 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 메서드
  Future<void> someMethod() async {
    _isLoading = true;
    notifyListeners();

    try {
      // API 호출
      // final response = await _apiClient.dio.get('/endpoint');
    } catch (e) {
      debugPrint('[ServiceName]Service error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## 프로젝트 패턴

- **ApiClient** 사용: Dio 기반 HTTP 클라이언트
- **싱글톤**: 전역 상태 관리용
- **ChangeNotifier**: UI 상태 업데이트
- **FlutterSecureStorage**: 민감 데이터 저장
