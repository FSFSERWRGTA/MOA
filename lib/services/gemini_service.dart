// 파일 경로: lib/services/gemini_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiService {  // 🚨 중요: 여기에 본인의 Gemini API 키를 입력하세요!
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  static Future<Map<String, dynamic>> getRecommendations({
    required String selectedMode,
    // 이번 구조에서는 '카테고리' 필드가 없어서 이 파라미터는 사용되지 않습니다.
    required String selectedCategory,
  }) async {
    try {
      // --- 1. Firestore에서 'serviceScrapes' 컬렉션의 모든 문서를 가져오기 ---
      final scrapesSnapshot = await FirebaseFirestore.instance
          .collection('serviceScrapes')
          .get();

      if (scrapesSnapshot.docs.isEmpty) {
        throw Exception("Firestore에 'serviceScrapes' 데이터가 없습니다.");
      }

      // --- 2. 앱(Dart)에서 데이터를 가공하여 Gemini가 이해하기 좋은 텍스트로 변환 ---
      final List<String> allPlansText = [];

      // 모든 스크랩 문서 (ext_disneyplus_..., ext_netflix_... 등)를 순회
      for (var scrapeDoc in scrapesSnapshot.docs) {
        final docData = scrapeDoc.data();

        // 문서 안에 providerID와 plans 필드가 있는지, plans가 배열인지 확인
        if (docData.containsKey('providerID') && docData.containsKey('plans') && docData['plans'] is List) {
          final serviceName = docData['providerID']; // 'disneyplus', 'netflix'
          final plansArray = docData['plans'] as List;

          // 각 서비스의 'plans' 배열 내부를 순회
          for (var planData in plansArray) {
            // planData가 Map(객체) 형태이고 필요한 키들을 가지고 있는지 확인
            if (planData is Map<String, dynamic> &&
                planData.containsKey('planName') &&
                planData.containsKey('amount') &&
                planData.containsKey('cycle')) {

              final planName = planData['planName'];
              final amount = planData['amount'];
              final cycle = planData['cycle']; // "month" 또는 "year"

              // Gemini에게 전달할 텍스트 형식으로 조합 (훨씬 더 구조화됨)
              allPlansText.add(" - 서비스: $serviceName, 요금제: $planName, 가격: $amount 원, 주기: $cycle");
            }
          }
        }
      }

      if (allPlansText.isEmpty) {
        throw Exception("가져온 데이터에서 유효한 요금제 정보를 찾을 수 없습니다.");
      }

      // 가공된 모든 요금제 정보를 하나의 문자열로 합치기
      final plansDataString = allPlansText.join('\n');

      // --- 3. Gemini API 호출 (프롬프트는 이전과 거의 동일) ---
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      final prompt = """
      당신은 구독 요금제 추천 전문가입니다. 아래 [최신 요금제 목록]을 바탕으로 사용자의 요청에 가장 적합한 추천을 JSON 형식으로 생성해주세요.

      [사용자 정보]
      - 추천 방향: "$selectedMode"
      - 관심 카테고리: "$selectedCategory" (참고용. 목록에 카테고리 정보가 없으므로 서비스 이름으로 유추)

      [최신 요금제 목록]
      $plansDataString

      [JSON 응답 형식 및 규칙]
      - 반드시 아래 3개의 키를 포함해야 합니다: "cheaperPlans", "alternativeServices", "bundleOptions".
      - 추천할 항목이 없으면 빈 리스트 `[]`를 반환합니다.
      - 각 추천 객체는 반드시 "logoLetter", "serviceName", "price", "savingLabel", "savingPercent", "summary", "features", "why" 키를 가져야 합니다.
      - 'price' 필드에는 "₩9,900/월" 과 같이 가격과 주기를 포함해서 응답해야 합니다.

      [요청]
      위 정보를 종합하여 최적의 추천 결과를 JSON 형식으로 생성해줘.
      """;

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        // API 응답의 유효성을 간단히 확인
        final decodedJson = jsonDecode(response.text!) as Map<String, dynamic>;
        if (decodedJson.containsKey('cheaperPlans')) {
          return decodedJson;
        } else {
          throw Exception("Gemini API가 올바른 JSON 형식으로 응답하지 않았습니다.");
        }
      } else {
        throw Exception('Gemini API로부터 응답이 없습니다.');
      }
    } catch (e) {
      print('오류 발생: $e');
      // 오류 발생 시, 앱이 멈추지 않도록 빈 데이터를 반환
      return {
        "cheaperPlans": [],
        "alternativeServices": [],
        "bundleOptions": [],
      };
    }
  }
}

