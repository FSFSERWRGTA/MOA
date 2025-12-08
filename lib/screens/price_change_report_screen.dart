// ---------------------------------------------------------------------------
// 가격 변동 리포트 화면
// 주요 기능:
//   - 사용자가 구독 중인 서비스만 가격 변동 체크
//   - serviceScrapes 컬렉션에서 최신 2개의 데이터를 비교 **따라서 당일 데이터가 있어야 함.
//   - 변동이 있는 플랜만 리스트업하여 UI로 표시
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../user_state.dart';

class PriceChangeReportScreen extends StatefulWidget {
  const PriceChangeReportScreen({super.key});

  @override
  State<PriceChangeReportScreen> createState() =>
      _PriceChangeReportScreenState();
}

class _PriceChangeReportScreenState extends State<PriceChangeReportScreen> {
  // Firestore에서 사용자의 구독 목록을 불러오는 함수
  Future<List<String>> _loadUserSubscriptions() async {
    final uid = UserState.currentUserId;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("subscriptions")
        .get();

    // 구독 문서에서 providerName 또는 serviceId 로 판단
    return snap.docs
        .map((d) => (d.data()["providerName"] as String?)?.toLowerCase() ?? "")
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // 가격 변동 분석 전체 흐름
  Future<List<PriceChangeModel>> _loadChanges() async {
    final subscribedServices = await _loadUserSubscriptions();

    if (subscribedServices.isEmpty) return [];

    // serviceScrapes 전체 불러오기
    final snap =
        await FirebaseFirestore.instance.collection("serviceScrapes").get();

    // 구독 중인 서비스만 필터링
    final filtered = snap.docs.where((doc) {
      final parts = doc.id.split("_");
      if (parts.length < 3) return false;
      final serviceName =
          parts[1].toLowerCase(); // evt_claude_20251207 -> claude
      return subscribedServices.contains(serviceName);
    }).toList();

    // 서비스별로 문서 그룹화 (claude, tving 등)
    Map<String, List<QueryDocumentSnapshot>> grouped = {};
    for (var doc in filtered) {
      final serviceKey = doc.id.split("_")[1].toLowerCase();
      grouped.putIfAbsent(serviceKey, () => []);
      grouped[serviceKey]!.add(doc);
    }

    // 최신 기준으로 정렬 + 최근 2개만 남기기
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.id.compareTo(a.id));
      if (grouped[key]!.length > 2) {
        grouped[key] = grouped[key]!.sublist(0, 2);
      }
    }

    List<PriceChangeModel> changes = [];

    // 실제 가격 비교 로직 수행
    for (var key in grouped.keys) {
      final docs = grouped[key]!;
      if (docs.length < 2) continue;

      final latest = docs[0].data() as Map<String, dynamic>;
      final previous = docs[1].data() as Map<String, dynamic>;

      final latestPlans = (latest["plans"] ?? []) as List;
      final previousPlans = (previous["plans"] ?? []) as List;

      // 이전 플랜을 planId 기준으로 빠르게 찾을 수 있게 map으로 변경
      final prevMap = {for (var p in previousPlans) p["planId"]: p};

      for (var plan in latestPlans) {
        final planId = plan["planId"];
        if (!prevMap.containsKey(planId)) continue;

        final oldPrice = (prevMap[planId]["amount"] as num?)?.toInt() ?? 0;
        final newPrice = (plan["amount"] as num?)?.toInt() ?? 0;

        if (oldPrice != newPrice) {
          changes.add(
            PriceChangeModel(
              serviceName: key,
              planName: plan["planName"] ?? "",
              oldPrice: oldPrice,
              newPrice: newPrice,
              effectiveDate: DateTime.now(),
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
        title: const Text("가격 변동 리포트",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: _loadChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _PriceChangeCard(item: items[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
          SizedBox(height: 12),
          Text("가격 변동이 없습니다.", style: TextStyle(fontSize: 16)),
          SizedBox(height: 6),
          Text("구독 중인 서비스는 모두 그대로에요.",
              style: TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 가격 변동 UI 카드
/// ---------------------------------------------------------------------------
class _PriceChangeCard extends StatelessWidget {
  const _PriceChangeCard({required this.item});
  final PriceChangeModel item;

  @override
  Widget build(BuildContext context) {
    final bool isIncrease = item.newPrice > item.oldPrice;
    final Color color = isIncrease ? Colors.red : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.serviceName,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text(item.planName,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("기존 ${item.oldPrice}원",
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 8),
              Text(
                "${item.newPrice}원",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "변동률: ${item.diffRate.toStringAsFixed(1)}%",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          )
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 모델 객체: 가격 변동 정보를 저장
/// ---------------------------------------------------------------------------
class PriceChangeModel {
  final String serviceName;
  final String planName;
  final int oldPrice;
  final int newPrice;
  final DateTime effectiveDate;

  PriceChangeModel({
    required this.serviceName,
    required this.planName,
    required this.oldPrice,
    required this.newPrice,
    required this.effectiveDate,
  });

  double get diffRate =>
      oldPrice == 0 ? 0 : ((newPrice - oldPrice) / oldPrice) * 100;
}
