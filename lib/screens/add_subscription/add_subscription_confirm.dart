/*
 * OCR 결과 확인 및 최종 저장 화면
 *
 * [역할]
 * - ocr_result에서 자동으로 필드 채우기 (서비스명, 금액, 날짜, 통화 등)
 * - 사용자가 수정 가능
 * - Firestore에 subscriptions/{uid} 형태로 저장
 * - 결제 주기(billingCycle)에 따른 nextRenewalAt 자동 계산
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user_state.dart';
import '../../model/ocr_result.dart';
import '../../routes/app_router.dart';

class AddSubscriptionConfirmScreen extends StatefulWidget {
  final OCRResult result;

  const AddSubscriptionConfirmScreen({super.key, required this.result});

  @override
  State<AddSubscriptionConfirmScreen> createState() =>
      _AddSubscriptionConfirmScreenState();
}

class _AddSubscriptionConfirmScreenState
    extends State<AddSubscriptionConfirmScreen> {
  // === UI 컨트롤러 ===
  late TextEditingController serviceCtrl;
  late TextEditingController planCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController currencyCtrl;
  late TextEditingController notesCtrl;

  // === 선택지 데이터 ===
  final _cycles = ["day", "week", "month", "year"];
  final _categories = ["OTT", "AI 툴", "음악", "클라우드", "생산성"];

  // === 상태 변수 ===
  DateTime? paidAt;
  String billingCycle = "month";
  String? category;

  // 저장 중 로딩 상태 표시
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    serviceCtrl = TextEditingController(text: widget.result.serviceName ?? '');
    planCtrl = TextEditingController(text: widget.result.planName ?? '');
    amountCtrl =
        TextEditingController(text: widget.result.amount?.toString() ?? '');
    currencyCtrl = TextEditingController(text: widget.result.currency ?? 'KRW');
    notesCtrl = TextEditingController();

    paidAt = widget.result.paidAt;

    // OCR 결과에서 카테고리 자동 설정
    if (widget.result.category != null &&
        _categories.contains(widget.result.category)) {
      category = widget.result.category;
    }

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
      paidAt != null;

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
    if (!_isFormValid) return;

    setState(() => _isSaving = true);

    try {
      final String? uid = UserState.currentUserId;
      if (uid == null || uid.isEmpty) {
        throw Exception("로그인 정보가 없습니다. 다시 로그인해주세요.");
      }

      final String providerName = serviceCtrl.text.trim();
      final String providerId = providerName.toLowerCase().replaceAll(' ', '');
      final double amount = double.tryParse(amountCtrl.text) ?? 0;
      final DateTime nextRenewal = _calculateNextRenewal(paidAt!, billingCycle);

      final Map<String, dynamic> data = {
        'userId': uid,
        'providerId': providerId,
        'providerName': providerName,
        'planName': planCtrl.text.isEmpty ? null : planCtrl.text,
        'category': category ?? 'uncategorized',
        'billingCycle': billingCycle,
        'amount': amount,
        'currency': currencyCtrl.text,
        'startedAt': Timestamp.fromDate(paidAt!),
        'nextRenewalAt': Timestamp.fromDate(nextRenewal),
        'billingAnchorDay': paidAt!.day,
        'status': 'active',
        'source': 'ocr',
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

      // 구독 추가 첫화면으로 돌아가기
      Navigator.popUntil(context, ModalRoute.withName(Routes.addSubscription));
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
          "구독 정보 확인",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const Text(
              "이미지에서 추출한 정보를 확인한 뒤 저장해주세요.",
              style:
                  TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 20),
            _section("기본 정보", [
              _label("서비스명 *"),
              _input(serviceCtrl),
              _label("요금제명"),
              _input(planCtrl),
            ]),
            _section("결제 정보", [
              _label("결제 금액 *"),
              _input(amountCtrl, type: TextInputType.number),
              _label("통화"),
              _input(currencyCtrl),
              _label("결제일 *"),
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
          initialDate: paidAt ?? now,
          firstDate: DateTime(2015),
          lastDate: DateTime(now.year + 5),
        );

        if (selected != null) {
          setState(() => paidAt = selected);
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
          paidAt == null ? "선택하세요" : DateFormat("yyyy-MM-dd").format(paidAt!),
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
    final bool isEnabled = _isFormValid && !_isSaving;

    return ElevatedButton(
      onPressed: isEnabled ? _saveToFirestore : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? const Color(0xFF6F6BFF) : const Color(0xFFE0E0E0),
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
