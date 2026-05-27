import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/gemini_service.dart';
import 'services/notification_service.dart';
import 'services/training_service.dart';
import 'theme/enola_theme.dart';
import 'screens/home_screen.dart';
import 'screens/riddle_screen.dart';
import 'services/drift_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  GeminiService.instance.apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // ── 1. Bind Native Taps to your Training Logic ─────────────────────────────
  NotificationService.instance.onNotificationTap = (String rawPayload) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawPayload);
      
      // Extract properties safely. Supports keys whether encoded as Strings or ints.
      final rawMapId = data['mapId'];
      final String mapIdString = rawMapId?.toString() ?? ''; 
      
      final rawRiddleId = data['riddleId'];
      final int riddleId = rawRiddleId is int 
          ? rawRiddleId 
          : int.tryParse(rawRiddleId?.toString() ?? '') ?? 0;

      // Handoff to your training service workflow to safely look up 
      // the Riddle model in the database and transition the view smoothly.
      if (TrainingService.instance.onTrainingNotificationTap != null) {
        TrainingService.instance.onTrainingNotificationTap!(mapIdString, riddleId);
      }
    } catch (e) {
      // Graceful fallback debug notification to protect production users from hard crashes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context == null) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Notification Payload Alert'),
            content: Text('Raw data incoming: $rawPayload\nDetails: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  };

  // ── 2. Run initializations with listeners securely hooked in ───────────────
  await NotificationService.instance.init();
  TrainingService.instance.init();

  runApp(const ProviderScope(child: EnolaApp()));
}

class EnolaApp extends StatelessWidget {
  const EnolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enola',
      debugShowCheckedModeBanner: false,
      theme: EnolaTheme.theme,
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}
