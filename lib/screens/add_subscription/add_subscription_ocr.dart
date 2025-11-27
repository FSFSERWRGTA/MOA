import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_router.dart';

/// OCR -> 결과 수정 화면으로 이동할 때 사용할 라우터
/// (나중에 AppRouter에 등록)
class OCRResult {
  final String rawText;
  final String serviceName;
  final int amount;
  final String currency;
  final DateTime paidAt;
  final String periodText;

  OCRResult({
    required this.rawText,
    required this.serviceName,
    required this.amount,
    required this.currency,
    required this.paidAt,
    required this.periodText,
  });
}

class AddSubscriptionOCRScreen extends StatefulWidget {
  const AddSubscriptionOCRScreen({super.key});

  @override
  State<AddSubscriptionOCRScreen> createState() =>
      _AddSubscriptionOCRScreenState();
}

class _AddSubscriptionOCRScreenState extends State<AddSubscriptionOCRScreen> {
  File? _selectedImage;
  bool _loading = false;

  // 이미지 피커
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _runOCR() async {
    if (_selectedImage == null) return;

    setState(() => _loading = true);

    /// 실제 Document AI / Gemini OCR 호출은 나중에 구현
    /// 지금은 1초 후 더미 데이터 반환
    await Future.delayed(const Duration(seconds: 1));

    final dummy = OCRResult(
      rawText: """
넷플릭스 정기결제
15,500원
결제일: 2025-01-05
""",
      serviceName: "Netflix",
      amount: 15500,
      currency: "KRW",
      paidAt: DateTime(2025, 1, 5),
      periodText: "월간 구독",
    );

    setState(() => _loading = false);

    // 결과 수정 화면으로 이동
    Navigator.pushNamed(context, "/add-subscription-confirm", arguments: dummy);
  }

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
          "OCR로 자동 등록",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "영수증 또는 결제내역 캡처를 업로드하면\n구독 정보를 자동으로 추출해드려요.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // 이미지 미리보기
            _selectedImage == null ? _emptyPreview() : _imagePreview(),

            const SizedBox(height: 24),

            // 업로드 버튼 2개 (카메라 / 갤러리)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_camera_outlined,
                    label: "카메라 촬영",
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.image_outlined,
                    label: "갤러리에서 선택",
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // OCR 실행 버튼
            ElevatedButton(
              onPressed: _selectedImage == null || _loading ? null : _runOCR,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF6F6BFF),
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "OCR 분석하기",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // UI 파트
  // ------------------------------

  Widget _emptyPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8FF)),
      ),
      child: const Center(
        child: Text("아직 선택된 이미지가 없어요", style: TextStyle(color: Colors.black54)),
      ),
    );
  }

  Widget _imagePreview() {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.file(_selectedImage!, fit: BoxFit.cover),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Color(0xFF6F6BFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6F6BFF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6F6BFF),
            ),
          ),
        ],
      ),
    );
  }
}
