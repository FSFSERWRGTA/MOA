import 'package:flutter/material.dart';
import '../routes/app_router.dart';

// 구독 추천 메인 화면
// - 하단 탭에서 "구독 추천"을 눌렀을 때 진입하는 페이지
// - 이후 Gemini + 크롤링 결과를 이 UI에 바인딩해서 사용
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  static const purple = Color(0xFF6F6BFF);
  static const divider = Color(0xFFE8E8FF);

  // 샘플값
  int thisMonthSpending = 23500; // 이번 달 현재 예상 지출
  int savingIfSwitched = 7200; // 전환 시 예상 절감액

  // 선택 상태 (UI 인터랙션용)
  String _selectedMode = '현재 구독을 더 저렴하게'; // or '새로운 구독 찾기'
  String _selectedCategory = '스트리밍';

  // 데모용 데이터 3묶음
  final List<_RecommendedPlan> _cheaperPlans = [
    _RecommendedPlan(
      logoLetter: 'N',
      serviceName: 'Netflix 스탠다드 → 베이식',
      price: '₩9,500/월',
      savingLabel: '월 ₩4,000 절감',
      savingPercent: '-29%',
      summary: '동일한 콘텐츠를 더 저렴한 화질로 이용하는 플랜',
      features: ['동시 접속 1인', 'FHD 미지원', '광고 없음'],
      why: '지금 시청 패턴 기준, 화질보다 가격 절감 효과가 더 큼',
    ),
    _RecommendedPlan(
      logoLetter: 'Y',
      serviceName: 'YouTube Premium 패밀리 → 개인',
      price: '₩10,450/월',
      savingLabel: '월 ₩3,000 절감',
      savingPercent: '-22%',
      summary: '실제 사용 인원이 1인일 때 더 효율적인 플랜',
      features: ['백그라운드 재생', '오프라인 저장', '광고 제거'],
      why: '가족 계정 구성원이 적을수록 개인 플랜이 더 economical',
    ),
  ];

  final List<_RecommendedPlan> _alternativeServices = [
    _RecommendedPlan(
      logoLetter: 'D',
      serviceName: 'Disney+ 기본 플랜',
      price: '₩9,900/월',
      savingLabel: '유사 가격대',
      savingPercent: '~',
      summary: '디즈니·픽사·마블 등 IP 중심의 스트리밍',
      features: ['마블/디즈니 독점', '4K 지원', '동시 4기기'],
      why: '현재 보유 OTT와 겹치지 않는 IP라 콘텐츠 다양성에 도움',
    ),
    _RecommendedPlan(
      logoLetter: 'W',
      serviceName: '왓챠 기본 플랜',
      price: '₩7,900/월',
      savingLabel: '월 ₩2,000 절감',
      savingPercent: '-20%',
      summary: '국내 콘텐트와 아트하우스 중심 대체 OTT',
      features: ['국내 드라마 강점', '컬렉션 기능', '추천 알고리즘'],
      why: '비슷한 장르를 선호하지만 로컬 콘텐츠 비중이 높을 때 적합',
    ),
  ];

  final List<_RecommendedPlan> _bundleOptions = [
    _RecommendedPlan(
      logoLetter: 'A',
      serviceName: 'Apple One 개인',
      price: '₩16,900/월',
      savingLabel: '단일 가입 대비 월 ₩5,000 절감',
      savingPercent: '-23%',
      summary: 'iCloud + Apple Music + TV+ 번들 패키지',
      features: ['iCloud 50GB', 'Apple Music', 'Apple TV+'],
      why: '이미 iCloud/Apple Music 중 2개 이상 사용한다면 번들이 더 저렴',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const appBg = Colors.white;

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          '구독 추천',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // 상단 인사/설명
          const Text(
            '키움님을 위한 구독 추천',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '현재 구독 상황과 원하는 방향을 선택하면\n대체 플랜과 새로운 서비스를 비교해드려요.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),

          // 1) 추천 기준 선택 카드
          _PreferenceCard(
            selectedMode: _selectedMode,
            onModeChanged: (value) {
              setState(() => _selectedMode = value);
            },
            selectedCategory: _selectedCategory,
            onCategoryChanged: (value) {
              setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 16),

          // 2) 이번 달 예상 지출 / 절감액 요약
          _SavingsSummaryRow(
            thisMonthSpending: thisMonthSpending,
            savingIfSwitched: savingIfSwitched,
          ),
          const SizedBox(height: 24),

          // 3-1) 같은 서비스의 더 저렴한 플랜
          _RecommendationGroup(
            title: '같은 서비스의 더 저렴한 플랜',
            subtitle: '지금 사용하는 서비스 안에서 요금제만 가볍게 조정해요.',
            plans: _cheaperPlans,
          ),
          const SizedBox(height: 22),

          // 3-2) 동일 카테고리 대체 서비스
          _RecommendationGroup(
            title: '동일 카테고리의 대체 서비스',
            subtitle: '콘텐츠 성격은 비슷하게, 가격·혜택은 더 나은 조합으로.',
            plans: _alternativeServices,
          ),
          const SizedBox(height: 22),

          // 3-3) 번들 / 패키지 옵션
          _RecommendationGroup(
            title: '번들 / 패키지 옵션',
            subtitle: '여러 개를 따로 구독 중이라면, 묶어서 더 저렴하게.',
            plans: _bundleOptions,
          ),
        ],
      ),

      // 하단 네비게이션 (4개 탭: 홈 / 내 구독 / 구독 추천 / 프로필)
      bottomNavigationBar: NavigationBar(
        backgroundColor: appBg,
        surfaceTintColor: Colors.transparent,
        selectedIndex: 2, // 구독 추천 탭
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, Routes.home);
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, Routes.subscriptions);
          } else if (i == 2) {
            // 현재 탭: 아무 것도 하지 않음
            return;
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, Routes.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '내 구독',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            label: '구독 추천',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}

