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

  int thisMonthSpending = 0;
  int savingIfSwitched = 0;

  String _selectedMode = '현재 구독을 더 저렴하게';
  String _selectedCategory = 'ott';
  String _userName = '';
  Set<String> _subscribedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cheaperPlans = [];
      _alternativeServices = [];
    });

    try {
      final userData = await UserService.getUserSubscriptions();
      final userSubsList = userData['subscriptions'] as List<UserSubscription>;

      final newSubscribedCategories = userSubsList.map((sub) {
        String category = sub.serviceType.toLowerCase();
        if (category == 'ai 툴') return 'ai';
        return category;
      }).toSet();

      if (mounted) {
        setState(() {
          _userName = userData['userName'] ?? '사용자';
          thisMonthSpending = userData['totalSpending'];
          _subscribedCategories = newSubscribedCategories;
        });
      }

      if (_selectedMode == '새로운 구독 찾기') {
        final result = await GeminiService.getNewSubscriptionSuggestions(
          selectedCategory: _selectedCategory,
        );
        final newAlternativeServices = (result['suggestions'] as List? ?? [])
            .map((p) => _RecommendedPlan.fromJson(p as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _alternativeServices = newAlternativeServices;
            savingIfSwitched = 0;
            _listKey = UniqueKey();
          });
        }
      } else {
        if (!newSubscribedCategories.contains(_selectedCategory)) {
          print("코드 레벨에서 차단: 사용자가 구독하지 않는 카테고리($_selectedCategory)입니다.");
          if (mounted) {
            setState(() {
              _cheaperPlans = [];
              _alternativeServices = [];
              savingIfSwitched = 0;
              _listKey = UniqueKey();
              _isLoading = false;
            });
          }
          return;
        }

        final userSubscriptionsText = userSubsList
            .map((sub) => " - ${sub.serviceId}: 월 ${sub.price}원 (카테고리: ${sub.serviceType})")
            .join('\n');

        final result = await GeminiService.getRecommendations(
          selectedMode: _selectedMode,
          selectedCategory: _selectedCategory,
          userSubscriptionsText: userSubscriptionsText,
          currentTotalSpending: thisMonthSpending,
        );
        final currentUserServicesInCategory = userSubsList
            .where((sub) => sub.serviceType.toLowerCase() == _selectedCategory)
            .map((sub) => sub.serviceId.toLowerCase())
            .toSet();

        final allSuggestedPlans = [
          ...(result['cheaperPlans'] as List? ?? []).map((p) => _RecommendedPlan.fromJson(p as Map<String, dynamic>)),
          ...(result['alternativeServices'] as List? ?? []).map((p) => _RecommendedPlan.fromJson(p as Map<String, dynamic>)),
        ];

        List<_RecommendedPlan> finalCheaperPlans = [];
        List<_RecommendedPlan> finalAlternativeServices = [];

        for (final plan in allSuggestedPlans) {
          if (currentUserServicesInCategory.contains(plan.serviceName.toLowerCase())) {
            finalCheaperPlans.add(plan);
          } else {
            finalAlternativeServices.add(plan);
          }
        }

        final estimatedSavings = result['estimatedMonthlySavings'] ?? 0;

        if (mounted) {
          setState(() {
            _cheaperPlans = finalCheaperPlans;
            _alternativeServices = finalAlternativeServices;
            savingIfSwitched = estimatedSavings is int
                ? estimatedSavings
                : int.tryParse(estimatedSavings.toString()) ?? 0;
            _listKey = UniqueKey();
          });
        }
      }
    } catch (e, s) {
      if (mounted) {
        setState(() {
          _error = "추천 정보를 가져오는 데 실패했습니다.\n네트워크 상태를 확인하거나 잠시 후 다시 시도해주세요.";
          print("RecommendationsScreen Error: $e\n$s");
        });
      }
    } finally {
      if (mounted) {
        if (_isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
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

    final bool isAlreadyOnCheapestPlan = !_isLoading &&
        _error == null &&
        _selectedMode == '현재 구독을 더 저렴하게' &&
        _subscribedCategories.contains(_selectedCategory) &&
        _cheaperPlans.isEmpty &&
        _alternativeServices.isNotEmpty;

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
            subscribedCategories: _subscribedCategories,
          ),
          const SizedBox(height: 16),

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
                if (isAlreadyOnCheapestPlan)
                  const Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('같은 서비스의 더 저렴한 플랜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('지금 사용하는 서비스 안에서 요금제만 가볍게 조정해요.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          SizedBox(height: 24),
                          Center(
                            child: Text(
                              "이미 가장 저렴한 플랜을 이용 중이에요!",
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      )
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _RecommendationGroup(
                      title: '같은 서비스의 더 저렴한 플랜',
                      subtitle: '지금 사용하는 서비스 안에서 요금제만 가볍게 조정해요.',
                      plans: _cheaperPlans,
                    ),
                  ),
                _RecommendationGroup(
                  title: _selectedMode == '새로운 구독 찾기'
                      ? '이런 구독 서비스는 어때요?'
                      : '동일 카테고리의 대체 서비스',
                  subtitle: _selectedMode == '새로운 구독 찾기'
                      ? '관심 카테고리의 인기 서비스를 모아봤어요.'
                      : '콘텐츠 성격은 비슷하게, 가격·혜택은 더 나은 조합으로.',
                  plans: _alternativeServices,
                ),
              ],
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
    required this.subscribedCategories,
  });

  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Set<String> subscribedCategories;

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
              final bool isAlreadySubscribed =
                  selectedMode == '새로운 구독 찾기' && subscribedCategories.contains(c);

              return Opacity(
                opacity: isAlreadySubscribed ? 0.5 : 1.0,
                child: ChoiceChip(
                  label: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF6F6BFF) : Colors.black87)),
                  selected: selected,
                  selectedColor: const Color(0xFFEDEBFF),
                  backgroundColor: const Color(0xFFF7F7FF),
                  side: BorderSide(color: selected ? const Color(0xFF6F6BFF) : _RecommendationsScreenState.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  onSelected: (_) => onCategoryChanged(c),
                ),
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
      featuresList = featuresData.map((e) => e.toString()).toList();
    } else if (featuresData is String) {
      featuresList = featuresData
          .split(RegExp(r'[,|•\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return _RecommendedPlan(
      logoLetter: json['logoLetter']?.toString() ?? '?',
      serviceName: json['serviceName']?.toString() ?? '이름 없음',
      price: json['price']?.toString() ?? '가격 정보 없음',
      savingLabel: json['savingLabel']?.toString() ?? '',
      savingPercent: json['savingPercent']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '요약 정보가 없습니다.',
      features: featuresList,
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