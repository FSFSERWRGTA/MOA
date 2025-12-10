/*
 * 이미지 기반 구독 등록 화면
 *
 * [주요 기능]
 * 1. 이미지 선택: 카메라 촬영 또는 갤러리에서 영수증/결제내역 이미지 선택
 * 2. AI 분석: Gemini 2.0 Flash API를 통해 이미지에서 구독 정보 자동 추출
 * 3. 화면 이동: 추출된 정보를 확인 화면(add_subscription_confirm)으로 전달
 *
 * [화면 흐름]
 * 구독 추가 선택 → [현재 화면: 이미지 업로드 & AI 분석] → 구독 정보 확인 → Firestore 저장
 *
 * [사용 패키지]
 * - image_picker: 카메라/갤러리 이미지 선택
 * - gemini_ocr_service: Gemini 2.0 Flash API 호출 및 JSON 파싱
 * ---------------------------------------------------------------------------
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_router.dart';
import '../../model/ocr_result.dart';
import '../../services/gemini_ocr_service.dart';

class AddSubscriptionOCRScreen extends StatefulWidget {
  const AddSubscriptionOCRScreen({super.key});

  @override
  State<AddSubscriptionOCRScreen> createState() =>
      _AddSubscriptionOCRScreenState();
}

class _AddSubscriptionOCRScreenState extends State<AddSubscriptionOCRScreen> {
  File? _selectedImage;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _selectedImage = File(picked.path));
  }

  // Gemini API 호출 -> 다음 화면으로 이동
  Future<void> _runOCR() async {
    if (_selectedImage == null) return;

    setState(() => _loading = true);

    try {
      // Gemini API 호출
      final ocrResult = await GeminiOCRService.extract(_selectedImage!);

      // 다음 화면으로 이동 (ocrResult 그대로 전달)
      if (mounted) {
        Navigator.pushNamed(
          context,
          Routes.addSubscriptionConfirm,
          arguments: ocrResult,
        );
      }
    } catch (e) {
      print("OCR 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지에서 정보를 추출하지 못했습니다. 다시 시도해주세요.")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          "이미지로 간편 등록",
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
                      "분석하기",
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
