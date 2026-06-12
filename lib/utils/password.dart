import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 비밀번호를 SHA-256 해시 문자열로 변환한다.
/// 저장 시와 로그인 검증 시 동일하게 사용해야 한다.
String hashPassword(String raw) =>
    sha256.convert(utf8.encode(raw.trim())).toString();
