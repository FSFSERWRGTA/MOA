import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../services/user_service.dart';
import '../services/gemini_service.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  static const purple = Color(0xFF6F6BFF);
  static const divider = Color(0xFFE8E8FF);

  bool _isLoading = true;
  String? _error;
  Key _listKey = UniqueKey();

  List<_RecommendedPlan> _cheaperPlans = [];
  List<_RecommendedPlan> _alternativeServices = [];

  // ✅ 실제 데이터로 업데이트될 변수들
  int thisMonthSpending = 0;
  int savingIfSwitched = 0; // ✅ API 응답으로 업데이트됨

  String _selectedMode = '현재 구독을 더 저렴하게';
  String _selectedCategory = 'ott';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    // ✨ 1. API 호출 전, 화면을 로딩 상태로 만들고 이전 데이터를 초기화합니다.
    setState(() {
      _isLoading = true;
      _error = null;
      _cheaperPlans = [];
      _alternativeServices = [];
    });

    try {
      // ✨ 2. 사용자 정보와 총 지출액을 가져옵니다.
      final userData = await UserService.getUserSubscriptions();
      if (mounted) {
        setState(() {
          // '이번 달 예상 지출' UI를 실제 데이터로 업데이트합니다.
          _userName = userData['userName'] ?? '사용자';
          thisMonthSpending = userData['totalSpending'];
        });
      }

      // ✨ 3. 사용자가 선택한 모드에 따라 API를 호출합니다.
      if (_selectedMode == '새로운 구독 찾기') {
        final result = await GeminiService.getNewSubscriptionSuggestions(
          selectedCategory: _selectedCategory,
        );

        // 파싱
        final newAlternativeServices = (result['suggestions'] as List? ?? [])
            .map((p) => _RecommendedPlan.fromJson(p as Map<String, dynamic>))
            .toList();

        // UI 업데이트
        if (mounted) {
          setState(() {
            _alternativeServices = newAlternativeServices;
            savingIfSwitched = 0; // 새로운 구독 찾기 모드에서는 절감액 0
            _listKey = UniqueKey();
          });
        }
      } else {
        // "현재 구독을 더 저렴하게" 모드
        final userSubsList = userData['subscriptions'] as List<UserSubscription>;
        final userSubscriptionsText = userSubsList
            .map((sub) => " - ${sub.serviceId}: 월 ${sub.price}원")
            .join('\n');

        final result = await GeminiService.getRecommendations(
          selectedMode: _selectedMode,
          selectedCategory: _selectedCategory,
          userSubscriptionsText: userSubscriptionsText,
          currentTotalSpending: thisMonthSpending,
        );

        // 파싱 (bundleOptions 제거됨)
        final newCheaperPlans = (result['cheaperPlans'] as List? ?? [])
            .map((p) => _RecommendedPlan.fromJson(p as Map<String, dynamic>))
            .toList();
        final newAlternativeServices = (result['alternativeServices'] as List? ?? [])
            .map((p) => _RecommendedPlan.fromJson(p as Map<String, dynamic>))
            .toList();
        final estimatedSavings = result['estimatedMonthlySavings'] ?? 0;

        // UI 업데이트 (bundleOptions 제거됨)
        if (mounted) {
          setState(() {
            _cheaperPlans = newCheaperPlans;
            _alternativeServices = newAlternativeServices;
            savingIfSwitched = estimatedSavings is int
                ? estimatedSavings
                : int.tryParse(estimatedSavings.toString()) ?? 0;
            _listKey = UniqueKey();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "추천 정보를 가져오는 데 실패했습니다.\n네트워크 상태를 확인하거나 잠시 후 다시 시도해주세요.";
          print("RecommendationsScreen Error: $e");
        });
      }
    } finally {
      // ✨ 4. 모든 작업(성공 또는 실패)이 끝나면 로딩 상태를 해제합니다.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    const appBg = Colors.white;

    final bool showEmptyMessage = !_isLoading &&
        _error == null &&
        _cheaperPlans.isEmpty &&
        _alternativeServices.isEmpty;

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('구독 추천', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: divider)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecommendations,
        child: ListView(
          key: _listKey,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),children: [
          // ✨ 3. 변수를 사용하여 동적으로 이름을 표시
          Text('$_userName님을 위한 구독 추천', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
            const Text('현재 구독 상황과 원하는 방향을 선택하면\n대체 플랜과 새로운 서비스를 비교해드려요.', style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
            const SizedBox(height: 18),

            _PreferenceCard(
              selectedMode: _selectedMode,
              onModeChanged: (value) {
                setState(() => _selectedMode = value);
                _fetchRecommendations();
              },
              selectedCategory: _selectedCategory,
              onCategoryChanged: (value) {
                setState(() => _selectedCategory = value);
                _fetchRecommendations();
              },
            ),
            const SizedBox(height: 16),

            // ✨ '현재 구독을 더 저렴하게' 모드일 때만 절감액 위젯을 표시
            if (_selectedMode == '현재 구독을 더 저렴하게')
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0), // 아래쪽 여백을 줌
                child: _SavingsSummaryRow(
                  thisMonthSpending: thisMonthSpending,
                  savingIfSwitched: savingIfSwitched,
                ),
              ),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: purple),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text(_error!, textAlign: TextAlign.center)),
              )
            else if (showEmptyMessage)                const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text("이 조건에 맞는 추천 항목이 없습니다.")),
              )
              else ...[

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _RecommendationGroup(
                      title: '같은 서비스의 더 저렴한 플랜',
                      subtitle: '지금 사용하는 서비스 안에서 요금제만 가볍게 조정해요.',
                      plans: _cheaperPlans,
                    ),
                  ),
                  _RecommendationGroup(
                    // ✨ 1. _selectedMode에 따라 다른 제목을 보여줍니다.
                    title: _selectedMode == '새로운 구독 찾기'
                        ? '이런 구독 서비스는 어때요?' // "새로운 구독 찾기" 모드일 때의 제목
                        : '동일 카테고리의 대체 서비스', // "더 저렴하게" 모드일 때의 제목

                    // ✨ 2. _selectedMode에 따라 다른 부제목을 보여줍니다.
                    subtitle: _selectedMode == '새로운 구독 찾기'
                        ? '관심 카테고리의 인기 서비스를 모아봤어요.' // "새로운 구독 찾기" 모드일 때의 부제목
                        : '콘텐츠 성격은 비슷하게, 가격·혜택은 더 나은 조합으로.', // "더 저렴하게" 모드일 때의 부제목
                    plans: _alternativeServices,
                  ),
                ],
