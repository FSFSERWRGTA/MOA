// ---------------------------------------------------------------------------
// - 구독 추가 플로우의 첫 화면
// - 사용자가 OCR 자동 등록 또는 직접 입력 중 선택하도록 안내
// - 앱 전체 UX 흐름에서 'entry point' 역할을 수행
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

class AddSubscriptionStartScreen extends StatelessWidget {
  const AddSubscriptionStartScreen({super.key});

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
          "구독 등록",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "두 가지 방식으로 구독을 등록할 수 있어요.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),

            // OCR 자동 등록 버튼
            _OptionButton(
              icon: Icons.document_scanner_outlined,
              title: "영수증 / 결제내역 캡처로 자동 등록",
              subtitle: "금액·설명·날짜를 자동 추출해요",
              onTap: () {
                Navigator.pushNamed(context, Routes.addSubscriptionOCR);
              },
            ),
            const SizedBox(height: 16),

            // 수동 입력 버튼
            _OptionButton(
              icon: Icons.edit_outlined,
              title: "직접 입력해서 등록",
              subtitle: "서비스명, 금액, 날짜 등을 직접 입력",
              onTap: () {
                Navigator.pushNamed(context, Routes.addSubscriptionManual);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF6F6BFF)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
