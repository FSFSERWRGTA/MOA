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

  // 요약값
  int thisMonthSpending = 23650;
  int activeCount = 3;
  DateTime nextBillingDate = DateTime(DateTime.now().year, 11, 5);

  // 데모 데이터(카테고리 필드 추가)
  final List<_SubItem> _items = [
    _SubItem('Netflix', '₩9,500', '11/05', '베이식 요금제', true, '영상'),
    _SubItem('YouTube Premium', '₩10,450', '11/08', '개인', true, '영상'),
    _SubItem('iCloud 200GB', '₩3,700', '11/10', '스토리지', true, '클라우드'),
    _SubItem('Disney+', '₩9,900', '11/18', '스탠다드', false, '영상'),
  ];

  String _query = '';
  String _filter = '전체'; // 전체/활성/일시중지
  static const String _kDefaultSort = '결제일 빠른순';
  String? _sort = _kDefaultSort;

  @override
  Widget build(BuildContext context) {
    // 검색/필터/정렬(목록용)
    final visible =
        _items.where((e) {
          final hit = e.name.toLowerCase().contains(_query.toLowerCase());
          final ok = switch (_filter) {
            '전체' => true,
            '활성' => e.active,
            '일시중지' => !e.active,
            _ => true,
          };
          return hit && ok;
        }).toList()..sort((a, b) {
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
      body: ListView(
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
          if (visible.isEmpty)
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
                  Expanded(child: Text('조건에 맞는 구독이 없어요. 필터나 검색어를 조정해보세요.')),
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
          if (i == 0) {
            // 홈으로 이동
            Navigator.pushReplacementNamed(context, Routes.home);
          } else if (i == 1) {
            // 현재 페이지: 아무것도 하지 않음
            return;
          } else if (i == 2) {
            // 추천 페이지로 이동
            Navigator.pushReplacementNamed(context, Routes.recommendations);
          } else if (i == 3) {
            // 프로필 페이지로 이동
            Navigator.pushReplacementNamed(context, Routes.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '내 구독',
          ),
          NavigationDestination(icon: Icon(Icons.star_border), label: '추천'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.addSubscription);
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
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.nextDate} • ${item.note} • ${item.category}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.price,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 요약 패널(3열). 라벨/값 폰트 사이즈와 기준선을 통일해 줄바꿈/높낮이 차이를 제거.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.monthSpendingText,
    required this.activeCountText,
    required this.nextBillingLabel,
    required this.nextBillingDday,
    required this.onTapNextBilling,
  });

  final String monthSpendingText;
  final String activeCountText;
  final String nextBillingLabel; // ex) 11/05
  final String nextBillingDday; // ex) D-4
  final VoidCallback onTapNextBilling;

  static const _labelStyle = TextStyle(
    fontSize: 12,
    height: 1.1,
    color: Colors.black54,
    fontWeight: FontWeight.w600,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const _valueStyle = TextStyle(
    fontSize: 13.5,
    height: 1.1,
    color: Colors.black87,
    fontWeight: FontWeight.w800,
    leadingDistribution: TextLeadingDistribution.even,
  );

  Widget _vline() => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: _SubscriptionsScreenState.divider,
  );

  Widget _item({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _SubscriptionsScreenState.purple, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Baseline(
                baselineType: TextBaseline.alphabetic,
                baseline: 14,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  strutStyle: const StrutStyle(
                    height: 1.1,
                    forceStrutHeight: true,
                  ),
                  style: _labelStyle,
                ),
              ),
              const SizedBox(height: 2.5),
              Baseline(
                baselineType: TextBaseline.alphabetic,
                baseline: 18,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: const StrutStyle(
                    height: 1.1,
                    forceStrutHeight: true,
                  ),
                  style: _valueStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: content,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: _item(
              icon: Icons.payments_outlined,
              label: '이번 달',
              value: monthSpendingText,
            ),
          ),
          _vline(),
          Expanded(
            child: _item(
              icon: Icons.subscriptions_outlined,
              label: '활성',
              value: activeCountText,
            ),
          ),
          _vline(),
          Expanded(
            child: _item(
              icon: Icons.event_available_outlined,
              label: nextBillingLabel,
              value: nextBillingDday,
              onTap: onTapNextBilling,
            ),
          ),
        ],
      ),
    );
  }
}

/// 마커(회색 점) 지원 미니 캘린더 위젯
class _MiniCalendar extends StatefulWidget {
  const _MiniCalendar({
    required this.initialMonth,
    required this.hasPaymentOn,
    required this.onSelect,
  });

  final DateTime initialMonth;
  final bool Function(DateTime day) hasPaymentOn; // 활성 결제 존재 여부
  final ValueChanged<DateTime> onSelect;

  @override
  State<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<_MiniCalendar> {
  late DateTime _visibleMonth; // 첫째날 기준
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
      1,
    );
    _selected = DateTime.now();
  }

  int _daysInMonth(DateTime m) {
    final firstNext = DateTime(m.year, m.month + 1, 1);
    return firstNext.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    ).weekday; // 1=Mon..7=Sun
    final startOffset = (firstWeekday % 7); // 0=Sun
    final totalDays = _daysInMonth(_visibleMonth);
    final cells = startOffset + totalDays;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month - 1,
                  1,
                );
              }),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_visibleMonth.year}년 ${_visibleMonth.month.toString().padLeft(2, '0')}월',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month + 1,
                  1,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _Dow('S'),
            _Dow('M'),
            _Dow('T'),
            _Dow('W'),
            _Dow('T'),
            _Dow('F'),
            _Dow('S'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.2,
          ),
          itemCount: cells,
          itemBuilder: (context, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = i - startOffset + 1;
            final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
            final selected =
                _selected != null &&
                _selected!.year == date.year &&
                _selected!.month == date.month &&
                _selected!.day == date.day;
            final hasPayment = widget.hasPaymentOn(date);

            return GestureDetector(
              onTap: () {
                setState(() => _selected = date);
                widget.onSelect(date);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? _SubscriptionsScreenState.purple.withOpacity(.12)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? _SubscriptionsScreenState.purple.withOpacity(.5)
                        : Colors.transparent,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 8,
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (hasPayment)
                      Positioned(
                        bottom: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