// ... 다른 코드들 .
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: appBg,
        surfaceTintColor: Colors.transparent,
        selectedIndex: 2,
        onDestinationSelected: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, Routes.home);
          else if (i == 1) Navigator.pushReplacementNamed(context, Routes.subscriptions);
          else if (i == 2) return;
          else if (i == 3) Navigator.pushReplacementNamed(context, Routes.profile);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: '내 구독'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: '구독 추천'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}

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
  static const _categories = ['ott', 'ai', 'music', 'cloud', 'productivity'];

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
          const Text('어떤 방향으로 추천받을까요?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modes.map((m) {
              final selected = m == selectedMode;
              return ChoiceChip(
                label: Text(m, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF6F6BFF) : Colors.black87)),
                selected: selected,
                selectedColor: const Color(0xFFEDEBFF),
                backgroundColor: const Color(0xFFF7F7FF),
                side: BorderSide(color: selected ? const Color(0xFF6F6BFF) : _RecommendationsScreenState.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                onSelected: (_) => onModeChanged(m),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('관심있는 구독 유형', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final selected = c == selectedCategory;
              return ChoiceChip(
                label: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF6F6BFF) : Colors.black87)),
                selected: selected,
                selectedColor: const Color(0xFFEDEBFF),
                backgroundColor: const Color(0xFFF7F7FF),
                side: BorderSide(color: selected ? const Color(0xFF6F6BFF) : _RecommendationsScreenState.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                onSelected: (_) => onCategoryChanged(c),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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
        Expanded(child: _SummaryPill(label: '이번 달 예상 지출', value: _formatWon(thisMonthSpending))),
        const SizedBox(width: 12),
        Expanded(child: _SummaryPill(label: '전환 시 절감 예상액', value: _formatWon(savingIfSwitched), highlight: true)),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? const Color(0xFF6F6BFF).withOpacity(.08) : Colors.white;
    final border = highlight ? const Color(0xFF6F6BFF) : _RecommendationsScreenState.divider;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.1)),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _RecommendationGroup extends StatelessWidget {
  const _RecommendationGroup({required this.title, required this.subtitle, required this.plans});
  final String title;
  final String subtitle;
  final List<_RecommendedPlan> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
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
  final String? savingLabel;
  final String? savingPercent;
  final String summary;
  final List<String> features;
  final String why;

  bool get isDollar => price.contains('\$');

  _RecommendedPlan({
    required this.logoLetter,
    required this.serviceName,
    required this.price,
    this.savingLabel,
    this.savingPercent,
    required this.summary,
    required this.features,
    required this.why,
  });

  factory _RecommendedPlan.fromJson(Map<String, dynamic> json) {
    List<String> featuresList = [];
    final featuresData = json['features'];

    if (featuresData is List) {
      // 1. 정상적으로 리스트가 올 경우
      featuresList = featuresData.map((e) => e.toString()).toList();
    } else if (featuresData is String) {
      // 2. 통 문자열로 올 경우 (예: "핵심 기능 1, 핵심 기능 2")
      // 쉼표나 줄바꿈으로 분리하여 리스트로 변환
      featuresList = featuresData
          .split(RegExp(r'[,|•\n]')) // 쉼표, •, 줄바꿈 기준으로 분리
          .map((e) => e.trim()) // 각 항목의 양쪽 공백 제거
          .where((e) => e.isNotEmpty) // 빈 항목은 리스트에 추가하지 않음
          .toList();
    }
    // 3. 그 외 타입(null 등)이 오면 빈 리스트로 유지됩니다.

    return _RecommendedPlan(
      logoLetter: json['logoLetter']?.toString() ?? '?',
      serviceName: json['serviceName']?.toString() ?? '이름 없음',
      price: json['price']?.toString() ?? '가격 정보 없음',
      savingLabel: json['savingLabel']?.toString() ?? '',
      savingPercent: json['savingPercent']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '요약 정보가 없습니다.',
      features: featuresList, // ✅ 안전하게 변환된 리스트 사용
      why: json['why']?.toString() ?? '추천 이유가 없습니다.',
    );
  }
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF1F0FF), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(plan.logoLetter, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF6F6BFF)))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.serviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(plan.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ✨✨✨ 결정적인 수정 ✨✨✨
          // 만약 plan.isDollar가 true이면(달러 기반이면), 이 부분을 아예 그리지 않습니다.
          // 또한 savingLabel에 내용이 있을 때만 이 부분을 그립니다.
          if (!plan.isDollar && plan.savingLabel != null && plan.savingLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF6F6BFF).withOpacity(.06), borderRadius: BorderRadius.circular(999)),
                    child: Text(plan.savingLabel!),
                  ),
                ],
              ),
            ),

          Text(plan.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          ...plan.features.take(3).map(
                (f) => Text('• $f', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
