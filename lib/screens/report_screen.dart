/*
 * 사용자의 구독 데이터를 분석하여 카테고리별 지출 통계를 보여주는 화면
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../user_state.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  // 카테고리별 색상 및 라벨 매핑
  static const Map<String, Color> categoryColors = {
    'OTT': Color.fromARGB(255, 243, 67, 67), // 빨강
    '음악': Color(0xFF448AFF), // 파랑
    '생산성': Color(0xFF69F0AE), // 초록
    'AI 툴': Color.fromARGB(255, 255, 163, 57), // 보라
    '클라우드': Color(0xFF607D8B), // 회색
  };

  static const Map<String, String> categoryLabels = {
    'OTT': 'OTT/영상',
    '음악': '음악',
    '생산성': '생산성',
    'AI 툴': 'AI 서비스',
    '클라우드': '클라우드',
  };

  @override
  Widget build(BuildContext context) {
    final uid = UserState.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "지출 리포트",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('subscriptions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("분석할 구독 데이터가 없어요."));
          }

          // 1. 데이터 가공 (카테고리별 합계 계산)
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

          // 2. 금액 순서대로 정렬 (내림차순)
          final sortedEntries = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // 3. 가장 많이 쓰는 카테고리
          final topCategory =
              sortedEntries.isNotEmpty ? sortedEntries.first.key : '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 총 지출 요약
                const Text("이번 달 총 지출",
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  "${NumberFormat("#,###").format(totalAmount)}원",
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (sortedEntries.isNotEmpty)
                  Text(
                    "🏆 ${categoryLabels[topCategory] ?? topCategory}에 가장 많이 쓰고 있어요!",
                    style: TextStyle(
                        color: categoryColors[topCategory] ?? Colors.black87,
                        fontWeight: FontWeight.w600),
                  ),

                const SizedBox(height: 30),

                // 시각화: 컬러 바 그래프
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: sortedEntries.map((entry) {
                        final flex = (entry.value / totalAmount * 100).round();
                        if (flex == 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: flex,
                          child: Container(
                            color: categoryColors[entry.key] ?? Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 상세 리스트
                const Text("카테고리별 상세",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                ...sortedEntries.map((entry) {
                  final percent =
                      (entry.value / totalAmount * 100).toStringAsFixed(1);
                  final color = categoryColors[entry.key] ?? Colors.grey;
                  final label = categoryLabels[entry.key] ?? entry.key;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 컬러 점
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        // 카테고리명
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const Spacer(),
                        // 금액 및 퍼센트
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${NumberFormat("#,###").format(entry.value)}원",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(
                              "$percent%",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
