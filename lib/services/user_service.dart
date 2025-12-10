import 'package:cloud_firestore/cloud_firestore.dart';

class UserSubscription {
  final String serviceId;
  final int price;
  final String serviceType;

  UserSubscription({
    required this.serviceId,
    required this.price,
    required this.serviceType,
  });
}

class UserService {
  static const String _fixedUserId = 'duri';

  static Future<Map<String, dynamic>> getUserSubscriptions() async {
    try {
      final userDocFuture = FirebaseFirestore.instance.collection('users').doc(_fixedUserId).get();
      final subCollectionFuture = FirebaseFirestore.instance.collection('users').doc(_fixedUserId).collection('subscriptions').get();

      final responses = await Future.wait([userDocFuture, subCollectionFuture]);

      final userDoc = responses[0] as DocumentSnapshot<Map<String, dynamic>>;
      final subCollectionSnapshot = responses[1] as QuerySnapshot<Map<String, dynamic>>;

      final userData = userDoc.data();

      if (userData == null) {
        return {'userName': '사용자', 'subscriptions': <UserSubscription>[], 'totalSpending': 0};
      }

      final List<UserSubscription> subscriptions = [];
      int totalSpending = 0;

      for (var subDoc in subCollectionSnapshot.docs) {
        final data = subDoc.data();

        if (data.containsKey('providerId') && data.containsKey('amount')) {
          final int price = (data['amount'] as num).toInt();
          totalSpending += price;

          final String serviceType = data['category']?.toString() ?? 'unknown';

          subscriptions.add(UserSubscription(
            serviceId: data['providerId'],
            price: price,
            serviceType: serviceType,
          ));
        }
      }

      return {
        'userName': userData['name'] ?? '사용자',
        'subscriptions': subscriptions,
        'totalSpending': totalSpending,
      };

    } catch (e, s) {
      print("사용자 구독 정보 조회 실패: $e\n$s");
      return {'userName': '사용자', 'subscriptions': <UserSubscription>[], 'totalSpending': 0};
    }
  }
}
