import 'package:flutter/material.dart';
import '../routes/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const purple = Color(0xFF6F6BFF);
  static const line = Color(0xFFEDEBFF);

  // 데모 값
  final String userName = 'kiwoom';
  final int activeCount = 3;
  final int thisMonthSpending = 23650;

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

      /* ───────── 본문 ───────── */
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // 사용자 헤더 (화이트 + 라인만)
          _HeaderCard(
            name: userName,
            onEdit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 편집 준비 중')),
              );
            },
          ),
          const SizedBox(height: 16),

          // 요약
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
            icon: Icons.lock_outline,
            title: '비밀번호/보안',
            onTap: () {},
          ),
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
            onTap: () {},
          ),
          _RowTile(
            icon: Icons.logout,
            title: '로그아웃',
            destructive: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 준비 중')),
              );
            },
          ),
        ],
      ),

      /* ───────── 하단 NavigationBar ───────── */
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        selectedIndex: 2,
        onDestinationSelected: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, Routes.home);
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, Routes.subscriptions);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: '내 구독'),
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
          BorderSide(color: ProfileScreen.line),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ProfileScreen.purple, width: 1.5),
            ),
            child: const Center(
              child:
                  Icon(Icons.person_outline, color: Colors.black87, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('기본 정보 보기',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: Colors.black87),
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
          BorderSide(color: ProfileScreen.line),
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
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
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
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          trailing:
              const Icon(Icons.chevron_right_rounded, color: Colors.black54),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 1, color: ProfileScreen.line),
      ],
    );
  }
}
