import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/web_location_capture_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLocationExperiment =
      kIsWeb && Uri.base.queryParameters['mode'] == 'location';

  if (!isLocationExperiment) {
    await SupabaseService.initialize(readOnlyMode: kIsWeb);
  }
  runApp(const FlatWayApp());
}

class FlatWayApp extends StatelessWidget {
  const FlatWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLocationExperiment =
        kIsWeb && Uri.base.queryParameters['mode'] == 'location';

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
      home: isLocationExperiment
          ? const WebLocationCaptureScreen()
          : kIsWeb
          ? const MapScreen(webMode: true, readOnly: true)
          : const SplashScreen(),
    );
  }
}
