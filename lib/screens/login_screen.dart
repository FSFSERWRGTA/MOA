import 'package:flutter/material.dart';
import '../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool get _isValid =>
      _idCtrl.text.trim().isNotEmpty && _pwCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6F6BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === 헤더 ===
                  Column(
                    children: const [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFEDEBFF),
                        child: Icon(
                          Icons.lock_outline,
                          color: Color(0xFF6F6BFF),
                          size: 28,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '다시 오신 걸 환영합니다 👋',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // === 카드형 폼 ===
                  Card(
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                      child: Form(
                        key: _formKey,
                        onChanged: () => setState(() {}),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FieldLabel('아이디'),
                            TextFormField(
                              controller: _idCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(hint: '아이디를 입력해주세요'),
                              validator: (v) =>
                                  v!.trim().isEmpty ? '아이디를 입력해주세요' : null,
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('비밀번호'),
                            TextFormField(
                              controller: _pwCtrl,
                              obscureText: true,
                              decoration: _inputDecoration(
                                hint: '비밀번호를 입력해주세요',
                              ),
                              validator: (v) =>
                                  v!.trim().isEmpty ? '비밀번호를 입력해주세요' : null,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: 비밀번호 찾기 페이지 연결
                                },
                                child: const Text(
                                  '비밀번호를 잊으셨나요?',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === 로그인 버튼 ===
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isValid ? _onLogin : null,
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
                      child: const Text('로그인'),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // === 회원가입 링크 ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '아직 계정이 없으신가요? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.signup),
                        child: const Text('회원가입'),
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

  // 로그인 버튼 동작
  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그인 성공! 홈 화면으로 이동합니다.')));

    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacementNamed(context, Routes.home);
    });
  }

  // 공통 입력 스타일
  InputDecoration _inputDecoration({String? hint}) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black26, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: base,
      focusedBorder: base.copyWith(
        borderSide: const BorderSide(color: Colors.black54, width: 1.2),
      ),
    );
  }
}

// === 공통 레이블 위젯 ===
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
