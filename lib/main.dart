import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOA',
      debugShowCheckedModeBanner: false,

      // 한국어 달력/위젯 로케일
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 기기 언어가 영어여도 앱을 항상 한국어로 고정하고자 하는 경우:
      // locale: const Locale('ko', 'KR'),
      initialRoute: Routes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
