/// 앱 전체에서 현재 로그인된 사용자의 ID를 공유하기 위한 간단한 세션입니다.
class AppSession {
  // 싱글톤 패턴: 앱 전체에서 단 하나의 인스턴스만 존재하도록 보장
  static final AppSession _instance = AppSession._internal();

  factory AppSession() {
    return _instance;
  }

  AppSession._internal();

  /// 로그인 성공 시 여기에 사용자 ID가 저장됩니다.
  String? loggedInUserId;
}
