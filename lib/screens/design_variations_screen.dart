import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// 두 가지 스타일 시안을 한 화면에서 비교해볼 수 있는 탭 뷰
class DesignVariationsScreen extends StatelessWidget {
  const DesignVariationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('디자인 시안'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '알폰스 무하 감성'),
              Tab(text: 'WPI 웹 감성'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MuchaInspiredDesign(),
            _WpiWebInspiredDesign(),
          ],
        ),
      ),
    );
  }
}

class _MuchaInspiredDesign extends StatelessWidget {
  const _MuchaInspiredDesign();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9E6D3),
            Color(0xFFFBEFE4),
            Color(0xFFF4D7C4),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MuchaHero(theme: theme),
              const SizedBox(height: 24),
              _PaletteRow(
                title: '팔레트',
                colors: const [
                  Color(0xFF1F6F8B),
                  Color(0xFFC47C56),
                  Color(0xFFE9C19E),
                  Color(0xFFF4E3D7),
                  Color(0xFF6C4A3D),
                ],
              ),
              const SizedBox(height: 20),
              _MuchaInfoCard(
                title: '아르누보 장식',
                description:
                    '곡선 장식, 얇은 금박 라인, 그리고 꽃잎을 닮은 반원형 모티프를 넣어 무하 특유의 프레임을 구현합니다. 배경에는 반투명 문양을 겹겹이 깔아 깊이를 만듭니다.',
                icon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 14),
              _MuchaInfoCard(
                title: '타이포그래피',
                description:
                    '제목은 세리프 계열(예: Playfair Display), 본문은 가독성 높은 산세리프(예: Noto Sans) 조합을 사용합니다. 제목은 드롭캡처럼 여백을 넓게 두고, 밑줄 장식을 금색으로 추가합니다.',
                icon: Icons.font_download,
              ),
              const SizedBox(height: 14),
              _MuchaInfoCard(
                title: '콘텐츠 레이아웃',
                description:
                    '상단에 보석톤 그라데이션 헤더와 아르누보 프레임을 배치하고, 카드에는 텍스처가 느껴지는 베이지 배경을 사용합니다. CTA 버튼은 에메랄드 컬러에 둥근 금색 테두리를 적용합니다.',
                icon: Icons.grid_view,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/7/7d/Mucha_-_Mo%C3%ABt_%26_Chandon_Cr%C3%A9mant_Imp%C3%A9rial.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Art Nouveau Mood',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '꽃잎, 곡선, 금빛 라인을 활용해 무하 감성을 현대적으로 재해석한 히어로 배경입니다.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuchaHero extends StatelessWidget {
  const _MuchaHero({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2B5F73),
                Color(0xFF1D2F3B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9B08C).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFFD9B08C)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '알폰스 무하 스타일',
                  style: TextStyle(
                    color: Color(0xFFF8E9D2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '곡선과 금빛 라인으로 완성하는
아르누보 감성의 WPI',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '꽃잎을 닮은 레이아웃, 빈티지 베이지 톤,
금빛 디테일이 어우러진 프리미엄 무드',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.palette_rounded),
                    label: const Text('컬러 가이드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9B08C),
                      foregroundColor: const Color(0xFF1F2A30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF8E9D2),
                      side: const BorderSide(color: Color(0xFFD9B08C)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('상세 모티프 보기'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: -10,
          top: -10,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF4E3D7).withOpacity(0.9),
                  const Color(0xFFE5C7A0).withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.waves_rounded,
              size: 48,
              color: Color(0xFF6C4A3D),
            ),
          ),
        ),
      ],
    );
  }
}

class _MuchaInfoCard extends StatelessWidget {
  const _MuchaInfoCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0DCC5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4E3D7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF6C4A3D)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF3E2D25),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5F4C43),
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.title, required this.colors});

  final String title;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E2D25),
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: colors
              .map(
                (color) => Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _WpiWebInspiredDesign extends StatelessWidget {
  const _WpiWebInspiredDesign();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _WpiHero(theme: theme),
              const SizedBox(height: 20),
              _InfoSection(
                title: '빠른 CTA 배치',
                description:
                    '상단에 "WPI 로그인"과 "검사 결과 확인" 버튼을 배치해 주요 흐름을 한 번에 안내합니다. 버튼은 WPI 사이트의 그라데이션 톤을 참고한 블루/민트 컬러를 사용합니다.',
                icon: Icons.touch_app_outlined,
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: '카드형 정보 구조',
                description:
                    '각 프로그램, 전문가 정보, 상담 신청 흐름을 카드 단위로 나누고, 부드러운 음영과 둥근 모서리로 가독성을 높입니다. 중요 안내는 노란색 강조 박스로 표시합니다.',
                icon: Icons.view_agenda_outlined,
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: '신뢰도 강화 요소',
                description:
                    '통계, 후기, 지도 섹션을 별도 카드로 배치해 신뢰도를 높이는 구성을 그대로 가져옵니다. 차트/리스트 컴포넌트는 여백과 분리선을 넉넉히 주어 명확히 구분합니다.',
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 24),
              _GridCards(theme: theme),
              const SizedBox(height: 20),
              _AlertBanner(theme: theme),
              const SizedBox(height: 20),
              _FooterLinks(theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _WpiHero extends StatelessWidget {
  const _WpiHero({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3AA0FF), Color(0xFF6AE3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WPI 웹 감성',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '기존 사이트의 구조와 버튼 톤을 계승한
깔끔하고 신뢰감 있는 레이아웃',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.widgets_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E77D0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('WPI 로그인'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('검사 결과 확인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E77D0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCards extends StatelessWidget {
  const _GridCards({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GridCardData('WPI 현실', '현실 성향 검사', Icons.sentiment_satisfied_alt),
      _GridCardData('WPI 이상', '이상 성향 검사', Icons.auto_awesome),
      _GridCardData('WPI 간편', '10문항 요약 검사', Icons.flash_on),
      _GridCardData('WPI커리어', '직업 성향 검사', Icons.business_center),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (_, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                card.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                card.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridCardData {
  _GridCardData(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4A3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: Color(0xFFCB9900)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '유사 사이트 주의 안내',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A7A00),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'WPI 심리검사는 본 페이지와 한국판 WPI 사이트에서만 제공됩니다. 공식 링크 외 접속을 피해주세요.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8A6D00),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '오시는 길',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('지도 열기'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '주소, 연락처, 진료시간을 담은 푸터 섹션입니다. 실제 지도/연락처 컴포넌트를 연동해 신뢰도를 높일 수 있습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
