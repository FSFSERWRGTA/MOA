import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';      // ← flutterfire configure 실행 후 자동 생성됨
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase 초기화 (가장 중요)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 앱 언어 강제 한국어 설정이 필요하면 아래 주석 해제
      // locale: const Locale('ko', 'KR'),

      initialRoute: Routes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
