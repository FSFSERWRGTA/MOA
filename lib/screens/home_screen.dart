/*
 * 앱의 메인 대시보드 화면으로, 사용자의 구독 현황을 나타냄
 *
 * [주요 기능 및 로직]
 * 1. 실시간 데이터 연동 (StreamBuilder):
 * - Firestore의 users/{uid}/subscriptions 컬렉션을 실시간으로 감시
 * - 데이터가 변경(추가/수정/삭제)되면 화면이 즉시 자동으로 갱신
 *
 * 2. 대시보드 통계 자동 계산 (Client-side Logic):
 * - 구독 수: 전체 문서의 개수 (docs.length)
 * - 이번 달 지출: 모든 구독의 결제 금액(amount)을 합산
 * - 다음 결제일: nextRenewalAt 기준으로 정렬하여 가장 빠른 날짜의 D-Day 표시
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../routes/app_router.dart';
import '../user_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const purple = Color(0xFF6F6BFF);

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

      body: StreamBuilder<QuerySnapshot>(
        // 1. DB에서 '다음 결제일' 순서로 구독 목록 가져오기
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(UserState.currentUserId) // 로그인한 ID
            .collection('subscriptions')
            .orderBy('nextRenewalAt')
            .snapshots(),
        builder: (context, snapshot) {
          // (A) 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // (B) 에러 났을 때
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          // (C) 데이터 계산 (Dashboard 로직)
          final docs = snapshot.data?.docs ?? [];

          // 1. 구독 개수
          final int count = docs.length;

          // 2. 이번 달 지출 합계 (모든 항목의 amount 더하기)
          int totalSpending = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toInt() ?? 0;
            totalSpending += amount;
          }

          // 3. 다음 결제일 (정렬했으므로 첫 번째 문서가 가장 빠름)
          DateTime? nextBill;
          if (docs.isNotEmpty) {
            final firstData = docs.first.data() as Map<String, dynamic>;
            if (firstData['nextRenewalAt'] != null) {
              nextBill = (firstData['nextRenewalAt'] as Timestamp).toDate();
            }
          }

          // (D) 화면 구성
          return RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('안녕하세요 👋',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('오늘도 구독/지출을 똑똑하게 관리해볼까요?',
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        const _SearchBar(),
                        const SizedBox(height: 20),

                        // ---- 자동 계산된 값 넣기) 요약 카드 ----
                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: [
                            _StatCard(
                              title: '이번 달 지출',
                              value: _formatWon(totalSpending), // DB 합계
                              icon: Icons.payments_outlined,
                              accent: purple,
                              subtitle: '이번 달 합계',
                              width:
                                  (MediaQuery.of(context).size.width - 52) / 2,
                            ),
                            _StatCard(
                              title: '구독 수',
                              value: '$count개', // DB 개수
                              icon: Icons.subscriptions_outlined,
                              accent: purple,
                              subtitle: '활성 구독',
                              width:
                                  (MediaQuery.of(context).size.width - 52) / 2,
                            ),
                            _StatCard(
                              title: '다음 결제',
                              value: nextBill != null
                                  ? _formatDate(nextBill)
                                  : '-', // DB 날짜
                              icon: Icons.event_available_outlined,
                              accent: purple,
                              subtitle:
                                  nextBill != null ? _dDay(nextBill) : '예정 없음',
                              width: MediaQuery.of(context).size.width - 40,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        // 빠른 작업 (버튼 숨김 옵션 적용)
                        const _SectionHeader(title: '빠른 작업', showMore: false),

                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                label: '구독 추가',
                                icon: Icons.add_circle_outline,
                                onTap: () => Navigator.pushNamed(
                                    context, Routes.addSubscription),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _QuickAction(
                                    label: '가격 인상 확인',
                                    icon: Icons.trending_up_outlined,
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, Routes.priceReport);
                                    })),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _QuickAction(
                                    label: '리포트',
                                    icon: Icons.bar_chart_outlined,
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, Routes.report);
                                    })),
                          ],
                        ),

                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: '다가오는 결제',
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, Routes.subscriptions);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- 실제 데이터 리스트 ----
                if (docs.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("등록된 구독이 없어요.")),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        // DB 데이터를 가져와서 타일 위젯에 넘깁니다.
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _UpcomingTile(data: data);
                      },
                      childCount: docs.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
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
  const _SectionHeader({
    required this.title,
    this.showMore = true,
    this.onTap,
  });
  final String title;
  final bool showMore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (showMore) TextButton(onPressed: onTap, child: const Text('전체보기')),
      ],
    );
  }
}

// DB 데이터 받아서 보여주는 타일 위젯
class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    // 데이터 꺼내기 - null 안전 처리
    final String serviceName = data['providerName'] ?? '이름 없음';
    final int amount = (data['amount'] as num?)?.toInt() ?? 0;
    final String planName = data['planName'] ?? '기본 요금제';

    // 날짜 변환 (Firestore Timestamp -> DateTime -> String)
    String dateStr = '날짜 미정';
    if (data['nextRenewalAt'] != null) {
      final date = (data['nextRenewalAt'] as Timestamp).toDate();
      // "11-05" 형식으로 포맷팅
      dateStr =
          '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    // 금액 콤마 찍기 (17000 -> 17,000)
    final priceStr = NumberFormat("#,###").format(amount);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      // 아이콘 박스
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
      // 서비스명
      title: Text(
        serviceName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      // 날짜 및 요금제
      subtitle: Text('$dateStr • $planName'),
      // 금액
      trailing: Text(
        '₩$priceStr',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTap: () {},
    );
  }
}
