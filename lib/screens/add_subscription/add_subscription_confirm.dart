import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_subscription_ocr.dart'; // OCRResult 가져오는 용도
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
  late TextEditingController serviceCtrl;
  late TextEditingController planCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController currencyCtrl;
  late TextEditingController notesCtrl;

  DateTime? paidAt;
  String billingCycle = "month"; // 기본 월 구독

  final _cycles = ["day", "week", "month", "year"];

  @override
  void initState() {
    super.initState();

    serviceCtrl = TextEditingController(text: widget.result.serviceName);
    planCtrl = TextEditingController(text: "");
    amountCtrl = TextEditingController(text: widget.result.amount.toString());
    currencyCtrl = TextEditingController(text: widget.result.currency);
    notesCtrl = TextEditingController();

    paidAt = widget.result.paidAt;
  }

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
          "구독 정보 확인",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Text(
            "OCR에서 추출한 구독 정보를 확인해주세요.\n잘못된 정보는 수정할 수 있어요.",
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 24),

          _subtitle("서비스명"),
          _input(serviceCtrl),

          _subtitle("요금제명"),
          _input(planCtrl),

          _subtitle("결제 금액"),
          _input(amountCtrl, type: TextInputType.number),

          _subtitle("통화"),
          _input(currencyCtrl),

          _subtitle("결제일"),
          _datePicker(),

          _subtitle("청구 주기"),
          _cycleSelector(),

          _subtitle("메모"),
          _input(notesCtrl, maxLines: 3),
          const SizedBox(height: 30),

          _saveButton(),
        ],
      ),
    );
  }

  Widget _subtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 20),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: () {
        // 실제 Firestore 저장은 아ㅏ직 구현x
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("저장 완료! (Firestore 연결 예정)"),
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
