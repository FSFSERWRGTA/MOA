import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBVEKVP6fwVZmsQS1zLC6sYf1Jgc_h0QaY';

  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  static Future<String> _getAllPlansAsString() async {
    final scrapesSnapshot = await FirebaseFirestore.instance.collection('serviceScrapes').get();
    if (scrapesSnapshot.docs.isEmpty) throw Exception("Firestore에 'serviceScrapes' 데이터가 없습니다.");

    final List<String> allPlansText = [];

    String _extractServiceName(Map<String, dynamic> docData, String docId) {
      return docData['providerId']?.toString() ?? docData['providerID']?.toString() ?? docId;
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

      String category = (docData['serviceType'] as String?)?.toLowerCase() ?? 'unknown';
      if (category == 'llm') {
        category = 'ai';
      }

      if (plansArray is! List) continue;

      for (var planData in plansArray) {
        if (planData is! Map<String, dynamic>) continue;

        final planName = _pickFirstNonNull(planData, ['planName', 'name', 'tierName']);
        final amount = _pickFirstNonNull(planData, ['amount', 'price', 'unitAmount']);
        final cycle = _pickFirstNonNull(planData, ['cycle', 'period', 'interval', 'billingCycle']) ?? '';
        final currency = (planData['currency'] as String?)?.toUpperCase() ?? 'KRW';

        if (planName == null || amount == null) continue;

        allPlansText.add(" - 서비스: $serviceName, 카테고리: $category, 요금제: $planName, 가격: $amount, 통화: $currency, 주기: $cycle");
      }
    }
    if (allPlansText.isEmpty) throw Exception("유효한 요금제 정보를 찾을 수 없습니다.");
    return allPlansText.join('\n');
  }

  static Future<Map<String, dynamic>> _callGeminiApi(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return jsonDecode(response.text!) as Map<String, dynamic>;
    } on InvalidApiKey catch (e) {
      print('Gemini SDK Error: API 키가 잘못되었습니다. - $e');
      rethrow;
    } catch (e) {
      print("Gemini SDK 통신 중 오류: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getRecommendations({
    required String selectedMode,
    required String selectedCategory,
    required String userSubscriptionsText,
    required int currentTotalSpending,
  }) async {
    try {
      final plansDataString = await _getAllPlansAsString();
      final prompt = """
      당신은 매우 꼼꼼하고 규칙을 잘 지키는 구독 요금제 추천 전문가입니다.

      [상황]
      사용자는 "$selectedMode"를 원하며, 특히 "$selectedCategory" 카테고리를 아주 중요하게 생각합니다.

      [사용자의 현재 구독 목록 (분석 대상)]
      $userSubscriptionsText

      [참고용 전체 서비스 요금제 목록 (카테고리 및 통화 정보 포함)]
      $plansDataString

      [매우 중요한 작업 지시]
      추천하는 모든 서비스("cheaperPlans", "alternativeServices")는 반드시 "$selectedCategory" 카테고리에 속해야 합니다.
      만약 "$selectedCategory"가 'cloud'라면, 'ai' 카테고리의 서비스(예: Gemini, GPT-4)는 절대 추천해서는 안 됩니다.
      만약 "$selectedCategory"가 'productivity'라면, 'ai' 카테고리의 서비스 또한 절대 추천해서는 안 됩니다.
      이 규칙은 다른 어떤 지시보다 우선합니다.
      
      1. "cheaperPlans"와 "alternativeServices" 추천 시, **카드 내용이 너무 길지 않도록** "summary"는 25자 이내, "features"는 각 15자 이내로 핵심만 간결하게 요약해야 합니다.
      2. **"savingLabel" 필드에는 반드시 "O,OOO원 절약" 또는 "O.OO달러 절약"과 같이, 통화 기호를 포함한 '금액' 형식으로만 응답해야 합니다. 절대로 퍼센티지(%)를 사용하면 안 됩니다.**
      3. 'price' 필드와 절감액 계산 시, **Firestore 데이터의 통화(currency)를 반드시 확인**하고, 원화(KRW)는 '원'으로, 달러(USD)는 '달러'로 정확하게 표시해야 합니다. (예: "₩13,500/월", "\$20/month")
      4. 사용자가 구독하지 않는 카테고리(예: 'ai')를 요청하면, 모든 추천 리스트를 반드시 빈 배열 `[]`로 반환해야 합니다.
      5. 오직 사용자의 관심 카테고리인 "$selectedCategory"와 관련된 서비스만 추천해야 합니다. 절대로 다른 카테고리의 서비스를 추천해서는 안 됩니다.
   

      [JSON 응답 형식]
      - "cheaperPlans", "alternativeServices", "estimatedMonthlySavings" 3개의 키를 포함.
      - 추천 항목이 없으면 반드시 빈 리스트 `[]`를 값으로 반환.
      - "estimatedMonthlySavings"는 절감 가능한 월 예상 금액 (숫자, 원화 기준).
      - 각 추천 객체는 "logoLetter", "serviceName", "price", "savingLabel", "summary", "features" 키를 가집니다.
      - "savingPercent" 키는 이제 사용하지 않으므로, 응답에 포함하지 마세요.

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

  static Future<Map<String, dynamic>> getNewSubscriptionSuggestions({
    required String selectedCategory,
  }) async {
    try {
      final plansDataString = await _getAllPlansAsString();
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
    
      1. **'price' 필드에는 Firestore 데이터의 통화(currency)를 반드시 확인하고, 원화(KRW)는 '원'으로, 달러(USD)는 '달러'로 정확하게 표시해야 합니다. (예: "₩9,900/월", "\$20/month")**
      2. 오직 사용자의 관심 카테고리인 "$selectedCategory"와 관련된 서비스만 추천해야 합니다. 절대로 다른 카테고리의 서비스를 추천해서는 안 됩니다. (예: 'ai'를 요청하면 'Netflix' 추천 금지)
      3. 현재 사용자가 구독하지 않은 구독제를 추천해야 합니다.
      4. 낮은 가격 순으로 구독제를 추천해야합니다.
      5. 3-5개 구독제를 추천해야합니다.

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
