# Flutter 모델 생성

새로운 데이터 모델을 생성합니다.

## 사용법
```
/gen-model [model_name]
```

## 인자
$ARGUMENTS

- `model_name`: 생성할 모델 이름 (snake_case)
  - 예: `payment_result`, `notification_setting`, `user_profile`

## 생성 위치

`lib/models/[model_name].dart`

## 템플릿

프로젝트의 기존 패턴을 따르세요:

```dart
class [ModelName] {
  final int id;
  final String name;
  final DateTime createdAt;

  const [ModelName]({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // JSON -> Model
  factory [ModelName].fromJson(Map<String, dynamic> json) {
    return [ModelName](
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Model -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // copyWith (선택)
  [ModelName] copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return [ModelName](
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => '[ModelName](id: $id, name: $name)';
}
```

## 프로젝트 패턴

- **immutable**: `final` 필드, `const` 생성자
- **fromJson/toJson**: JSON 직렬화
- **nullable 처리**: 백엔드 응답에 따라 `?` 사용
- **날짜 처리**: `DateTime.parse()` 사용
