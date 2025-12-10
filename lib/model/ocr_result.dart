/*
 * Gemini Vision OCR 분석 결과를 담는 데이터 모델
 *
 * - OCR로부터 추출한 값(서비스명, 금액, 통화, 결제일, 결제 주기 텍스트 등)을 하나의 객체로 구조화하여 전달하기 위한 모델
 * - add_subscription_OCR -> add_subscription_confirm -> Firestore 저장 흐름에서 사용됨
 *
 * [입력/출력]
 * - GeminiOCRService.extract()에서 JSON 기반으로 이 모델 객체를 생성하여 반환
 * - Confirm 화면(add_subscription_confirm.dart)에서는 사용자가 수정한 값을 Firestore 형태에 맞게 가공하여 저장함.
 *
 * [유의사항]
 * - OCR 결과의 필드가 누락될 수 있으므로 nullable 필드도 존재
 * - 결제일(paidAt)은 대부분의 영수증에서 YYYY-MM-DD 형태로 제공되므로 DateTime 사용.
 * - billingCycle(period) 텍스트는 '월간', '연간' 등 자연어 그대로 전달되며, Confirm 화면에서 월/년(day/week 등)으로 매핑 가능.
 * ---------------------------------------------------------------------------
 */

import 'package:flutter/material.dart';

class OCRResult {
  final String rawText; // 전체 OCR 텍스트(디버깅 및 사용자가 직접 확인용)
  final String? serviceName; // 서비스명 (넷플릭스, 유튜브 프리미엄 등)
  final String? planName; // 요금제명 (프리미엄, 베이식 등) — 없을 수도 있음
  final int? amount; // 숫자만 추출한 결제 금액
  final String? currency; // KRW, USD 등 (추출 실패 시 null)
  final DateTime? paidAt; // 결제한 날짜
  final String? periodText; // '월간', '연간', '매월 결제', '1개월 이용권' 등 자연어 텍스트
  final String? category; // 'AI 툴' 등 카페고리

  OCRResult({
    required this.rawText,
    this.serviceName,
    this.planName,
    this.amount,
    this.currency,
    this.paidAt,
    this.periodText,
    this.category,
  });

  // raw JSON -> OCRResult 변환용 팩토리 생성자
  factory OCRResult.fromJson(Map<String, dynamic> json) {
    // // 다버깅 출력
    // print("!!!!!!! fromJson 받은 json: $json");
    // print("!!!!!!! json['category']: ${json['category']}");

    final result = OCRResult(
      rawText: json['rawText'] ?? '',
      serviceName: json['serviceName']?.toString(),
      planName: json['planName']?.toString(),
      amount: _parseAmount(json['amount']),
      currency: json['currency']?.toString() ?? "KRW",
      paidAt: _parseDate(json['paidAt']),
      periodText: json['periodText']?.toString(),
      category: json['category']?.toString(),
    );

    print("!!!!!!! 생성된 result.category: ${result.category}");
    return result;
  }

  // 문자열/숫자/소수점 모두 int로 변환
  static int? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // "22.00" → 22, "14,900" → 14900
      final cleaned = value.replaceAll(',', '').replaceAll(' ', '');
      final parsed = double.tryParse(cleaned);
      return parsed?.toInt();
    }
    return null;
  }

  // 날짜 형식 처리
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      // ISO 형식 시도
      final isoDate = DateTime.tryParse(value);
      if (isoDate != null) return isoDate;

      // "December 7, 2025" 같은 형식 처리
      try {
        return _parseNaturalDate(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // 자연어 날짜 파싱 ("December 7, 2025" → DateTime)
  static DateTime? _parseNaturalDate(String value) {
    final months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };

    final cleaned = value.toLowerCase().replaceAll(',', '');
    final parts = cleaned.split(' ').where((p) => p.isNotEmpty).toList();

    if (parts.length >= 3) {
      final month = months[parts[0]];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      "rawText": rawText,
      "serviceName": serviceName,
      "planName": planName,
      "amount": amount,
      "currency": currency,
      "paidAt": paidAt?.toIso8601String(),
      "periodText": periodText,
    };
  }
}
