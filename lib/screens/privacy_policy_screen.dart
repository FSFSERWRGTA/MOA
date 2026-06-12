/*
 * 개인정보 처리방침 화면
 */

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '개인정보 처리방침',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: const [
            Text(
              'MOA(이하 "회사")는 「개인정보 보호법」 등 관련 법령을 준수하며, '
              '이용자의 개인정보를 다음과 같이 처리합니다. 본 방침은 회사가 제공하는 '
              '구독 관리 서비스에 적용됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.6),
            ),
            SizedBox(height: 8),
            Text(
              '시행일자: 2026년 6월 11일',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            SizedBox(height: 24),

            _Section(
              title: '1. 수집하는 개인정보 항목',
              body:
                  '회사는 회원가입 및 서비스 제공을 위해 아래의 개인정보를 수집합니다.\n\n'
                  '• 필수 항목: 아이디, 비밀번호, 이름, 성별, 생년월일\n'
                  '• 서비스 이용 과정에서 생성·수집되는 정보: 구독 서비스명, 요금제, '
                  '결제 금액, 결제 주기, 결제일 등 구독 관리 정보\n'
                  '• 자동 수집 항목: 서비스 이용 기록, 접속 일시',
            ),
            _Section(
              title: '2. 개인정보의 수집 및 이용 목적',
              body: '회사는 수집한 개인정보를 다음의 목적으로 이용합니다.\n\n'
                  '• 회원 식별 및 본인 확인, 로그인 등 회원 관리\n'
                  '• 구독 현황 관리, 지출 분석 및 리포트 제공\n'
                  '• 맞춤형 요금제·서비스 추천 기능 제공\n'
                  '• 서비스 개선 및 신규 서비스 개발',
            ),
            _Section(
              title: '3. 개인정보의 보유 및 이용 기간',
              body:
                  '회사는 원칙적으로 개인정보 수집·이용 목적이 달성되면 해당 정보를 지체 없이 '
                  '파기합니다. 다만, 회원 탈퇴 시까지 회원 정보를 보유하며, 관계 법령에 따라 '
                  '보존할 필요가 있는 경우 해당 기간 동안 보관합니다.',
            ),
            _Section(
              title: '4. 개인정보의 제3자 제공',
              body:
                  '회사는 이용자의 개인정보를 본 방침에서 명시한 목적 범위를 초과하여 이용하거나 '
                  '제3자에게 제공하지 않습니다. 다만, 이용자가 사전에 동의한 경우 또는 법령에 '
                  '따라 요구되는 경우는 예외로 합니다.',
            ),
            _Section(
              title: '5. 개인정보의 처리 위탁',
              body: '회사는 안정적인 서비스 제공을 위해 아래와 같이 개인정보 처리 업무를 '
                  '위탁할 수 있습니다.\n\n'
                  '• 클라우드 인프라(데이터 저장): Google Firebase\n'
                  '• AI 분석(영수증 인식·추천): Google Gemini API',
            ),
            _Section(
              title: '6. 이용자의 권리와 행사 방법',
              body:
                  '이용자는 언제든지 본인의 개인정보를 조회·수정하거나 회원 탈퇴를 통해 개인정보의 '
                  '삭제를 요청할 수 있습니다. 회사는 이용자의 요청을 지체 없이 처리합니다.',
            ),
            _Section(
              title: '7. 개인정보의 안전성 확보 조치',
              body: '회사는 개인정보의 분실·도난·유출·변조 등을 방지하기 위해 접근 권한 관리, '
                  '접근 통제 등 기술적·관리적 보호 조치를 취하고 있습니다.',
            ),
            _Section(
              title: '8. 개인정보 보호책임자 및 문의처',
              body: '개인정보 처리에 관한 문의는 아래로 연락해 주시기 바랍니다.\n\n'
                  '• 개인정보 보호책임자: MOA 운영팀\n'
                  '• 이메일: privacy@moa.app',
            ),

            SizedBox(height: 8),
            Text(
              '본 개인정보 처리방침은 관련 법령 및 회사 정책에 따라 변경될 수 있으며, '
              '변경 시 서비스 내 공지를 통해 안내합니다.',
              style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
