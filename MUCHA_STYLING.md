# 알폰스 무하 아르누보 스타일 가이드

이 문서는 Flutter 앱에 적용된 알폰스 무하(Alphonse Mucha)의 아르누보 스타일 디자인에 대한 가이드입니다.

## 🎨 색상 팔레트

### 주요 색상
- **Primary (라벤더)**: `#9B7EBD` - 무하의 대표적인 파스텔 퍼플
- **Secondary (로즈/피치)**: `#E8B4B8` - 부드럽고 따뜻한 핑크 톤
- **Accent (골드)**: `#D4AF37` - 무하의 황금 장식 느낌

### 배경 색상
- **다크 배경**: `#4A3C57` - 깊은 자주색 (온보딩, 스플래시)
- **라이트 배경**: `#FAF7F2` - 크림/아이보리 톤
- **카드 배경**: `#FFFBF5` - 부드러운 아이보리

### 텍스트 색상
- **Primary Text**: `#4A3C57` - 깊은 자주색
- **Secondary Text**: `#6B5B73` - 중간 톤 자주색
- **Tertiary Text**: `#9B8AA1` - 밝은 회색-퍼플

### 존재 유형별 색상
- **조화형**: `#9CC5A1` - 세이지 그린
- **도전형**: `#E8B4B8` - 로즈
- **안정형**: `#8ABED4` - 파스텔 블루
- **탐구형**: `#A98FBC` - 라일락
- **감성형**: `#F5C6CB` - 핑크

## 🎭 디자인 특징

### 1. 곡선미 (Curved Lines)
- 모든 버튼과 입력 필드에 더 둥근 모서리 적용 (28px radius)
- 카드와 프레임에 우아한 곡선 (24px radius)
- 커스텀 곡선 라인과 장식 요소

### 2. 장식적 요소
- `MuchaDecorativeDivider`: 우아한 곡선 구분선
- `MuchaDecorativeFrame`: 장식적인 프레임 (모서리 장식 포함)
- 골드 악센트와 그림자 효과

### 3. 그라데이션
- `MuchaGradientBackground`: 부드러운 라이트 그라데이션
- `MuchaDarkGradientBackground`: 다크 그라데이션 + 패턴 오버레이
- `MuchaCard`: 그라데이션과 장식이 포함된 카드

### 4. 타이포그래피
- 넓은 자간 (letter-spacing) 적용
- 우아한 폰트 웨이트 (400-700)
- 여유있는 행간 (line-height: 1.4-1.7)

## 📦 새로운 위젯

### MuchaDecorativeDivider
우아한 곡선이 있는 구분선 위젯

```dart
MuchaDecorativeDivider(
  height: 40,
  color: AppColors.primary,
)
```

### MuchaDecorativeFrame
모서리에 장식이 있는 프레임 위젯

```dart
MuchaDecorativeFrame(
  borderColor: AppColors.primary,
  backgroundColor: AppColors.cardBackground,
  padding: EdgeInsets.all(24),
  child: YourWidget(),
)
```

### MuchaGradientBackground
부드러운 그라데이션 배경

```dart
MuchaGradientBackground(
  child: YourWidget(),
)
```

### MuchaDarkGradientBackground
다크 그라데이션 + 패턴 배경 (온보딩/스플래시용)

```dart
MuchaDarkGradientBackground(
  child: YourWidget(),
)
```

### MuchaCard
무하 스타일의 장식적인 카드

```dart
MuchaCard(
  padding: EdgeInsets.all(20),
  margin: EdgeInsets.all(16),
  child: YourWidget(),
)
```

## 🎨 사용 예시

### 스플래시 스크린
```dart
Scaffold(
  body: MuchaDarkGradientBackground(
    child: Center(
      child: Column(
        children: [
          Icon(Icons.psychology, color: AppColors.accent),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ],
      ),
    ),
  ),
)
```

### 일반 화면
```dart
Scaffold(
  body: MuchaGradientBackground(
    child: ListView(
      children: [
        MuchaCard(
          child: Column(
            children: [
              Text('제목', style: AppTextStyles.h3),
              MuchaDecorativeDivider(),
              Text('내용', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

## 🌟 무하 스타일의 핵심 원칙

1. **파스텔 톤**: 부드럽고 우아한 파스텔 색상 사용
2. **골드 악센트**: 중요한 부분에 금색 포인트
3. **유려한 곡선**: 직선보다 곡선, 장식적인 요소
4. **여성적 우아함**: 섬세하고 정교한 디테일
5. **자연 모티브**: 꽃, 식물과 같은 유기적 형태 (향후 추가 예정)

## 📝 향후 개선 사항

- [ ] 무하 스타일의 꽃/식물 아이콘 세트 추가
- [ ] 커스텀 폰트 적용 (우아한 세리프 또는 아르누보 스타일)
- [ ] 애니메이션 효과 (부드러운 페이드, 슬라이드)
- [ ] 무하 작품에서 영감을 받은 일러스트레이션 추가
- [ ] 다크 모드 지원

## 🎭 참고 자료

- [Alphonse Mucha - Official Website](https://www.muchafoundation.org/)
- Art Nouveau 스타일 가이드
- 무하의 대표작: "The Seasons", "Zodiac", "Job" 포스터

---

*이 스타일 가이드는 알폰스 무하의 아르누보 예술 작품에서 영감을 받아 제작되었습니다.*
