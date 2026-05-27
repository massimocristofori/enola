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

  await NotificationService.instance.init();
  TrainingService.instance.init();

  // ── Warm-start notification tap handler ───────────────────────────────────
  TrainingService.instance.onTrainingNotificationTap = (mapId, riddleId) async {
    final db = DriftService.instance.db;
    await DriftService.instance.ensureReady();

    final riddles = await db.getRiddlesForMap(mapId);
    final index = riddles.indexWhere((r) => r.id == riddleId);
    if (index == -1) return;
    final riddle = riddles[index];

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Push riddle on top of whatever is currently showing
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF1F4F8),
          body: SafeArea(
            child: RiddleScreen(
              riddle: riddle,
              riddleIndex: index,
              trainingMode: true,
              onDismiss: () => Navigator.of(context).pop(),
              onComplete: (errorCount) async {
                await TrainingService.instance.onRiddleAnswered(
                  mapId: mapId,
                  riddleId: riddleId,
                  correct: errorCount == 0,
                  riddles: riddles,
                );
                Navigator.of(context).pop();
              },
              onSkip: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  };

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
