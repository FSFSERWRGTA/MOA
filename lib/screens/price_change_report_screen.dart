import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 가격 변동 리포트 화면
class PriceChangeReportScreen extends StatefulWidget {
  const PriceChangeReportScreen({super.key});

  @override
  State<PriceChangeReportScreen> createState() =>
      _PriceChangeReportScreenState();
}

class _PriceChangeReportScreenState extends State<PriceChangeReportScreen> {
  final NumberFormat comma = NumberFormat('#,###');

  // 현재 선택된 필터 (전체/인상/인하)
  String selectedFilter = "전체";

  // 더미 가격 변동 데이터
  // 실제로는 Firestore에서 받아올 예정
  final List<Map<String, dynamic>> priceChanges = [
    {
      "serviceName": "Netflix",
      "oldPrice": 15500,
      "newPrice": 17200,
      "diffRate": 11.1,
      "effectiveDate": DateTime(2025, 2, 7),
    },
    {
      "serviceName": "YouTube Premium",
      "oldPrice": 10900,
      "newPrice": 7900,
      "diffRate": -27.5,
      "effectiveDate": DateTime(2025, 1, 30),
    },
    {
      "serviceName": "Wave",
      "oldPrice": 7900,
      "newPrice": 8900,
      "diffRate": 12.7,
      "effectiveDate": DateTime(2025, 3, 1),
    },
  ];

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F6FF);

    // 선택된 필터에 맞춰 데이터 필터링
    final filtered = priceChanges.where((item) {
      final r = item["diffRate"] as double;
      if (selectedFilter == "전체") return true;
      if (selectedFilter == "인상") return r > 0;
      if (selectedFilter == "인하") return r < 0;
      return true;
    }).toList();

    // 데이터가 마지막으로 업데이트된 시각 (예: 서버에서 응답한 timestamp)
    final lastChecked = DateTime(2025, 2, 8, 14, 30);

    return Scaffold(
      backgroundColor: bg,

      // 상단 AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        centerTitle: true,
        title: const Text(
          "가격 변동 리포트",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),

      // 메인 UI
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 필터 선택 버튼 Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _filterButton("전체"),
                _filterButton("인상"),
                _filterButton("인하"),
              ],
            ),

            const SizedBox(height: 24),

            // 제목 텍스트
            const Text(
              "최근 감지된 가격 변동",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 가격 변동 리스트
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return _PriceChangeCard(
                    name: item["serviceName"],
                    oldP: item["oldPrice"],
                    newP: item["newPrice"],
                    rate: item["diffRate"],
                    date: item["effectiveDate"],
                    fmt: comma,
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // 업데이트 기준 (하단 고정 표시)
            Center(
              child: Text(
                "업데이트 기준 · "
                "${lastChecked.year}-${lastChecked.month.toString().padLeft(2, '0')}-${lastChecked.day.toString().padLeft(2, '0')}  "
                "${lastChecked.hour.toString().padLeft(2, '0')}:${lastChecked.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 필터 버튼 위젯
  // label: "전체" / "인상" / "인하"
  Widget _filterButton(String label) {
    final bool active = (label == selectedFilter);

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF7C78FF), Color(0xFF6F6BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.white,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(
            color: active ? const Color(0xFF6F6BFF) : const Color(0xFFE1E3F8),
          ),

          boxShadow: [
            if (active)
              BoxShadow(
                color: const Color(0xFF6F6BFF).withOpacity(0.25),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
          ],
        ),

        // 라벨 텍스트
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ----------- 가격 변동 카드 -----------
class _PriceChangeCard extends StatelessWidget {
  final String name; // 서비스명
  final int oldP; // 이전 가격
  final int newP; // 변경된 가격
  final double rate; // 변동률 (%)
  final DateTime date; // 반영일
  final NumberFormat fmt;

  const _PriceChangeCard({
    required this.name,
    required this.oldP,
    required this.newP,
    required this.rate,
    required this.date,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = rate > 0; // 인상인지 인하인지 구분
    final color = isUp ? Colors.red : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E8F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 서비스명 + 변동률 표시 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 서비스 이름
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),

              // 변화 아이콘 + 퍼센트
              Row(
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${rate > 0 ? '+' : ''}${rate.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 가격 변화 텍스트
          Text(
            "₩${fmt.format(oldP)}  →  ₩${fmt.format(newP)}",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // 반영일 표시
          Text(
            "반영일: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
