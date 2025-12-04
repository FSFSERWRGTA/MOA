import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../routes/app_router.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  static const purple = Color(0xFF6F6BFF);
  static const appBg = Colors.white;
  static const divider = Color(0xFFE8E8FF);

  // --- 상태 변수 ---
  bool _isLoading = true;
  List<_SubItem> _items = [];

  // 요약값 (초기값, 데이터 로드 후 업데이트됨)
  int thisMonthSpending = 0;
  int activeCount = 0;
  DateTime nextBillingDate = DateTime.now();

  // 검색/필터/정렬용
  String _query = '';
  String _filter = '전체'; // 전체/활성/일시중지
  static const String _kDefaultSort = '결제일 빠른순';
  String? _sort = _kDefaultSort;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  /// Firestore에서 구독 정보를 불러옵니다.
  Future<void> _loadSubscriptions() async {
    // TODO: 실제 앱에서는 로그인된 사용자 ID를 동적으로 가져와야 합니다.
    // 예: final userId = FirebaseAuth.instance.currentUser?.uid;
    const userId = 'duri'; // 현재는 'duri' 사용자로 고정

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .get();

      // Firestore 문서들을 _SubItem 객체로 변환
      final fetchedItems = snapshot.docs.map((doc) {
        final data = doc.data();
        final nextRenewalAt = (data['nextRenewalAt'] as Timestamp?)?.toDate();
        final nextDateStr =
            nextRenewalAt != null ? _formatDate(nextRenewalAt) : 'N/A';

        return _SubItem(
          data['providerName'] as String? ?? '이름 없음',
          _formatWon(data['amount'] as int? ?? 0),
          nextDateStr,
          data['planName'] as String? ?? '',
          (data['status'] as String? ?? 'inactive') == 'active',
          data['category'] as String? ?? '기타',
        );
      }).toList();

      _calculateSummaries(fetchedItems);
    } catch (e) {
      print('구독 정보 로딩 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구독 정보를 불러오는 데 실패했습니다.')),
        );
      }
    }
  }

  /// 불러온 데이터를 기반으로 요약 정보를 계산하고 상태를 업데이트합니다.
  void _calculateSummaries(List<_SubItem> items) {
    int newActiveCount = 0;
    int newThisMonthSpending = 0;
    DateTime? nextDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final item in items) {
      if (item.active) {
        newActiveCount++;

        final month = _monthOf(item.nextDate);
        if (month == now.month) {
          newThisMonthSpending += _parseWon(item.price);
        }

        final parts = item.nextDate.split('/');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]);
          final d = int.tryParse(parts[1]);
          if (m != null && d != null) {
            var potentialNextDate = DateTime(now.year, m, d);
            if (potentialNextDate.isBefore(today)) {
              potentialNextDate = DateTime(now.year + 1, m, d);
            }
            if (nextDate == null || potentialNextDate.isBefore(nextDate)) {
              nextDate = potentialNextDate;
            }
          }
        }
      }
    }

    setState(() {
      _items = items;
      activeCount = newActiveCount;
      thisMonthSpending = newThisMonthSpending;
      if (nextDate != null) nextBillingDate = nextDate;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 검색/필터/정렬(목록용)
    final visible = _items.where((e) {
      final hit = e.name.toLowerCase().contains(_query.toLowerCase());
      final ok = switch (_filter) {
        '전체' => true,
        '활성' => e.active,
        '일시중지' => !e.active,
        _ => true,
      };
      return hit && ok;
    }).toList()
      ..sort((a, b) {
        switch (_sort ?? _kDefaultSort) {
          case '가격 높은순':
            final pa = _parseWon(a.price);
            final pb = _parseWon(b.price);
            return pb.compareTo(pa);
          case '이름':
            return a.name.compareTo(b.name);
          case '결제일 빠른순':
          default:
            return a.nextDate.compareTo(b.nextDate);
        }
      });

    // 카테고리별 지출: 이번 달 + 활성만 (검색/필터 무관)
    final now = DateTime.now();
    final Map<String, int> categoryTotals = {};
    for (final it in _items) {
      if (!it.active) continue;
      final m = _monthOf(it.nextDate);
      if (m != now.month) continue;
      final v = _parseWon(it.price);
      categoryTotals.update(it.category, (prev) => prev + v, ifAbsent: () => v);
    }

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'MOA',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '결제 달력',
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black87,
            ),
            onPressed: _openCalendarSheet,
          ),
          IconButton(
            tooltip: '홈으로',
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, Routes.home),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                const Text(
                  '내 구독',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // 요약 패널
                _SummaryPanel(
                  monthSpendingText: _formatWon(thisMonthSpending),
                  activeCountText: '$activeCount개',
                  nextBillingLabel: _formatDate(nextBillingDate),
                  nextBillingDday: _dDay(nextBillingDate),
                  onTapNextBilling: _openCalendarSheet,
                ),
                const SizedBox(height: 16),

                // 검색
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: '구독명 검색',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 필터 + 정렬
                Row(
                  children: [
                    _FilterChip(
                      label: '전체',
                      selected: _filter == '전체',
                      onTap: () => setState(() => _filter = '전체'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: '활성',
                      selected: _filter == '활성',
                      onTap: () => setState(() => _filter = '활성'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: '일시중지',
                      selected: _filter == '일시중지',
                      onTap: () => setState(() => _filter = '일시중지'),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: '정렬',
                      onSelected: (v) => setState(() => _sort = v),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: '결제일 빠른순', child: Text('결제일 빠른순')),
                        PopupMenuItem(value: '가격 높은순', child: Text('가격 높은순')),
                        PopupMenuItem(value: '이름', child: Text('이름')),
                      ],
                      child: Row(
                        children: [
                          Text(
                            _sort ?? _kDefaultSort,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 카테고리별 지출 (이번 달 · 활성)
                if (categoryTotals.isNotEmpty) ...[
                  const Text(
                    '카테고리별 지출 (이번 달 · 활성)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _CategoryBars(data: categoryTotals),
                  const SizedBox(height: 18),
                ],

                // 리스트
                ...visible.map((e) => _SubCard(item: e, accent: purple)),
                if (visible.isEmpty && !_isLoading)
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: divider),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.inbox_outlined),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text('조건에 맞는 구독이 없어요. 필터나 검색어를 조정해보세요.')),
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: appBg,
        surfaceTintColor: Colors.transparent,
        selectedIndex: 1, // 내 구독 탭
        onDestinationSelected: (i) {
          // if (i == 0) {
          //   // 홈으로 이동
          //   Navigator.pushReplacementNamed(context, Routes.home);
          // } else if (i == 1) {
          //   // 현재 페이지: 아무것도 하지 않음
          //   return;
          // } else if (i == 2) {
          //   // 추천 페이지로 이동
          //   Navigator.pushReplacementNamed(context, Routes.recommendations);
          // } else if (i == 3) {
          //   // 프로필 페이지로 이동
          //   Navigator.pushReplacementNamed(context, Routes.profile);
          // }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '내 구독',
          ),
          NavigationDestination(icon: Icon(Icons.star_border), label: '추천'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigator.pushNamed(context, Routes.addSubscription);
        },
        backgroundColor: const Color(0xFFEDEBFF),
        icon: const Icon(Icons.add, color: Color(0xFF6F6BFF)),
        label: const Text('구독 추가', style: TextStyle(color: Color(0xFF6F6BFF))),
      ),
    );
  }

  // ---------------- 달력 바텀시트 (마커/오버플로우 방지) ----------------
  void _openCalendarSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: appBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        DateTime selected = DateTime.now();

        List<_SubItem> itemsOf(DateTime d) {
          final mm = d.month.toString().padLeft(2, '0');
          final dd = d.day.toString().padLeft(2, '0');
          return _items
              .where((e) => e.active && e.nextDate == '$mm/$dd')
              .toList();
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => SafeArea(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: StatefulBuilder(
                builder: (context, setSheet) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        '결제 달력',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MiniCalendar(
                      initialMonth: DateTime.now(),
                      hasPaymentOn: (d) => itemsOf(d).isNotEmpty,
                      onSelect: (d) => setSheet(() => selected = d),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '선택일 결제 ${itemsOf(selected).length}건',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...itemsOf(
                      selected,
                    ).map((e) => _SubCard(item: e, accent: purple)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- 유틸 ----------------
  int _parseWon(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  int _monthOf(String mmdd) {
    final sp = mmdd.split('/');
    if (sp.isEmpty) return DateTime.now().month;
    return int.tryParse(sp[0]) ?? DateTime.now().month;
  }

  String _formatWon(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left % 3 == 0 && left != 0) buf.write(',');
    }
    return '₩${buf.toString()}';
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _dDay(DateTime d) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return '오늘';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }
}

/* ================= 위젯들 ================= */

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.monthSpendingText,
    required this.activeCountText,
    required this.nextBillingLabel,
    required this.nextBillingDday,
    this.onTapNextBilling,
  });
  final String monthSpendingText;
  final String activeCountText;
  final String nextBillingLabel;
  final String nextBillingDday;
  final VoidCallback? onTapNextBilling;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SubscriptionsScreenState.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCol('이번 달 지출', monthSpendingText),
          _buildCol('활성 구독', activeCountText),
          InkWell(
            onTap: onTapNextBilling,
            borderRadius: BorderRadius.circular(8),
            child: _buildCol(
              '다음 결제일',
              nextBillingLabel,
              sub: nextBillingDday,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCol(String label, String value, {String? sub}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (sub != null)
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _SubscriptionsScreenState.purple,
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? const Color(0xFFEDEBFF) : Colors.white;
    final Color border = selected
        ? _SubscriptionsScreenState.purple
        : _SubscriptionsScreenState.divider;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: bg,
      backgroundColor: bg,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (s, v) => s + v);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((e) {
        final ratio = total == 0 ? 0.0 : e.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '₩${_formatComma(e.value)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Container(
                      height: 10,
                      width: c.maxWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F0FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _SubscriptionsScreenState.divider,
                        ),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: c.maxWidth * ratio,
                      decoration: BoxDecoration(
                        color: _SubscriptionsScreenState.purple.withOpacity(.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static String _formatComma(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      final left = s.length - i - 1;
      if (left % 3 == 0 && left != 0) b.write(',');
    }
    return b.toString();
  }
}

// 달력 위젯 (여기서는 구현을 생략, 기존 코드에 있다고 가정)
class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({this.initialMonth, this.hasPaymentOn, this.onSelect});
  final DateTime? initialMonth;
  final bool Function(DateTime)? hasPaymentOn;
  final void Function(DateTime)? onSelect;

  @override
  Widget build(BuildContext context) {
    // 실제 앱에서는 TableCalendar 같은 패키지를 사용하여 구현합니다.
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: _SubscriptionsScreenState.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('여기에 달력이 표시됩니다.'),
    );
  }
}


class _SubItem {
  final String name;
  final String price; // "₩x,xxx"
  final String nextDate; // "MM/DD"
  final String note;
  final bool active;
  final String category;
  _SubItem(
    this.name,
    this.price,
    this.nextDate,
    this.note,
    this.active,
    this.category,
  );
}

class _SubCard extends StatelessWidget {
  const _SubCard({required this.item, required this.accent});
  final _SubItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.active ? Colors.green : Colors.orange;
    final statusText = item.active ? '활성' : '일시중지';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SubscriptionsScreenState.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.subscriptions_outlined, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.note,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.price,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('다음 결제: ${item.nextDate}'),
            ],
          )
        ],
      ),
    );
  }
}
