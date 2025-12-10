import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recommendations_screen.dart';
import '../screens/add_subscription/add_subscription_start.dart';
import '../screens/add_subscription/add_subscription_ocr.dart';
import '../screens/add_subscription/add_subscription_manual.dart';
import '../screens/add_subscription/add_subscription_confirm.dart';
import '../screens/price_change_report_screen.dart';
import '../screens/report_screen.dart';
import '../model/ocr_result.dart';

class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const subscriptions = '/subscriptions';
  static const profile = '/profile';
  static const recommendations = '/recommendations';
  static const addSubscription = '/add-subscription';
  static const addSubscriptionOCR = '/add-subscription-ocr';
  static const addSubscriptionManual = '/add-subscription-manual';
  static const addSubscriptionConfirm = '/add-subscription-confirm';
  static const priceReport = '/price-report';
  static const report = '/report';
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

      case Routes.recommendations:
        return MaterialPageRoute(builder: (_) => const RecommendationsScreen());

      case Routes.addSubscription:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddSubscriptionStartScreen(),
        );

      case Routes.addSubscriptionOCR:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddSubscriptionOCRScreen(),
        );

      case Routes.addSubscriptionManual:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddSubscriptionManualScreen(),
        );

      case Routes.addSubscriptionConfirm:
        final args = settings.arguments as OCRResult;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AddSubscriptionConfirmScreen(result: args),
        );

      case Routes.priceReport:
        return MaterialPageRoute(
          builder: (_) => const PriceChangeReportScreen(),
        );

      case Routes.report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
