import 'package:flutter/material.dart';
import '../routes/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

enum Gender { female, male }

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  Gender? _gender;
  DateTime? _birthDate;
  bool _agree = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _gender != null &&
      _birthDate != null &&
      _agree;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6F6BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  Column(
                    children: const [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFEDEBFF),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF6F6BFF),
                          size: 28,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '몇 가지 정보를 입력하면 바로 시작할 수 있어요.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 카드 폼
                  Card(
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                      child: Form(
                        key: _formKey,
                        onChanged: () => setState(() {}),
                        autovalidateMode:
                            AutovalidateMode.disabled, //  한글 조합 보호
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FieldLabel('이름'),
                            TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.name, // 이름 키보드
                              textCapitalization: TextCapitalization.words,
                              enableSuggestions: true,
                              decoration: _inputDecoration(hint: '실명 입력'),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return '이름을 입력해주세요';
                                // 한글 완성형 + 자모 + 영문 + 공백 허용
                                final nameReg = RegExp(
                                  r'^[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z\s]+$',
                                );
                                if (!nameReg.hasMatch(value)) {
                                  return '한글 또는 영문만 입력 가능합니다';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            const _FieldLabel('성별'),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('남성'),
                                  selected: _gender == Gender.male,
                                  onSelected: (_) =>
                                      setState(() => _gender = Gender.male),
                                  selectedColor: const Color(0xFFEDEBFF),
                                  labelStyle: TextStyle(
                                    color: _gender == Gender.male
                                        ? purple
                                        : Colors.black87,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('여성'),
                                  selected: _gender == Gender.female,
                                  onSelected: (_) =>
                                      setState(() => _gender = Gender.female),
                                  selectedColor: const Color(0xFFEDEBFF),
                                  labelStyle: TextStyle(
                                    color: _gender == Gender.female
                                        ? purple
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            const _FieldLabel('생년월일'),
                            GestureDetector(
                              onTap: _pickBirthDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: _inputDecoration(
                                    hint: '달력에서 선택',
                                    suffix: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: _birthDate == null
                                        ? ''
                                        : _formatDate(_birthDate!),
                                  ),
                                  validator: (_) => _birthDate == null
                                      ? '생년월일을 선택해주세요'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 이용약관 동의
                            Row(
                              children: [
                                Checkbox(
                                  value: _agree,
                                  onChanged: (v) =>
                                      setState(() => _agree = v ?? false),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Expanded(
                                  child: Text(
                                    '[필수] 개인정보 처리방침에 동의합니다',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: 약관 페이지 연결
                                  },
                                  child: const Text('보기'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 가입 버튼
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isValid ? _onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        disabledBackgroundColor: const Color(0xFFBFB8FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('가입하기'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 하단 보조 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '이미 계정이 있으신가요? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('로그인'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 날짜 선택 (전역 MaterialApp에서 ko-KR 설정돼 있으면 자동 한글)
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100, 1, 1);
    final lastDate = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, 1, 1),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '생년월일 선택',
      confirmText: '확인',
      cancelText: '취소',
      // locale: const Locale('ko', 'KR'), // 전역에서 ko-KR이면 옵션 생략 가능
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF6F6BFF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _birthDate = picked);
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다!')));

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacementNamed(context, Routes.home);
    });
  }

  // 공통 인풋 보더
  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black26, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: base,
      focusedBorder: base.copyWith(
        borderSide: const BorderSide(color: Colors.black54, width: 1.2),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// 작은 레이블 위젯
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
