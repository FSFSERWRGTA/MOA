import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/profile_screen.dart';

class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const subscriptions = '/subscriptions';
  static const profile = '/profile';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.subscriptions:
        return MaterialPageRoute(builder: (_) => const SubscriptionsScreen());
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        // 정의되지 않은 경로 → 로그인으로 보냄
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
