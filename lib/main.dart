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
      // Assuming your payload is stored as a JSON string containing IDs
      final Map<String, dynamic> data = jsonDecode(rawPayload);
      final mapId = data['mapId'] as int;
      final riddleId = data['riddleId'] as int;

      // Pass it to your local training service workflow if required
      if (TrainingService.instance.onTrainingNotificationTap != null) {
        TrainingService.instance.onTrainingNotificationTap!(mapId, riddleId);
      }

      // Execute navigation safely outside the render process cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiddleScreen(mapId: mapId, riddleId: riddleId),
          ),
        );
      });
    } catch (e) {
      // Fallback debug validation if json parsing or parsing types mismatch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context == null) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error Reading Payload'),
            content: Text('Raw: $rawPayload\nException: $e'),
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

  // ── 2. Run initializations with the listener hooked in ────────────────────
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
