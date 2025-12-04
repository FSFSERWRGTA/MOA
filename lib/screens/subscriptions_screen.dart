import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../routes/app_router.dart';
import '../user_state.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  static const purple = Color(0xFF6F6BFF);
  static const appBg = Colors.white;
  static const divider = Color(0xFFE8E8FF);

  // DB에서 데이터 가져오는 함수
  Future<Map<String, dynamic>> _fetchSubsData() async {
    final uid = UserState.currentUserId;

    if (uid == null) {
      return {'items': [], 'totalSpending': 0, 'nextDate': null};
    }

    try {
      final subDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int totalSpending = 0;
      DateTime? nextDate;
      List<_SubItem> items = [];

      for (var doc in subDocs.docs) {
        final data = doc.data();
        final bool isActive = (data['status'] as String? ?? 'inactive') == 'active';
        if (!isActive) continue; // 비활성 구독은 건너뛰기

        final amount = (data['amount'] as num?)?.toInt() ?? 0;
        totalSpending += amount;

        final nextRenewalAt = (data['nextRenewalAt'] as Timestamp?)?.toDate();
        if (nextRenewalAt != null) {
          var potentialNextDate = nextRenewalAt;
          if (potentialNextDate.isBefore(today)) {
            // 이미 지난 날짜면 내년으로
            potentialNextDate = DateTime(now.year + 1, potentialNextDate.month, potentialNextDate.day);
          }
          if (nextDate == null || potentialNextDate.isBefore(nextDate)) {
            nextDate = potentialNextDate;
          }
        }

        items.add(_SubItem(
          data['providerName'] ?? '이름 없음',
          _formatWon(amount),
          nextRenewalAt != null ? _formatDate(nextRenewalAt) : 'N/A',
          data['planName'] ?? '',
          isActive,
          data['category'] ?? '기타',
        ));
      }

      return {
        'items': items,
        'totalSpending': totalSpending,
        'nextDate': nextDate,
      };
    } catch (e) {
      print("구독 정보 로딩 에러: $e");
      return {'items': [], 'totalSpending': 0, 'nextDate': null, 'error': e};
    }
  }

  String _formatWon(int v) => NumberFormat("#,###").format(v) + '원';
  String _formatDate(DateTime d) => DateFormat('MM/dd').format(d);
  String _dDay(DateTime d) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return '오늘';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }
  int _monthOf(String mmdd) {
    final sp = mmdd.split('/');
    if (sp.isEmpty) return DateTime.now().month;
    return int.tryParse(sp[0]) ?? DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('MOA', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        actions: [
          IconButton(tooltip: '결제 달력', icon: const Icon(Icons.calendar_today_outlined, color: Colors.black87), onPressed: () {}),
          IconButton(tooltip: '홈으로', icon: const Icon(Icons.home_outlined, color: Colors.black87), onPressed: () => Navigator.pushReplacementNamed(context, Routes.home)),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: divider)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSubsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?['error'] != null) {
            return Center(child: Text("데이터를 불러올 수 없습니다.\n${snapshot.error ?? snapshot.data?['error']}"));
          }

          final data = snapshot.data!;
          final List<_SubItem> allItems = data['items'];
          final int totalSpending = data['totalSpending'];
          final DateTime? nextBillingDate = data['nextDate'];

          return _SubsListBody(
            allItems: allItems,
            totalSpending: totalSpending,
            nextBillingDate: nextBillingDate,
            dDay: nextBillingDate != null ? _dDay(nextBillingDate) : '',
            formatDate: _formatDate,
            formatWon: _formatWon,
            monthOf: _monthOf,
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: appBg,
        surfaceTintColor: Colors.transparent,
        selectedIndex: 1, // 내 구독 탭
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, Routes.home);
          } else if (i == 1) {
            return; // 현재 탭
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, Routes.recommendations);
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, Routes.profile);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: '내 구독'),
          NavigationDestination(icon: Icon(Icons.star_border), label: '추천'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFEDEBFF),
        icon: const Icon(Icons.add, color: Color(0xFF6F6BFF)),
        label: const Text('구독 추가', style: TextStyle(color: Color(0xFF6F6BFF))),
      ),
    );
  }
}

// 화면의 메인 컨텐츠를 분리 (상태 관리를 위함)
class _SubsListBody extends StatefulWidget {
  const _SubsListBody({
    required this.allItems,
    required this.totalSpending,
    required this.nextBillingDate,
    required this.dDay,
    required this.formatDate,
    required this.formatWon,
    required this.monthOf,
  });

  final List<_SubItem> allItems;
  final int totalSpending;
  final DateTime? nextBillingDate;
  final String dDay;
  final String Function(DateTime) formatDate;
  final String Function(int) formatWon;
  final int Function(String) monthOf;

  @override
  State<_SubsListBody> createState() => _SubsListBodyState();
}

class _SubsListBodyState extends State<_SubsListBody> {
  String _query = '';
  String _filter = '전체'; // 전체/활성/일시중지
  static const String _kDefaultSort = '결제일 빠른순';
  String? _sort = _kDefaultSort;

