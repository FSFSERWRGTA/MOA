/*
 * OCR 인식 없이 사용자가 직접 정보를 입력하여 구독을 추가하는 화면
 *
 * [주요 기능 및 로직]
 * 1. 사용자 입력: 서비스명, 금액, 결제 주기(월/년 등), 시작일, 카테고리, 메모
 * 2. 데이터 가공:
 * - providerId: 서비스명을 소문자 및 공백 제거하여 생성 (검색/정렬용)
 * - nextRenewalAt: 시작일과 결제 주기를 기반으로 다음 결제일 자동 계산
 * - billingAnchorDay: 매월 결제되는 날짜(일) 추출
 * 3. Firestore 저장:
 * - 경로: users/{uid}/subscriptions
 * - 사용자 ID(uid): UserState.currentUserId (전역 변수)에서 가져옴
 * - 로그인 상태가 아닐 경우(uid 없음) 예외 처리 포함
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user_state.dart';
import '../../routes/app_router.dart';

class AddSubscriptionManualScreen extends StatefulWidget {
  const AddSubscriptionManualScreen({super.key});

  @override
  State<AddSubscriptionManualScreen> createState() =>
      _AddSubscriptionManualScreenState();
}

class _AddSubscriptionManualScreenState
    extends State<AddSubscriptionManualScreen> {
  // === UI 컨트롤러 ===
  final TextEditingController serviceCtrl = TextEditingController();
  final TextEditingController planCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController currencyCtrl = TextEditingController(text: "KRW");
  final TextEditingController notesCtrl = TextEditingController();

  // === 선택지 데이터 ===
  final _cycles = ["day", "week", "month", "year"];
  final _categories = ["ott", "ai", "music", "cloud", "productivity"];

  // === 상태 변수 ===
  String billingCycle = "month";
  String? category;
  DateTime? startedAt;

  // 저장 중 로딩 상태 표시
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    serviceCtrl.addListener(_updateState);
    amountCtrl.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    serviceCtrl.removeListener(_updateState);
    amountCtrl.removeListener(_updateState);
    serviceCtrl.dispose();
    planCtrl.dispose();
    amountCtrl.dispose();
    currencyCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  // 필수 정보가 모두 입력되었는지 확인하는 getter
  bool get _isFormValid =>
      serviceCtrl.text.trim().isNotEmpty &&
      amountCtrl.text.trim().isNotEmpty &&
      startedAt != null;

  // 다음 결제일 자동 계산 로직
  DateTime _calculateNextRenewal(DateTime start, String cycle) {
    switch (cycle) {
      case 'day':
        return start.add(const Duration(days: 1));
      case 'week':
        return start.add(const Duration(days: 7));
      case 'year':
        return DateTime(start.year + 1, start.month, start.day);
      case 'month':
      default:
        return DateTime(start.year, start.month + 1, start.day);
    }
  }

  // Firestore 저장 함수
  Future<void> _saveToFirestore() async {
    // 버튼이 활성화된 상태에서만 실행되지만, 혹시 모를 안전장치
    if (!_isFormValid) return;

    setState(() => _isSaving = true);

    try {
      final String? uid = UserState.currentUserId;
      if (uid == null || uid.isEmpty) {
        throw Exception("로그인 정보가 없습니다. 다시 로그인해주세요.");
      }

      final String providerName = serviceCtrl.text.trim();
      // 대소문자 통일 (NetFlix -> netflix)로 중복 최소화
      final String providerId = providerName.toLowerCase().replaceAll(' ', '');
      final double amount = double.tryParse(amountCtrl.text) ?? 0;
      final DateTime nextRenewal =
          _calculateNextRenewal(startedAt!, billingCycle);

      final Map<String, dynamic> data = {
        'userId': uid,
        'providerId': providerId,
        'providerName': providerName,
        'planName': planCtrl.text.isEmpty ? null : planCtrl.text,
        'category': category ?? 'uncategorized',
        'billingCycle': billingCycle,
        'amount': amount,
        'currency': currencyCtrl.text,
        'startedAt': Timestamp.fromDate(startedAt!),
        'nextRenewalAt': Timestamp.fromDate(nextRenewal),
        'billingAnchorDay': startedAt!.day,
        'status': 'active',
        'source': 'manual',
        'notes': notesCtrl.text.isEmpty ? null : notesCtrl.text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .add(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("구독이 추가되었습니다!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 실패: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          "구독 수동 등록",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const Text(
              "OCR 없이 직접 입력하여 구독을 등록할 수 있어요.",
              style:
                  TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 20),
            _section("기본 정보", [
              _label("서비스명 *"), // 필수 표시
              _input(serviceCtrl),
              _label("요금제명"),
              _input(planCtrl),
            ]),
            _section("결제 정보", [
              _label("결제 금액 *"), // 필수 표시
              _input(amountCtrl, type: TextInputType.number),
              _label("통화"),
              _input(currencyCtrl),
              _label("구독 시작일 *"), // 필수 표시
              _datePicker(),
            ]),
            _section("청구 주기 / 카테고리", [
              _label("청구 주기"),
              _cycleSelector(),
              _label("카테고리"),
              _categorySelector(),
            ]),
            _section("기타 정보", [_label("메모"), _input(notesCtrl, maxLines: 3)]),
            const SizedBox(height: 30),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black87)),
    );
  }

  Widget _input(
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F7FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8FF))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8FF))),
      ),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: startedAt ?? now,
          firstDate: DateTime(2015),
          lastDate: DateTime(now.year + 5),
        );

        if (selected != null) {
          setState(() => startedAt = selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8FF)),
        ),
        child: Text(
          startedAt == null
              ? "선택하세요"
              : DateFormat("yyyy-MM-dd").format(startedAt!),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _cycleSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cycles.map((c) {
        final selected = c == billingCycle;
        return ChoiceChip(
          label: Text(c,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? const Color(0xFF6F6BFF) : Colors.black87)),
          selected: selected,
          selectedColor: const Color(0xFFEDEBFF),
          backgroundColor: const Color(0xFFF7F7FF),
          side: BorderSide(
              color:
                  selected ? const Color(0xFF6F6BFF) : const Color(0xFFE8E8FF)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          onSelected: (_) => setState(() => billingCycle = c),
        );
      }).toList(),
    );
  }

  Widget _categorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((c) {
        final selected = c == category;
        return ChoiceChip(
          label: Text(c,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? const Color(0xFF6F6BFF) : Colors.black87)),
          selected: selected,
          selectedColor: const Color(0xFFEDEBFF),
          backgroundColor: const Color(0xFFF7F7FF),
          side: BorderSide(
              color:
                  selected ? const Color(0xFF6F6BFF) : const Color(0xFFE8E8FF)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          onSelected: (_) => setState(() => category = c),
        );
      }).toList(),
    );
  }

  Widget _saveButton() {
    // 폼 유효성에 따라 버튼 활성화/비활성화
    // _isFormValid가 true일 때만 함수 연결, 아니면 null(비활성)
    final bool isEnabled = _isFormValid && !_isSaving;

    return ElevatedButton(
      onPressed: isEnabled ? _saveToFirestore : null,
      style: ElevatedButton.styleFrom(
        // 활성화: 보라색, 비활성화: 회색
        backgroundColor:
            isEnabled ? const Color(0xFF6F6BFF) : const Color(0xFFE0E0E0),
        // 활성화: 흰색 글자, 비활성화: 짙은 회색 글자
        foregroundColor: isEnabled ? Colors.white : const Color(0xFF9E9E9E),
        disabledBackgroundColor: const Color(0xFFE0E0E0),
        disabledForegroundColor: const Color(0xFF9E9E9E),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Text("저장하기",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}
