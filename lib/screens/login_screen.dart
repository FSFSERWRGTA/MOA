import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../user_state.dart';
import '../utils/password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  // 로딩 상태를 관리할 변수
  bool _isLoading = false;

  // 로그인 화면에 들어올 때마다(로그아웃 후 재진입 포함) 처음 N번은 무조건 실패시킴.
  // static 이 아니므로 화면이 새로 생성될 때마다 0으로 리셋됨.
  int _loginAttempts = 0;
  static const int _forcedFailCount = 3;

  // 로딩 중이 아닐 때만 버튼이 활성화되도록 수정
  bool get _isValid =>
      !_isLoading &&
      _idCtrl.text.trim().isNotEmpty &&
      _pwCtrl.text.trim().isNotEmpty;

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
                                onPressed: _isLoading
                                    ? null
                                    : () {
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
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('로그인'),
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
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, Routes.signup),
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
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 의도적으로 처음 2번은 로그인 실패 처리
    _loginAttempts++;
    if (_loginAttempts <= _forcedFailCount) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다')),
        );
        // 실패 시 입력값 초기화 (처음부터 다시 입력)
        _idCtrl.clear();
        _pwCtrl.clear();
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final enteredId = _idCtrl.text.trim();
      final enteredPassword = _pwCtrl.text.trim();

      // Firestore에서 사용자가 입력한 아이디로 문서를 찾음
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(enteredId)
          .get();

      if (userDoc.exists) {
        // 문서가 존재하면, 저장된 비밀번호와 입력된 비밀번호를 비교
        final storedPassword = userDoc.data()?['passwd'];
        if (storedPassword == hashPassword(enteredPassword)) {
          // --- 로그인 성공 ---
          // 로그인 성공 시 전역 변수에 아이디 저장
          UserState.currentUserId = enteredId;

          if (mounted) {
            Navigator.pushReplacementNamed(context, Routes.home);
          }
        } else {
          // 비밀번호 불일치
          throw Exception('wrong-password');
        }
      } else {
        // 아이디 (문서) 없음
        throw Exception('user-not-found');
      }
    } catch (e) {
      // [디버깅] 오류의 실제 원인을 콘솔에 출력!
      print('로그인 오류 상세: $e');

      // 모든 로그인 오류 메시지를 통일
      const message = '로그인에 실패했습니다';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        // 실패 시 입력값 초기화 (처음부터 다시 입력)
        _idCtrl.clear();
        _pwCtrl.clear();
      }
    } finally {
      // 성공/실패와 관계없이 로딩 상태 해제
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