  @override
  Widget build(BuildContext context) {
    final visible = widget.allItems.where((e) {
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
          case '가격 높은순': return _parseWon(b.price).compareTo(_parseWon(a.price));
          case '이름': return a.name.compareTo(b.name);
          case '결제일 빠른순': default: return a.nextDate.compareTo(b.nextDate);
        }
      });

    final now = DateTime.now();
    final Map<String, int> categoryTotals = {};
    for (final it in widget.allItems) {
      if (!it.active) continue;
      final m = widget.monthOf(it.nextDate);
      if (m != now.month) continue;
      final v = _parseWon(it.price);
      categoryTotals.update(it.category, (prev) => prev + v, ifAbsent: () => v);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const Text('내 구독', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _SummaryPanel(
          monthSpendingText: widget.formatWon(widget.totalSpending),
          activeCountText: '${widget.allItems.where((e) => e.active).length}개',
          nextBillingLabel: widget.nextBillingDate != null ? widget.formatDate(widget.nextBillingDate!) : '없음',
          nextBillingDday: widget.dDay,
          onTapNextBilling: () {},
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: '구독명 검색',
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _FilterChip(label: '전체', selected: _filter == '전체', onTap: () => setState(() => _filter = '전체')),
            const SizedBox(width: 8),
            _FilterChip(label: '활성', selected: _filter == '활성', onTap: () => setState(() => _filter = '활성')),
            const SizedBox(width: 8),
            _FilterChip(label: '일시중지', selected: _filter == '일시중지', onTap: () => setState(() => _filter = '일시중지')),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: '정렬',
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (ctx) => const [PopupMenuItem(value: '결제일 빠른순', child: Text('결제일 빠른순')), PopupMenuItem(value: '가격 높은순', child: Text('가격 높은순')), PopupMenuItem(value: '이름', child: Text('이름'))],
              child: Row(children: [Text(_sort ?? _kDefaultSort, style: const TextStyle(color: Colors.black87)), const SizedBox(width: 4), const Icon(Icons.arrow_drop_down)]),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (categoryTotals.isNotEmpty) ...[
          const Text('카테고리별 지출 (이번 달 · 활성)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _CategoryBars(data: categoryTotals),
          const SizedBox(height: 18),
        ],
        ...visible.map((e) => _SubCard(item: e, accent: const Color(0xFF6F6BFF))),
        if (visible.isEmpty) Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF7F7FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E8FF))),
          child: const Row(children: [Icon(Icons.inbox_outlined), SizedBox(width: 8), Expanded(child: Text('조건에 맞는 구독이 없어요. 필터나 검색어를 조정해보세요.'))]),
        ),
      ],
    );
  }
  int _parseWon(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}




/* ================= 위젯들 ================= */

class _SubItem {
  final String name, price, nextDate, note, category;
  final bool active;
  _SubItem(this.name, this.price, this.nextDate, this.note, this.active, this.category);
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.monthSpendingText, required this.activeCountText, required this.nextBillingLabel, required this.nextBillingDday, this.onTapNextBilling});
  final String monthSpendingText, activeCountText, nextBillingLabel, nextBillingDday;
  final VoidCallback? onTapNextBilling;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF7F7FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E8FF))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCol('월 예상 지출', monthSpendingText),
          _buildCol('활성 구독', activeCountText),
          InkWell(onTap: onTapNextBilling, borderRadius: BorderRadius.circular(8), child: _buildCol('다음 결제일', nextBillingLabel, sub: nextBillingDday)),
        ],
      ),
    );
  }

  Widget _buildCol(String label, String value, {String? sub}) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6F6BFF))),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? const Color(0xFFEDEBFF) : Colors.white;
    final Color border = selected ? const Color(0xFF6F6BFF) : const Color(0xFFE8E8FF);
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), selectedColor: bg, backgroundColor: bg, labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87), side: BorderSide(color: border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)));
  }
}

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (s, v) => s + v);
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(children: entries.map((e) {
      final ratio = total == 0 ? 0.0 : e.value / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(children: [
          Row(children: [Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))), Text('₩${_formatComma(e.value)}', style: const TextStyle(color: Colors.black54))]),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, c) => Stack(children: [
            Container(height: 10, width: c.maxWidth, decoration: BoxDecoration(color: const Color(0xFFF1F0FF), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE8E8FF)))),
            Container(height: 10, width: c.maxWidth * ratio, decoration: BoxDecoration(color: const Color(0xFF6F6BFF).withOpacity(.9), borderRadius: BorderRadius.circular(999))),
          ])),
        ]),
      );
    }).toList());
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

class _SubCard extends StatelessWidget {
  const _SubCard({required this.item, required this.accent});
  final _SubItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E8FF)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEDEBFF), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.subscriptions_outlined, color: accent)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(item.note, style: const TextStyle(color: Colors.black54, fontSize: 13))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(item.price, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('다음 결제: ${item.nextDate}')]),
      ]),
    );
  }
}
