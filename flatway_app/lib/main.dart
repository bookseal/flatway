import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/web_location_capture_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 웹 위치 기록 실험은 학생 팀의 운영 DB와 완전히 분리한다.
  if (!kIsWeb) {
    await SupabaseService.initialize();
  }
  runApp(const FlatWayApp());
}

class FlatWayApp extends StatelessWidget {
  const FlatWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlatWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF047857),
          primary: const Color(0xFF047857),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const WebLocationCaptureScreen() : const SplashScreen(),
    );
  }
}
