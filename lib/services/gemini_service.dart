// lib/services/gemini_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiService {
  static const String _apiKey =
      'AIzaSyBVEKVP6fwVZmsQS1zLC6sYf1Jgc_h0QaY'; // ⭐️ 여기에 실제 API 키 입력
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  /// Firestore 'serviceScrapes' 컬렉션의 모든 문서를 읽어와,
  /// Gemini에게 전달할 수 있는 하나의 긴 텍스트(String)로 변환합니다.
  static Future<String> _getAllPlansAsString() async {
    final scrapesSnapshot =
        await FirebaseFirestore.instance.collection('serviceScrapes').get();
    if (scrapesSnapshot.docs.isEmpty)
      throw Exception("Firestore에 'serviceScrapes' 데이터가 없습니다.");

    final List<String> allPlansText = [];

    String _extractServiceName(Map<String, dynamic> docData, String docId) {
      return docData['providerId']?.toString() ??
          docData['providerID']?.toString() ??
          docId;
    }

    String? _pickFirstNonNull(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m[k] != null) return m[k].toString();
      }
      return null;
    }

    for (var scrapeDoc in scrapesSnapshot.docs) {
      final docData = scrapeDoc.data();
      final serviceName = _extractServiceName(docData, scrapeDoc.id);
      final plansArray = docData['plans'];

      String category =
          (docData['serviceType'] as String?)?.toLowerCase() ?? 'unknown';
      if (category == 'llm') {
        category = 'ai';
      }

      if (plansArray is! List) continue;

      for (var planData in plansArray) {
        if (planData is! Map<String, dynamic>) continue;

        final planName =
            _pickFirstNonNull(planData, ['planName', 'name', 'tierName']);
        final amount =
            _pickFirstNonNull(planData, ['amount', 'price', 'unitAmount']);
        final cycle = _pickFirstNonNull(
                planData, ['cycle', 'period', 'interval', 'billingCycle']) ??
            '';

        // ✨ 1. Firestore에서 'currency' 필드를 직접 읽어옵니다.
        final currency =
            (planData['currency'] as String?)?.toUpperCase() ?? 'KRW';

        if (planName == null || amount == null) continue;

        // ✨ 2. Gemini에게 "통화: USD" 또는 "통화: KRW" 정보를 명시적으로 전달합니다.
        allPlansText.add(
            " - 서비스: $serviceName, 요금제: $planName, 가격: $amount, 통화: $currency, 주기: $cycle");
      }
    }
    if (allPlansText.isEmpty) throw Exception("유효한 요금제 정보를 찾을 수 없습니다.");
    return allPlansText.join('\n');
  }

  /// [내부 전용 함수]
  /// 프롬프트(prompt) 문자열을 받아 Gemini API를 직접 호출하고,
  /// 그 결과를 JSON(Map<String, dynamic>) 형태로 변환하여 반환하는 핵심 함수
  static Future<Map<String, dynamic>> _callGeminiApi(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          // JSON 응답을 강제하는 설정
          "generationConfig": {
            "response_mime_type": "application/json",
            "thinkingConfig": {"thinkingBudget": 0}
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            responseBody['candidates'][0]['content']['parts'][0]['text'];
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        print("Gemini API Error Response: ${response.body}");
        throw Exception("Gemini API 호출 실패 (상태 코드: ${response.statusCode})");
      }
    } catch (e) {
      print("Gemini API 통신 중 오류: $e");
      rethrow;
    }
  }

  // -------------------------------------------------------------------
  // ⭐️ 1. "현재 구독을 더 저렴하게" 추천 기능
  // -------------------------------------------------------------------

  /// RecommendationsScreen에서 '현재 구독을 더 저렴하게' 모드일 때 호출되는 함수입니다.
  /// 사용자의 현재 구독 목록과 전체 요금제 목록을 바탕으로
  /// 1) 더 저렴한 요금제, 2) 대체 가능한 다른 서비, 3) 예상 절감액
  static Future<Map<String, dynamic>> getRecommendations({
    required String selectedMode,
    required String selectedCategory,
    required String userSubscriptionsText,
    required int currentTotalSpending,
  }) async {
    try {
      final plansDataString = await _getAllPlansAsString();
      // ✨ 요구사항을 모두 반영하여 프롬프트를 대폭 강화합니다.
      final prompt = """
      당신은 매우 꼼꼼하고 규칙을 잘 지키는 구독 요금제 추천 전문가입니다.

      [상황]
      사용자는 "$selectedMode"를 원하며, 특히 "$selectedCategory" 카테고리를 아주 중요하게 생각합니다.

      [사용자의 현재 구독 목록 (분석 대상)]
      $userSubscriptionsText

      [참고용 전체 서비스 요금제 목록 (통화 정보 포함)]
      $plansDataString

      [매우 중요한 작업 지시]
      추천하는 모든 서비스("cheaperPlans", "alternativeServices")는 반드시 "$selectedCategory" 카테고리에 속해야 합니다.
      만약 "$selectedCategory"가 'cloud'라면, 'ai' 카테고리의 서비스(예: Gemini, GPT-4)는 절대 추천해서는 안 됩니다.
      만약 "$selectedCategory"가 'productivity'라면, 'ai' 카테고리의 서비스 또한 절대 추천해서는 안 됩니다.
      이 규칙은 다른 어떤 지시보다 우선합니다.
      1.  "cheaperPlans"와 "alternativeServices" 추천 시, **카드 내용이 너무 길지 않도록** "summary"는 25자 이내, "features"는 각 15자 이내로 핵심만 간결하게 요약해야 합니다.
      2.  **"savingLabel" 필드에는 반드시 "O,OOO원 절약" 또는 "O.OO달러 절약"과 같이, 통화 기호를 포함한 '금액' 형식으로만 응답해야 합니다. 절대로 퍼센티지(%)를 사용하면 안 됩니다.**
      3.  'price' 필드와 절감액 계산 시, **Firestore 데이터의 통화(currency)를 반드시 확인**하고, 원화(KRW)는 '원'으로, 달러(USD)는 '달러'로 정확하게 표시해야 합니다. (예: "₩13,500/월", "\$20/month")
      4.  사용자가 구독하지 않는 카테고리(예: 'ai')를 요청하면, 모든 추천 리스트를 반드시 빈 배열 `[]`로 반환해야 합니다.
      5.  오직 사용자의 관심 카테고리인 "$selectedCategory"와 관련된 서비스만 추천해야 합니다. 절대로 다른 카테고리의 서비스를 추천해서는 안 됩니다.
   

      [JSON 응답 형식]
      -   "cheaperPlans", "alternativeServices", "estimatedMonthlySavings" 3개의 키를 포함.
      -   추천 항목이 없으면 반드시 빈 리스트 `[]`를 값으로 반환.
      -   "estimatedMonthlySavings"는 절감 가능한 월 예상 금액 (숫자, 원화 기준).
      -   각 추천 객체는 "logoLetter", "serviceName", "price", "savingLabel", "summary", "features" 키를 가집니다.
      -   "savingPercent" 키는 이제 사용하지 않으므로, 응답에 포함하지 마세요.

      [요청]
      위 모든 정보와 지시사항을 철저히 준수하여 최적의 추천 결과를 JSON 형식으로 생성해줘.
      """;
      return await _callGeminiApi(prompt);
    } catch (e) {
      print('getRecommendations 오류: $e');
      return {
        "cheaperPlans": [],
        "alternativeServices": [],
        "estimatedMonthlySavings": 0
      };
    }
  }

  // -------------------------------------------------------------------
  // 2. "새로운 구독 찾기" 추천 기능
  // -------------------------------------------------------------------

  /// RecommendationsScreen에서 '새로운 구독 찾기' 모드일 때 호출되는 함수
  /// 사용자가 선택한 카테고리를 바탕으로, 사용자가 좋아할 만한 새로운 구독 서비스를 추천
  static Future<Map<String, dynamic>> getNewSubscriptionSuggestions({
    required String selectedCategory,
  }) async {
    try {
      final plansDataString = await _getAllPlansAsString();
      // ✨ 프롬프트 강화
      final prompt = """
      당신은 최신 트렌드를 잘 아는 구독 서비스 추천 전문가입니다.

      [사용자 요청]
      - 관심 카테고리: "$selectedCategory"
      - 원하는 작업: 새로운 서비스 추천

      [참고용 전체 서비스 목록]
      $plansDataString

      [매우 중요한 작업 지시]
      추천하는 모든 서비스("cheaperPlans", "alternativeServices")는 반드시 "$selectedCategory" 카테고리에 속해야 합니다.
      만약 "$selectedCategory"가 'cloud'라면, 'ai' 카테고리의 서비스(예: Gemini, GPT-4)는 절대 추천해서는 안 됩니다.
      만약 "$selectedCategory"가 'productivity'라면, 'ai' 카테고리의 서비스 또한 절대 추천해서는 안 됩니다.
      이 규칙은 다른 어떤 지시보다 우선합니다.
    
      1.  **'price' 필드에는 Firestore 데이터의 통화(currency)를 반드시 확인하고, 원화(KRW)는 '원'으로, 달러(USD)는 '달러'로 정확하게 표시해야 합니다. (예: "₩9,900/월", "\$20/month")**
      2.  오직 사용자의 관심 카테고리인 "$selectedCategory"와 관련된 서비스만 추천해야 합니다. 절대로 다른 카테고리의 서비스를 추천해서는 안 됩니다. (예: 'ai'를 요청하면 'Netflix' 추천 금지)
      3.  현재 사용자가 구독하지 않은 구독제를 추천해야 합니다.
      4.  낮은 가격 순으로 구독제를 추천해야합니다.
      5.  3-5개 구독제를 추천해야합니다.

      [JSON 응답 형식]
      - 반드시 "suggestions" 라는 하나의 키를 가진 JSON 객체를 반환해야 합니다.
      - "suggestions"의 값은 추천 서비스 객체들의 리스트(배열)입니다.
      - 추천할 항목이 없으면 빈 리스트 `[]`를 반환합니다.
      - 각 추천 객체는 "logoLetter", "serviceName", "price", "summary", "features", "why" 키를 가져야 합니다.
      - "savingLabel"과 "savingPercent"는 반드시 빈 문자열 "" 로 설정해야 합니다.

      [요청]
      위 모든 정보와 규칙을 준수하여 추천 결과를 JSON 형식으로 생성해줘.
      """;
      return await _callGeminiApi(prompt);
    } catch (e) {
      print('getNewSubscriptionSuggestions 오류: $e');
      return {"suggestions": []};
    }
  }
}
