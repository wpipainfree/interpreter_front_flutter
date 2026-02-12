# Flutter 위젯 생성

새로운 재사용 가능한 위젯을 생성합니다.

## 사용법
```
/gen-widget [widget_name]
```

## 인자
$ARGUMENTS

- `widget_name`: 생성할 위젯 이름 (snake_case)
  - 예: `custom_button`, `loading_indicator`, `error_card`

## 생성 위치

`lib/widgets/[widget_name].dart`

## 템플릿

### StatelessWidget (상태 없는 위젯)

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class [WidgetName] extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const [WidgetName]({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}
```

### StatefulWidget (상태 있는 위젯)

```dart
import 'package:flutter/material.dart';

class [WidgetName] extends StatefulWidget {
  final String title;

  const [WidgetName]({
    super.key,
    required this.title,
  });

  @override
  State<[WidgetName]> createState() => _[WidgetName]State();
}

class _[WidgetName]State extends State<[WidgetName]> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(widget.title),
    );
  }
}
```

## 프로젝트 스타일

- **AppColors**: `lib/utils/app_colors.dart` 색상 상수
- **AppTextStyles**: `lib/utils/app_text_styles.dart` 텍스트 스타일
- **const 생성자**: 가능하면 const 사용
- **super.key**: Flutter 3.x 스타일
