import 'package:cloud_firestore/cloud_firestore.dart';

// 사용자 구독 정보를 담을 간단한 클래스
// 파일 경로: lib/services/user_service.dartimport 'package:cloud_firestore/cloud_firestore.dart';

// 사용자 구독 정보를 담을 간단한 클래스
class UserSubscription {
  final String serviceId;
  final int price;

  UserSubscription({required this.serviceId, required this.price});
}

class UserService {
  // 'duri' 사용자의 정보를 가져오도록 ID를 고정합니다.
  static const String _fixedUserId = 'duri';

  // 사용자의 구독 목록과 총 지출액을 가져오는 함수
  static Future<Map<String, dynamic>> getUserSubscriptions() async {
    try {
      // ✨✨✨ 핵심 수정: 문서의 필드가 아닌 '하위 컬렉션'을 조회합니다. ✨✨✨
      final subCollectionSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_fixedUserId)
          .collection('subscriptions') // <--- '.collection()'으로 변경!
          .get();

      // 하위 컬렉션에 문서가 없는 경우
      if (subCollectionSnapshot.docs.isEmpty) {
        print("사용자('$_fixedUserId')의 'subscriptions' 하위 컬렉션에 문서가 없습니다.");
        return {'subscriptions': <UserSubscription>[], 'totalSpending': 0};
      }

      final List<UserSubscription> subscriptions = [];
      int totalSpending = 0;

      // 하위 컬렉션의 각 '문서'를 순회합니다.
      for (var subDoc in subCollectionSnapshot.docs) {
        final data = subDoc.data();

        // ✨✨✨ 실제 필드 이름으로 데이터를 추출합니다. ✨✨✨
        // 스크린샷에 나온 필드: providerId, amount
        if (data.containsKey('providerId') && data.containsKey('amount')) {
          subscriptions.add(UserSubscription(
            serviceId: data['providerId'], // 'serviceId' 대신 'providerId'
            price: (data['amount'] as num).toInt(), // 'price' 대신 'amount'
          ));
          totalSpending += (data['amount'] as num).toInt();
        }
      }

      return {'subscriptions': subscriptions, 'totalSpending': totalSpending};

    } catch (e) {
      print("사용자 구독 정보 조회 실패: $e");
      return {'subscriptions': <UserSubscription>[], 'totalSpending': 0};
    }
  }
}
