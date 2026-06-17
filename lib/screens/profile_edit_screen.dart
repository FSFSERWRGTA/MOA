/*
 * 회원정보 수정 화면
 * - 항목별 편집 불가: 이름만 바꾸려 해도 성별/생년월일을 모두 다시 입력해야 저장됨.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../user_state.dart';

enum _EditGender { female, male }

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const purple = Color(0xFF6F6BFF);

  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  _EditGender? _gender;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    void rebuild() => setState(() {});
    _nameCtrl.addListener(rebuild);
    _nicknameCtrl.addListener(rebuild);
    _phoneCtrl.addListener(rebuild);
    _emailCtrl.addListener(rebuild);
    _zipCtrl.addListener(rebuild);
    _address1Ctrl.addListener(rebuild);
    _address2Ctrl.addListener(rebuild);
    _jobCtrl.addListener(rebuild);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _zipCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _jobCtrl.dispose();
    super.dispose();
  }

  // 모든 항목을 다시 입력해야만 저장 가능 (항목별 편집 불가)
  bool get _isValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _nicknameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _zipCtrl.text.trim().isNotEmpty &&
      _address1Ctrl.text.trim().isNotEmpty &&
      _address2Ctrl.text.trim().isNotEmpty &&
      _jobCtrl.text.trim().isNotEmpty &&
      _gender != null &&
      _birthDate != null;

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '생년월일 선택',
      confirmText: '확인',
      cancelText: '취소',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);
    try {
      final uid = UserState.currentUserId;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameCtrl.text.trim(),
          'nickname': _nicknameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'zipCode': _zipCtrl.text.trim(),
          'address1': _address1Ctrl.text.trim(),
          'address2': _address2Ctrl.text.trim(),
          'job': _jobCtrl.text.trim(),
          'gender': _gender == _EditGender.male ? 'male' : 'female',
          'birthDate': _formatDate(_birthDate!),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('회원정보 수정',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '모든 항목을 다시 입력해야 저장됩니다.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // 이름
              const _Label('이름'),
              TextField(
                controller: _nameCtrl,
                decoration: _dec('이름을 입력해주세요'),
              ),
              const SizedBox(height: 18),

              // 닉네임
              const _Label('닉네임'),
              TextField(
                controller: _nicknameCtrl,
                decoration: _dec('닉네임을 입력해주세요'),
              ),
              const SizedBox(height: 18),

              // 휴대폰 번호
              const _Label('휴대폰 번호'),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec('010-0000-0000'),
              ),
              const SizedBox(height: 18),

              // 이메일
              const _Label('이메일'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('example@email.com'),
              ),
              const SizedBox(height: 18),

              // 우편번호
              const _Label('우편번호'),
              TextField(
                controller: _zipCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('우편번호 5자리'),
              ),
              const SizedBox(height: 18),

              // 주소
              const _Label('주소'),
              TextField(
                controller: _address1Ctrl,
                decoration: _dec('기본 주소'),
              ),
              const SizedBox(height: 18),

              // 상세 주소
              const _Label('상세 주소'),
              TextField(
                controller: _address2Ctrl,
                decoration: _dec('동/호수 등 상세 주소'),
              ),
              const SizedBox(height: 18),

              // 직업
              const _Label('직업'),
              TextField(
                controller: _jobCtrl,
                decoration: _dec('직업을 입력해주세요'),
              ),
              const SizedBox(height: 18),

              // 성별
              const _Label('성별'),
              Row(
                children: [
                  _genderChip('남성', _EditGender.male),
                  const SizedBox(width: 8),
                  _genderChip('여성', _EditGender.female),
                ],
              ),
              const SizedBox(height: 18),

              // 생년월일
              const _Label('생년월일'),
              GestureDetector(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: _dec('생년월일을 선택해주세요'),
                  child: Text(
                    _birthDate == null ? '생년월일을 선택해주세요' : _formatDate(_birthDate!),
                    style: TextStyle(
                      color:
                          _birthDate == null ? Colors.black38 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isValid && !_saving) ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    disabledBackgroundColor: const Color(0xFFBFB8FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderChip(String label, _EditGender value) {
    final selected = _gender == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _gender = value),
      selectedColor: const Color(0xFFEDEBFF),
      backgroundColor: Colors.white,
      labelStyle:
          TextStyle(color: selected ? purple : Colors.black87),
      side: BorderSide(
          color: selected ? purple : const Color(0xFFE8E8FF)),
    );
  }

  InputDecoration _dec(String hint) {
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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
