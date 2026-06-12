import 'package:flutter/material.dart';

/// 아직 구현되지 않은 메뉴를 위한 "준비 중" 빈 페이지.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, this.title = ''});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: const Center(
        child: Text(
          '준비 중',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }
}
