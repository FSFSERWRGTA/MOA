import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const purple = Color(0xFF6F6BFF);

  // ---- 대시보드 통계 (샘플) ----
  int subscriptionCount = 3;
  int thisMonthSpending = 23650; // 원
  DateTime nextBillingDate = DateTime(DateTime.now().year, 11, 5);

  @override
  Widget build(BuildContext context) {
    const appBg = Colors.white; // 전체 배경
    const divider = Color(0xFFE8E8FF); // 상단 구분선 색 (보라 라이트)

    return Scaffold(
      backgroundColor: appBg,

      appBar: AppBar(
        backgroundColor: appBg, // 배경이랑 비슷하게(동일)
        elevation: 0, // 그림자 제거
        scrolledUnderElevation: 0, // 스크롤 음영 제거(Material3)
        surfaceTintColor: Colors.transparent, // 업리프트 틴트 제거
        systemOverlayStyle: SystemUiOverlayStyle.dark, // 상태바 아이콘 어두운색
        centerTitle: true,
        title: const Text(
          'MOA',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (_) => false,
              );
            },
          ),
        ],
        // 얇은 하단 구분선만
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 인사 & 검색
                    const Text(
                      '안녕하세요 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '오늘도 구독/지출을 똑똑하게 관리해볼까요?',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    const _SearchBar(),
                    const SizedBox(height: 20),

                    // ---- 요약 카드 ----
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        _StatCard(
                          title: '이번 달 지출',
                          value: _formatWon(thisMonthSpending),
                          icon: Icons.payments_outlined,
                          accent: purple,
                          subtitle: '활성 합계',
                          width: (MediaQuery.of(context).size.width -
                                  20 -
                                  20 -
                                  12) /
                              2,
                        ),
                        _StatCard(
                          title: '구독 수',
                          value: '$subscriptionCount개',
                          icon: Icons.subscriptions_outlined,
                          accent: purple,
                          subtitle: '활성 구독',
                          width: (MediaQuery.of(context).size.width -
                                  20 -
                                  20 -
                                  12) /
                              2,
                        ),
                        _StatCard(
                          title: '다음 결제',
                          value: _formatDate(nextBillingDate),
                          icon: Icons.event_available_outlined,
                          accent: purple,
                          subtitle: _dDay(nextBillingDate), // D-day 표기
                          width: MediaQuery.of(context).size.width - 20 - 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    const _SectionHeader(
                      title: '빠른 작업',
                      showMore: false,
                    ),

                    // 빠른 작업 버튼 3개
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            label: '구독 추가',
                            icon: Icons.add_circle_outline,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.addSubscription,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            label: '가격 인상 확인',
                            icon: Icons.trending_up_outlined,
                            onTap: () {
                              Navigator.pushNamed(context, Routes.priceReport);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            label: '리포트',
                            icon: Icons.bar_chart_outlined,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    const _SectionHeader(title: '다가오는 결제'),
                  ],
                ),
              ),
            ),

            // 다가오는 결제 리스트
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _UpcomingTile(item: _upcoming[i]),
                childCount: _upcoming.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),

      // 하단 네비 + FAB
      bottomNavigationBar: NavigationBar(
        backgroundColor: appBg, // 네비와 전체 톤 맞춤
        surfaceTintColor: Colors.transparent,
        selectedIndex: 0, // 홈 탭
        onDestinationSelected: (i) {
          if (i == 0) return; // 이미 홈이면 무시
          if (i == 1) {
            Navigator.pushReplacementNamed(context, Routes.subscriptions);
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, Routes.recommendations);
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
          NavigationDestination(icon: Icon(Icons.star_border), label: '추천'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }

  // ---- 포맷 유틸 ----
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

/* ---------------- 위젯들 ---------------- */

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '서비스/구독 검색',
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black54, width: 1.2),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.width,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8E8FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6F6BFF)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.showMore = true});
  final String title;
  final bool showMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (showMore) TextButton(onPressed: () {}, child: const Text('전체보기')),
      ],
    );
  }
}

class UpcomingItem {
  final String service;
  final String date; // mm-dd
  final String price; // ₩xx,xxx
  final String note;
  UpcomingItem(this.service, this.date, this.price, this.note);
}

final _upcoming = <UpcomingItem>[
  UpcomingItem('Netflix', '11-05', '₩9,500', '베이식 요금제'),
  UpcomingItem('YouTube Premium', '11-08', '₩10,450', '개인'),
  UpcomingItem('iCloud 200GB', '11-10', '₩3,700', '스토리지'),
];

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item});
  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEBFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.subscriptions_outlined,
          color: Color(0xFF6F6BFF),
        ),
      ),
      title: Text(
        item.service,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${item.date} • ${item.note}'),
      trailing: Text(
        item.price,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTap: () {},
    );
  }
}
