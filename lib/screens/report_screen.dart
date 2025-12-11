/*
 * 지출 리포트 화면: 카테고리 별 지출을 확인할 수 있다.
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../user_state.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  // 브랜드 컬러
  static const primaryPurple = Color(0xFF6F6BFF);
  static const softPurple = Color(0xFFF4F3FF);
  static const darkText = Color(0xFF1A1A2E);
  static const subtleText = Color(0xFF6B7280);

  // 카테고리별 컬러
  static const Map<String, Color> categoryColors = {
    'OTT': Color(0xFFFF6B6B),
    '음악': Color(0xFF4ECDC4),
    '생산성': Color(0xFF45B7D1),
    'AI 툴': Color(0xFFFFBE0B),
    '클라우드': Color(0xFF9D6BFF),
  };

  static const Map<String, String> categoryLabels = {
    'OTT': 'OTT/영상',
    '음악': '음악',
    '생산성': '생산성',
    'AI 툴': 'AI 서비스',
    '클라우드': '클라우드',
  };

  static const Map<String, IconData> categoryIcons = {
    'OTT': Icons.play_circle_rounded,
    '음악': Icons.music_note_rounded,
    '생산성': Icons.work_rounded,
    'AI 툴': Icons.auto_awesome_rounded,
    '클라우드': Icons.cloud_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final uid = UserState.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('subscriptions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryPurple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          // 데이터 처리
          final docs = snapshot.data!.docs;
          final Map<String, int> categoryTotals = {};
          int totalAmount = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toInt() ?? 0;
            final category = data['category'] ?? 'uncategorized';

            totalAmount += amount;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          final sortedEntries = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final topCategory =
              sortedEntries.isNotEmpty ? sortedEntries.first.key : '-';

          return CustomScrollView(
            slivers: [
              // 커스텀 앱바
              SliverToBoxAdapter(
                child: _buildHeader(context, totalAmount, topCategory),
              ),

              // 도넛 차트 섹션
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _buildChartSection(sortedEntries, totalAmount),
                ),
              ),

              // 인사이트 카드
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _buildInsightCard(
                      sortedEntries, totalAmount, docs.length),
                ),
              ),

              // 카테고리별 상세
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: softPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pie_chart_rounded,
                          size: 18,
                          color: primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '카테고리별 상세',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 카테고리 리스트
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = sortedEntries[index];
                      return _CategoryCard(
                        category: entry.key,
                        amount: entry.value,
                        totalAmount: totalAmount,
                        rank: index + 1,
                      );
                    },
                    childCount: sortedEntries.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // 헤더
  // ============================================================
  Widget _buildHeader(
      BuildContext context, int totalAmount, String topCategory) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      color: const Color(0xFFFAFAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 네비게이션
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: darkText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                '지출 리포트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: softPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: primaryPurple,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateTime.now().month}월',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 총 지출 금액
          const Text(
            '이번 달 총 지출',
            style: TextStyle(
              fontSize: 14,
              color: subtleText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat("#,###").format(totalAmount),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: subtleText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 도넛 차트 섹션
  // ============================================================
  Widget _buildChartSection(
      List<MapEntry<String, int>> entries, int totalAmount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 도넛 차트
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutChartPainter(
                entries: entries,
                totalAmount: totalAmount,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entries.length}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtleText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // 범례
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.take(5).map((entry) {
                final percent =
                    (entry.value / totalAmount * 100).toStringAsFixed(0);
                final color = categoryColors[entry.key] ?? Colors.grey;
                final label = categoryLabels[entry.key] ?? entry.key;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 인사이트 카드
  // ============================================================
  Widget _buildInsightCard(
      List<MapEntry<String, int>> entries, int totalAmount, int subCount) {
    final avgPerSub = subCount > 0 ? (totalAmount / subCount).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            softPurple,
            softPurple.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: primaryPurple,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '지출 인사이트',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InsightItem(
                  icon: Icons.subscriptions_rounded,
                  label: '구독 수',
                  value: '$subCount개',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: primaryPurple.withOpacity(0.15),
              ),
              Expanded(
                child: _InsightItem(
                  icon: Icons.payments_rounded,
                  label: '평균 단가',
                  value: '₩${NumberFormat("#,###").format(avgPerSub)}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: primaryPurple.withOpacity(0.15),
              ),
              Expanded(
                child: _InsightItem(
                  icon: Icons.trending_up_rounded,
                  label: '전월 대비',
                  value: '+0%',
                  valueColor: const Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 빈 상태
  // ============================================================
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 60,
        20,
        20,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: softPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: primaryPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '분석할 데이터가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '구독을 추가하면 지출 분석을 확인할 수 있어요',
            style: TextStyle(
              fontSize: 14,
              color: subtleText,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 인사이트 아이템
// ============================================================
class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InsightItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: ReportScreen.primaryPurple.withOpacity(0.6),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor ?? ReportScreen.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ReportScreen.subtleText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 카테고리 카드
// ============================================================
class _CategoryCard extends StatelessWidget {
  final String category;
  final int amount;
  final int totalAmount;
  final int rank;

  const _CategoryCard({
    required this.category,
    required this.amount,
    required this.totalAmount,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final color = ReportScreen.categoryColors[category] ?? Colors.grey;
    final label = ReportScreen.categoryLabels[category] ?? category;
    final icon = ReportScreen.categoryIcons[category] ?? Icons.category_rounded;
    final percent = (amount / totalAmount * 100);
    final percentStr = percent.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 아이콘 배경
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // 카테고리 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ReportScreen.darkText,
                          ),
                        ),
                        if (rank == 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFBE0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '최다 지출',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE5A500),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentStr% 차지',
                      style: TextStyle(
                        fontSize: 13,
                        color: ReportScreen.subtleText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 금액
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₩${NumberFormat("#,###").format(amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/월',
                    style: TextStyle(
                      fontSize: 12,
                      color: ReportScreen.subtleText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 도넛 차트 페인터
// ============================================================
class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int totalAmount;

  _DonutChartPainter({
    required this.entries,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    double startAngle = -math.pi / 2;

    for (var entry in entries) {
      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi;
      final color = ReportScreen.categoryColors[entry.key] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.02, // 약간의 간격
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
