/*
 * 도움말 화면
 * - 자주 묻는 질문(FAQ)을 ExpansionTile로 펼쳐 볼 수 있음
 * - 오른쪽 아래 챗봇 버튼을 누르면 채팅 시트가 열림
 *   (단, 챗봇은 무엇을 물어도 "이해하지 못했다"는 식의 답만 반복함)
 */

import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const purple = Color(0xFF6F6BFF);

  // 자주 묻는 질문 목록
  // (고객센터 안내 말투로 정중하게 응대하지만, 정작 질문의 해결책은 알려주지 않음)
  static const List<_Faq> _faqs = [
    _Faq(
      'OCR로 구독을 추가했는데 금액이 잘못 인식됐어요. 어떻게 수정하나요?',
      '안녕하세요, 고객님. 문의 주셔서 감사합니다.\n\n'
          'OCR 인식 결과는 이미지의 화질, 조명, 촬영 각도 등 다양한 환경 요인에 따라 '
          '일부 차이가 발생할 수 있는 점 양해 부탁드립니다. '
          '보다 정확한 인식을 위해 밝고 선명한 환경에서 다시 시도해 주시기 바랍니다. '
          '인식 정확도는 지속적으로 개선되고 있으며, 이용에 불편을 드린 점 깊이 사과드립니다.',
    ),
    _Faq(
      '구독을 실수로 삭제했어요. 되돌릴 수 있나요?',
      '안녕하세요, 고객님. 불편을 드려 죄송합니다.\n\n'
          '삭제된 항목의 복구 가능 여부는 처리 상황에 따라 달라질 수 있습니다. '
          '소중한 구독 정보가 손실되지 않도록, 삭제 전 한 번 더 확인하시기를 권장드립니다. '
          '앞으로 보다 안정적인 서비스 제공을 위해 노력하겠습니다. 이용에 참고 부탁드립니다.',
    ),
    _Faq(
      '영수증을 올렸는데 분석이 멈춰요.',
      '안녕하세요, 고객님. 이용에 불편을 드려 죄송합니다.\n\n'
          '일시적인 네트워크 환경 또는 서버 상태에 따라 분석이 지연될 수 있습니다. '
          '네트워크 연결 상태를 확인하신 후, 잠시 뒤 다시 시도해 주시기 바랍니다. '
          '증상이 지속될 경우 앱을 종료 후 재실행해 주시면 도움이 될 수 있습니다. '
          '원활한 서비스 제공을 위해 최선을 다하겠습니다.',
    ),
    _Faq(
      '결제일 알림이 안 와요.',
      '안녕하세요, 고객님. 문의 주셔서 감사합니다.\n\n'
          '알림은 다양한 환경적 요인에 따라 발송 여부 및 시점이 달라질 수 있으며, '
          '다가오는 결제는 홈 화면과 "내 구독"에서도 확인하실 수 있으니 참고해주세요.  '
          '알림이 잘 오는지는 기기나 사용 환경에 따라 다를 수 있어요. '
          '앞으로도 변함없는 서비스로 보답하겠습니다.',
    ),
    _Faq(
      '추천된 더 저렴한 플랜으로 어떻게 전환하나요?',
      '안녕하세요, 고객님. 합리적인 구독 관리에 관심 가져 주셔서 감사합니다.\n\n'
          '플랜 전환 절차 및 조건은 각 서비스 제공처의 정책에 따라 상이할 수 있습니다. '
          '자세한 전환 방법은 해당 서비스의 공식 안내를 참고해 주시기 바랍니다. '
          '고객님께 더욱 유용한 추천을 제공할 수 있도록 지속적으로 개선해 나가겠습니다.',
    ),
    _Faq(
      '달러로 결제하는 해외 구독은 어떻게 등록하나요?',
      '안녕하세요, 고객님. 문의 주셔서 감사합니다.\n\n'
          '해외 결제 구독은 환율 및 결제 통화에 따라 표시 금액이 달라질 수 있습니다. '
          '외화 결제와 관련된 자세한 사항은 이용 중이신 카드사 또는 금융기관에 '
          '문의해 주시기 바랍니다. 이용에 참고하시어 도움이 되시길 바랍니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('도움말',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const Text('자주 묻는 질문',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('궁금한 항목을 눌러 답변을 확인하세요.',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          ..._faqs.map((f) => _FaqTile(faq: f)),
        ],
      ),
      // 오른쪽 아래 챗봇 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: purple,
        onPressed: () => _openChat(context),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HelpChatSheet(),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});
  final _Faq faq;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8FF)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: HelpScreen.purple,
          collapsedIconColor: Colors.black45,
          leading: const Icon(Icons.help_outline, color: HelpScreen.purple),
          title: Text(
            faq.question,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          children: [
            Text(
              faq.answer,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= 챗봇 시트 ================= */

class _HelpChatSheet extends StatefulWidget {
  const _HelpChatSheet();

  @override
  State<_HelpChatSheet> createState() => _HelpChatSheetState();
}

class _ChatMsg {
  final String text;
  final bool fromUser;
  _ChatMsg(this.text, this.fromUser);
}

class _HelpChatSheetState extends State<_HelpChatSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // 무엇을 물어도 돌아오는, 도움이 되지 않는 답변들
  static const List<String> _uselessReplies = [
    '저는 단지 언어 모델일 뿐이고, 그것을 처리하고 이해하는 능력이 없기 때문에 도와드릴 수가 없습니다.',
    '언어 모델로서, 저는 그것을 도와드릴 수가 없습니다.',
    '죄송하지만 무슨 말씀인지 이해하지 못했어요.',
    '이해하지 못했습니다. 다시 말씀해 주시겠어요?',
    '죄송하지만 저는 그 요청을 이해할 수 없습니다.',
  ];

  int _replyIndex = 0;

  final List<_ChatMsg> _messages = [
    _ChatMsg('안녕하세요! 무엇을 도와드릴까요?', false),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(text, true));
      // 어떤 입력이든 도움이 안 되는 답만 순환하며 응답
      _messages.add(_ChatMsg(_uselessReplies[_replyIndex], false));
      _replyIndex = (_replyIndex + 1) % _uselessReplies.length;
      _ctrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom; // 키보드 높이
    // 상단 상태바(알림창) 아래로만 시트가 차지하도록 최대 높이 제한
    final maxSheet =
        media.size.height - media.padding.top - bottomInset - 12;
    final sheetHeight =
        (media.size.height * 0.7).clamp(0.0, maxSheet < 0 ? 0.0 : maxSheet);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE8E8FF), width: 1)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFEDEBFF),
                    child: Icon(Icons.smart_toy_outlined,
                        size: 18, color: HelpScreen.purple),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('도움말 챗봇',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black45),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 메시지 목록
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _bubble(_messages[i]),
              ),
            ),
            // 입력창 (하단 홈 인디케이터/제스처 영역에 가려지지 않도록 SafeArea 적용)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0xFFE8E8FF), width: 1)),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 12),
                child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: HelpScreen.purple,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: _send,
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFEDEBFF) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          m.text,
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
        ),
      ),
    );
  }
}

/* ================= 재사용 위젯 ================= */

// 도움말 페이지로 이동
void openHelp(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HelpScreen()),
  );
}


/// 화면 본문 위에 오른쪽 아래 "도움말" 플로팅 버튼을 띄우는 오버레이.
/// 하단 네비게이션 바와 겹치지 않도록 본문 영역 안에 떠 있음.
/// FAB가 이미 있는 화면은 [bottomOffset]을 키워 겹치지 않게 한다.
class HelpOverlay extends StatelessWidget {
  const HelpOverlay({super.key, required this.child, this.bottomOffset = 16});
  final Widget child;
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: 16,
          bottom: bottomOffset,
          child: SafeArea(
            top: false,
            child: Material(
              color: HelpScreen.purple,
              elevation: 4,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => openHelp(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headset_mic_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('도움말',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