// 상단: 추천 기준/카테고리 선택 카드
class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.selectedMode,
    required this.onModeChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  static const _modes = ['현재 구독을 더 저렴하게', '새로운 구독 찾기'];

  static const _categories = ['스트리밍', '음악', 'AI 도구', '클라우드', '생산성'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RecommendationsScreenState.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어떤 방향으로 추천받을까요?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),

          // 추천 모드 선택 (두 개 중 택1)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modes.map((m) {
              final selected = m == selectedMode;
              return ChoiceChip(
                label: Text(
                  m,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? const Color(0xFF6F6BFF) : Colors.black87,
                  ),
                ),
                selected: selected,
                selectedColor: const Color(0xFFEDEBFF),
                backgroundColor: const Color(0xFFF7F7FF),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF6F6BFF)
                      : _RecommendationsScreenState.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                onSelected: (_) => onModeChanged(m),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text(
            '관심있는 구독 유형',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // 카테고리 선택
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final selected = c == selectedCategory;
              return ChoiceChip(
                label: Text(
                  c,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? const Color(0xFF6F6BFF) : Colors.black87,
                  ),
                ),
                selected: selected,
                selectedColor: const Color(0xFFEDEBFF),
                backgroundColor: const Color(0xFFF7F7FF),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF6F6BFF)
                      : _RecommendationsScreenState.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                onSelected: (_) => onCategoryChanged(c),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// 요약: 이번 달 예상 지출 / 절감 예상액
class _SavingsSummaryRow extends StatelessWidget {
  const _SavingsSummaryRow({
    required this.thisMonthSpending,
    required this.savingIfSwitched,
  });

  final int thisMonthSpending;
  final int savingIfSwitched;

  String _formatWon(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      final left = s.length - i - 1;
      if (left % 3 == 0 && left != 0) b.write(',');
    }
    return '₩${b.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(
            label: '이번 달 예상 지출',
            value: _formatWon(thisMonthSpending),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryPill(
            label: '전환 시 절감 예상액',
            value: _formatWon(savingIfSwitched),
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? const Color(0xFF6F6BFF).withOpacity(.08)
        : Colors.white;
    final border = highlight
        ? const Color(0xFF6F6BFF)
        : _RecommendationsScreenState.divider;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// 추천 카드 그룹 + 개별 카드
class _RecommendationGroup extends StatelessWidget {
  const _RecommendationGroup({
    required this.title,
    required this.subtitle,
    required this.plans,
  });

  final String title;
  final String subtitle;
  final List<_RecommendedPlan> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // 가로 슬라이드 카드 리스트
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _RecommendationCard(plan: plans[i]),
          ),
        ),
      ],
    );
  }
}

class _RecommendedPlan {
  final String logoLetter;
  final String serviceName;
  final String price;
  final String savingLabel;
  final String savingPercent;
  final String summary;
  final List<String> features;
  final String why;

  _RecommendedPlan({
    required this.logoLetter,
    required this.serviceName,
    required this.price,
    required this.savingLabel,
    required this.savingPercent,
    required this.summary,
    required this.features,
    required this.why,
  });
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.plan});
  final _RecommendedPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RecommendationsScreenState.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 로고 + 서비스명 + 가격
          Row(
            children: [
              // 로고 박스 (임시 이니셜)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    plan.logoLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6F6BFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.price,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 절감 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F6BFF).withOpacity(.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.savingLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F6BFF),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                plan.savingPercent,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 요약
          Text(
            plan.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 6),

          // 핵심 기능 3개
          ...plan.features
              .take(3)
              .map(
                (f) => Text(
                  '• $f',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),

          const Spacer(),
          const Divider(height: 12),
          Text(
            plan.why,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
