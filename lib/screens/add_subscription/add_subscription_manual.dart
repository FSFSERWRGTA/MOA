import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes/app_router.dart';

class AddSubscriptionManualScreen extends StatefulWidget {
  const AddSubscriptionManualScreen({super.key});

  @override
  State<AddSubscriptionManualScreen> createState() =>
      _AddSubscriptionManualScreenState();
}

class _AddSubscriptionManualScreenState
    extends State<AddSubscriptionManualScreen> {
  final TextEditingController serviceCtrl = TextEditingController();
  final TextEditingController planCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController currencyCtrl = TextEditingController(text: "KRW");
  final TextEditingController notesCtrl = TextEditingController();

  final _cycles = ["day", "week", "month", "year"];
  final _categories = ["streaming", "ai", "music", "cloud", "productivity"];

  String billingCycle = "month";
  String? category;
  DateTime? startedAt;

  @override
  void dispose() {
    serviceCtrl.dispose();
    planCtrl.dispose();
    amountCtrl.dispose();
    currencyCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Text(
            "OCR 없이 직접 입력하여 구독을 등록할 수 있어요.",
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),

          _section("기본 정보", [
            _label("서비스명"),
            _input(serviceCtrl),

            _label("요금제명"),
            _input(planCtrl),
          ]),

          _section("결제 정보", [
            _label("결제 금액"),
            _input(amountCtrl, type: TextInputType.number),

            _label("통화"),
            _input(currencyCtrl),

            _label("구독 시작일"),
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8FF)),
        ),
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
          label: Text(
            c,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF6F6BFF) : Colors.black87,
            ),
          ),
          selected: selected,
          selectedColor: const Color(0xFFEDEBFF),
          backgroundColor: const Color(0xFFF7F7FF),
          side: BorderSide(
            color: selected ? const Color(0xFF6F6BFF) : const Color(0xFFE8E8FF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          onSelected: (_) {
            setState(() => billingCycle = c);
          },
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
          label: Text(
            c,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF6F6BFF) : Colors.black87,
            ),
          ),
          selected: selected,
          selectedColor: const Color(0xFFEDEBFF),
          backgroundColor: const Color(0xFFF7F7FF),
          side: BorderSide(
            color: selected ? const Color(0xFF6F6BFF) : const Color(0xFFE8E8FF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          onSelected: (_) {
            setState(() => category = c);
          },
        );
      }).toList(),
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("구독이 저장되었습니다! (Firestore 연결 예정)"),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F6BFF),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        "저장하기",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}
