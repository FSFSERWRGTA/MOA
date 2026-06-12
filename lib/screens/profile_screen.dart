/*
 * 사용자 정보와 구독 통계를 가져와 보여주는 프로필 화면
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_router.dart';
import 'coming_soon_screen.dart';
import 'profile_edit_screen.dart';
import '../user_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const purple = Color(0xFF6F6BFF);
  static const line = Color(0xFFEDEBFF);
  static const appBg = Colors.white;

  // DB에서 데이터 가져오는 함수
  Future<Map<String, dynamic>> _fetchProfileData() async {
    final uid = UserState.currentUserId;

    // 비회원일 경우 기본값 반환
    if (uid == null) {
      return {'name': '게스트', 'count': 0, 'spending': 0};
    }

    try {
      // 사용자 정보 가져오기 (users 컬렉션)
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      // DB에 'name' 필드가 없으면 '사용자'로 표시
      final String name = userDoc.data()?['name'] ?? '사용자';

      // 구독 목록 가져와서 통계 내기 (subscriptions 서브 컬렉션)
      final subDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .get();

      int count = subDocs.docs.length; // 구독 개수
      int totalSpending = 0; // 총 지출액

      for (var doc in subDocs.docs) {
        final amount = (doc.data()['amount'] as num?)?.toInt() ?? 0;
        totalSpending += amount;
      }

      return {
        'name': name,
        'count': count,
        'spending': totalSpending,
      };
    } catch (e) {
      // 에러 발생 시 기본값 반환 (혹은 에러 처리)
      print("프로필 로딩 에러: $e");
      return {'name': '오류 발생', 'count': 0, 'spending': 0};
    }
  }

  // 금액 포맷팅 (예: 13500.00 KRW)
  String _formatWon(int v) {
    return '${v.toStringAsFixed(2)} KRW';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /* ───────── AppBar (상단 바) ───────── */
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          '프로필',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('설정 화면 준비 중')),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: line),
        ),
      ),

      /* ───────── 본문 (FutureBuilder 적용) ───────── */
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(), // 데이터 로딩 함수 실행
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. 에러 발생
          if (snapshot.hasError) {
            return Center(child: Text("데이터를 불러올 수 없습니다.\n${snapshot.error}"));
          }

          // 3. 데이터 도착
          final data =
              snapshot.data ?? {'name': '알 수 없음', 'count': 0, 'spending': 0};
          final String userName = data['name'];
          final int activeCount = data['count'];
          final int thisMonthSpending = data['spending'];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // 사용자 헤더
              _HeaderCard(
                name: userName,
                onEdit: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                  // 수정 후 돌아오면 프로필 새로고침
                  if (changed == true && mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // 요약 통계 (DB 데이터 반영)
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      title: '이번 달 지출',
                      value: _formatWon(thisMonthSpending),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      title: '활성 구독',
                      value: '$activeCount개',
                      icon: Icons.subscriptions_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionHeader(title: '계정'),
              _RowTile(
                  icon: Icons.lock_outline, title: '비밀번호/보안', onTap: () {}),
              _RowTile(
                icon: Icons.notifications_none,
                title: '알림 설정',
                onTap: () {},
              ),
              _RowTile(
                icon: Icons.credit_card_outlined,
                title: '결제 수단',
                onTap: () {},
              ),
              _RowTile(
                icon: Icons.file_download_outlined,
                title: '데이터 내보내기',
                onTap: () {},
              ),

              const SizedBox(height: 12),
              const _SectionHeader(title: '지원'),
              _RowTile(
                  icon: Icons.help_outline,
                  title: '도움말 / 피드백',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ComingSoonScreen(title: '도움말 / 피드백'),
                      ),
                    );
                  }),

              // 로그아웃 기능
              _RowTile(
                icon: Icons.logout,
                title: '로그아웃',
                destructive: true,
                onTap: () {
                  // 로그아웃 로직: ID 지우고 로그인 화면으로 이동
                  UserState.currentUserId = null;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.login,
                    (_) => false, // 뒤로가기 불가능하게 모든 라우트 제거
                  );
                },
              ),
            ],
          );
        },
      ),

      /* ───────── 하단 NavigationBar ───────── */
      bottomNavigationBar: NavigationBar(
        backgroundColor: appBg,
        surfaceTintColor: Colors.transparent,
        selectedIndex: 3, // 프로필 탭
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, Routes.home);
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, Routes.subscriptions);
          } else if (i == 2) {
            Navigator.pushReplacementNamed(context, Routes.recommendations);
          } else if (i == 3) {
            return; // 현재 탭 유지
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
}

/* ================== 위젯들 ================== */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.onEdit});
  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEDEBFF)), // static 상수 대신 직접 값 사용
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6F6BFF), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline,
                color: Colors.black87,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '기본 정보 보기',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.black87,
            ),
            label: const Text('편집', style: TextStyle(color: Colors.black87)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFEDEBFF)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : Colors.black87;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.black54,
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEDEBFF)),
      ],
    );
  }
}
