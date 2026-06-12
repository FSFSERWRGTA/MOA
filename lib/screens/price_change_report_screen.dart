// ---------------------------------------------------------------------------
// 가격 변동 리포트 화면
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../user_state.dart';
import '../routes/app_router.dart'; // Routes.recommendations 사용

class PriceChangeReportScreen extends StatefulWidget {
  const PriceChangeReportScreen({super.key});

  @override
  State<PriceChangeReportScreen> createState() =>
      _PriceChangeReportScreenState();
}

class _PriceChangeReportScreenState extends State<PriceChangeReportScreen> {
  String filterType = "all"; // all / up / down
  final formatter = NumberFormat('#,###');

  // 브랜드 컬러
  static const primaryPurple = Color(0xFF6F6BFF);
  static const softPurple = Color(0xFFF4F3FF);
  static const increaseRed = Color(0xFFFF6B6B);
  static const decreaseGreen = Color(0xFF4ECDC4);

  Future<List<String>> _loadUserSubscriptions() async {
    final uid = UserState.currentUserId;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("subscriptions")
        .get();

    return snap.docs
        .map((d) => (d.data()["providerName"] as String?)?.toLowerCase() ?? "")
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<PriceChangeModel>> _loadChanges() async {
    final subscribedServices = await _loadUserSubscriptions();
    if (subscribedServices.isEmpty) return [];

    final snap =
        await FirebaseFirestore.instance.collection("serviceScrapes").get();

    final filtered = snap.docs.where((doc) {
      final parts = doc.id.split("_");
      if (parts.length < 3) return false;
      final serviceName = parts[1].toLowerCase();
      return subscribedServices.contains(serviceName);
    }).toList();

    Map<String, List<QueryDocumentSnapshot>> grouped = {};
    for (var doc in filtered) {
      final key = doc.id.split("_")[1].toLowerCase();
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(doc);
    }

    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.id.compareTo(a.id));
      if (grouped[key]!.length > 2) {
        grouped[key] = grouped[key]!.sublist(0, 2);
      }
    }

    List<PriceChangeModel> changes = [];

    for (var key in grouped.keys) {
      final docs = grouped[key]!;
      if (docs.length < 2) continue;

      final latest = docs[0].data() as Map<String, dynamic>;
      final prev = docs[1].data() as Map<String, dynamic>;

      final latestPlans = (latest["plans"] ?? []) as List;
      final prevPlans = (prev["plans"] ?? []) as List;

      final prevMap = {for (var p in prevPlans) p["planId"]: p};

      for (var plan in latestPlans) {
        final id = plan["planId"];
        if (!prevMap.containsKey(id)) continue;

        final oldPrice = (prevMap[id]["amount"] as num?)?.toInt() ?? 0;
        final newPrice = (plan["amount"] as num?)?.toInt() ?? 0;

        if (oldPrice != newPrice) {
          changes.add(
            PriceChangeModel(
              serviceName: key,
              planName: plan["planName"] ?? "",
              oldPrice: oldPrice,
              newPrice: newPrice,
            ),
          );
        }
      }
    }

    return changes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "가격 변동 리포트",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: _loadChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primaryPurple),
            );
          }

          final allItems = snapshot.data!;
          if (allItems.isEmpty) {
            return _buildEmptyState();
          }

          // 필터링
          List<PriceChangeModel> items = allItems;
          if (filterType == "up") {
            items = items.where((e) => e.newPrice > e.oldPrice).toList();
          } else if (filterType == "down") {
            items = items.where((e) => e.newPrice < e.oldPrice).toList();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            children: [
              const SizedBox(height: 16),
              // 1. 필터 UI
              _buildSegmentedFilter(),
              const SizedBox(height: 20),
              _buildSummaryCard(allItems),
              const SizedBox(height: 24),
              // 3. 구독 추천 CTA 버튼
              _buildRecommendationCTA(),
              const SizedBox(height: 24),
              // 2. 카드 리스트
              ...items.map((item) => _PriceChangeCard(
                    item: item,
                    formatter: formatter,
                  )),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // 1. 세그먼트 필터 UI
  // ============================================================
  Widget _buildSegmentedFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segmentButton("전체", "all", Icons.list_rounded),
          const SizedBox(width: 4),
          _segmentButton("인상", "up", Icons.trending_up_rounded),
          const SizedBox(width: 4),
          _segmentButton("하락", "down", Icons.trending_down_rounded),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, String value, IconData icon) {
    final selected = filterType == value;
    final Color iconColor = value == "up"
        ? increaseRed
        : value == "down"
            ? decreaseGreen
            : primaryPurple;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filterType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? iconColor : Colors.black45,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.black87 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 요약 카드
  // ============================================================
  Widget _buildSummaryCard(List<PriceChangeModel> list) {
    final up = list.where((e) => e.newPrice > e.oldPrice).length;
    final down = list.where((e) => e.newPrice < e.oldPrice).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [softPurple, softPurple.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, color: primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                "요약 리포트",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem("총 변동", list.length, primaryPurple),
              Container(
                width: 1,
                height: 40,
                color: primaryPurple.withOpacity(0.15),
              ),
              _summaryItem("인상", up, primaryPurple),
              Container(
                width: 1,
                height: 40,
                color: primaryPurple.withOpacity(0.15),
              ),
              _summaryItem("하락", down, primaryPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 3. 구독 추천 CTA 버튼
  // ============================================================
  Widget _buildRecommendationCTA() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.recommendations);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6F6BFF), Color(0xFF9D6BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "더 저렴한 대안 찾기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "AI가 맞춤 구독을 추천해드려요",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: primaryPurple,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: decreaseGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 44,
              color: decreaseGreen,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "가격 변동이 없습니다",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "구독 중인 서비스는 모두 그대로예요.",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 2. 가격 변동 카드 UI
// ============================================================
class _PriceChangeCard extends StatelessWidget {
  final PriceChangeModel item;
  final NumberFormat formatter;

  const _PriceChangeCard({required this.item, required this.formatter});

  static const increaseRed = Color(0xFFFF6B6B);
  static const decreaseGreen = Color(0xFF4ECDC4);

  @override
  Widget build(BuildContext context) {
    final bool isIncrease = item.newPrice > item.oldPrice;
    final Color accentColor = isIncrease ? increaseRed : decreaseGreen;
    final IconData trendIcon =
        isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final String trendLabel = isIncrease ? "인상" : "하락";
    final int diff = (item.newPrice - item.oldPrice).abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // 서비스 로고 플레이스홀더
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item.serviceName.isNotEmpty
                          ? item.serviceName[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.serviceName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.planName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        "${isIncrease ? '+' : '-'}${item.diffRate.abs().toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 가격 비교 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              children: [
                // 기존 가격
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "기존 가격",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.oldPrice.toStringAsFixed(2)} KRW",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                // 화살표 아이콘
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                // 변경 가격
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "변경 가격",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.newPrice.toStringAsFixed(2)} KRW",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단 차이 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncrease
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  "월 ${diff.toStringAsFixed(2)} KRW ${trendLabel}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
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

/// 데이터 모델
class PriceChangeModel {
  final String serviceName;
  final String planName;
  final int oldPrice;
  final int newPrice;

  PriceChangeModel({
    required this.serviceName,
    required this.planName,
    required this.oldPrice,
    required this.newPrice,
  });

  double get diffRate =>
      oldPrice == 0 ? 0 : ((newPrice - oldPrice) / oldPrice) * 100;
}
