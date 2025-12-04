/*
 * 크롤러가 감지한 가격 변동 내역(priceChanges 컬렉션)을 리스트로 보여주는 화면
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PriceChangeReportScreen extends StatelessWidget {
  const PriceChangeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const appBg = Colors.white;

    return Scaffold(
      backgroundColor: appBg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "가격 변동 리포트",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. priceChanges 컬렉션을 감지일(detectedAt) 최신순으로 정렬하여 가져옴
        stream: FirebaseFirestore.instance
            .collection('priceChanges')
            .orderBy('detectedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("데이터를 불러오는데 실패했습니다: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _PriceChangeCard(data: data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
          const SizedBox(height: 16),
          const Text(
            "감지된 가격 변동이 없습니다.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            "모든 구독 서비스가 안정적입니다.",
            style: TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _PriceChangeCard extends StatelessWidget {
  const _PriceChangeCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    // 데이터 파싱
    final String serviceName = data['serviceName'] ?? '서비스명 미상';
    final String planName = data['planName'] ?? '기본 플랜';
    final int oldPrice = (data['oldPrice'] as num?)?.toInt() ?? 0;
    final int newPrice = (data['newPrice'] as num?)?.toInt() ?? 0;
    final String type =
        data['changeType'] ?? 'increase'; // increase or decrease

    // 날짜 파싱
    DateTime? effectiveDate;
    if (data['effectiveDate'] != null) {
      effectiveDate = (data['effectiveDate'] as Timestamp).toDate();
    }

    // 변동률 계산
    double diffRate = 0;
    if (oldPrice > 0) {
      diffRate = ((newPrice - oldPrice) / oldPrice) * 100;
    }

    // UI 테마 설정 (인상: 빨강 / 인하: 파랑)
    final bool isIncrease = type == 'increase';
    final Color cardColor =
        isIncrease ? const Color(0xFFFFF5F5) : const Color(0xFFF0F9FF);
    final Color accentColor =
        isIncrease ? const Color(0xFFFF5252) : const Color(0xFF448AFF);
    final IconData icon = isIncrease ? Icons.trending_up : Icons.trending_down;
    final String sign = isIncrease ? "+" : "";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (서비스명 + 배지)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.subscriptions, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      planName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // 변동률 배지
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "$sign${diffRate.toStringAsFixed(1)}%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 16),

          // 2. 가격 비교 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("기존 가격",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    "${NumberFormat("#,###").format(oldPrice)}원",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough, // 취소선
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("변경 가격",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    "${NumberFormat("#,###").format(newPrice)}원",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. 반영일 정보
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  effectiveDate != null
                      ? "반영 예정일: ${DateFormat('yyyy년 MM월 dd일').format(effectiveDate)}"
                      : "반영일 미정",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
