/*
 * Gemini 2.0 Flash API를 활용한 영수증/결제내역 이미지 분석 서비스
 *
 * [주요 기능]
 * - 영수증 또는 결제내역 이미지에서 구독 정보를 자동으로 추출
 * - Gemini 2.0 Flash 멀티모달 API를 사용하여 이미지 분석
 * - 추출된 정보를 OCRResult 객체로 변환하여 반환
 *
 * [추출 정보]
 * - serviceName: 서비스 브랜드명 (ChatGPT, Netflix 등)
 * - planName: 요금제명 (Plus, Pro, Premium 등)
 * - amount: 결제 금액
 * - currency: 통화 (USD, KRW 등)
 * - paidAt: 결제일
 * - periodText: 구독 기간
 * - category: 서비스 카테고리 (OTT, AI 툴, 음악, 클라우드, 생산성)
 *
 * [사용 흐름]
 * 1. 이미지 파일을 Base64로 인코딩
 * 2. Gemini API에 프롬프트와 이미지 전송
 * 3. JSON 응답 파싱 및 OCRResult 객체 생성
 *
 * [호출 방법]
 * final result = await GeminiOCRService.extract(imageFile);
 * ---------------------------------------------------------------------------
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../model/ocr_result.dart';

class GeminiOCRService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  static Future<String> _encodeImageToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  static Future<OCRResult> extract(File imageFile) async {
    try {
      final base64Image = await _encodeImageToBase64(imageFile);

      final prompt = """
당신은 영수증 및 결제내역에서 구독 정보를 추출하는 전문가입니다.

다음 이미지에서 아래 정보를 JSON 형태로 정확히 추출해주세요:

1. serviceName: 서비스 브랜드명 (예: ChatGPT, Netflix, YouTube, Spotify, Claude)
   - 요금제명(Plus, Pro, Premium, Basic)은 제외하고 순수 서비스명만 추출
   
2. planName: 요금제/플랜명 (예: Plus, Pro, Premium, Basic, Standard)

3. amount: 총 결제 금액 (숫자만)

4. currency: 통화 기호 (USD, KRW, \$ 등)

5. paidAt: 결제일 (YYYY-MM-DD 형식)

6. periodText: 구독 기간 (예: "Dec 3, 2025 - Jan 3, 2026")

7. category: 서비스 카테고리 (다음 중 하나만 선택)
   - "OTT": Netflix, Disney+, Watcha, Wavve, YouTube Premium 등 영상 스트리밍
   - "AI 툴": ChatGPT, Claude, Midjourney, Copilot, Notion AI 등 AI 서비스
   - "음악": Spotify, Apple Music, YouTube Music, Melon, Genie 등
   - "클라우드": Google One, iCloud, Dropbox, OneDrive 등 저장소
   - "생산성": Notion, Slack, Figma, Adobe, Microsoft 365 등

출력은 반드시 JSON 객체 한 개만 포함해야 합니다.
""";
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.1
          }
        }),
      );

      if (response.statusCode != 200) {
        print("!!!!!!! OCR API Error: ${response.body}");
        throw Exception("Gemini OCR API 호출 실패");
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      final parts = body["candidates"][0]["content"]["parts"];

      String? textOutput;

      for (final p in parts) {
        if (p["text"] != null && p["text"].toString().contains("{")) {
          textOutput = p["text"];
          break;
        }
      }

      if (textOutput == null) {
        throw Exception("OCR 결과에서 JSON 텍스트를 찾지 못했습니다.");
      }

      print("!!!!!!! OCR 응답 원문:");
      print(textOutput);

      // 마크다운 코드 블록 제거
      String cleanedText = textOutput
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // JSON 파싱
      final jsonResult = jsonDecode(cleanedText);

      // 배열이면 첫 번째 요소 사용, 객체면 그대로 사용
      final Map<String, dynamic> resultMap;
      if (jsonResult is List) {
        resultMap = jsonResult.first as Map<String, dynamic>;
      } else {
        resultMap = jsonResult as Map<String, dynamic>;
      }

      return OCRResult.fromJson(resultMap);
    } catch (e) {
      print("!!!!!!! Gemini OCR Error: $e");
      rethrow;
    }
  }
}
