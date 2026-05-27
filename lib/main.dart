import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'services/gemini_service.dart';
import 'services/notification_service.dart';
import 'services/training_service.dart';
import 'theme/enola_theme.dart';
import 'screens/home_screen.dart';
import 'screens/riddle_screen.dart';
import 'services/drift_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  NotificationService.setPendingBackground(response);
}

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

  // ── 1. Initialize Services ─────────────────────────────────────────────────
  await NotificationService.instance.init(
    onBackground: onBackgroundNotificationResponse,
  );
  TrainingService.instance.init();

  // ── 2. Bind the screen route ───────────────────────────────────────────────
  TrainingService.instance.onTrainingNotificationTap =
      (String mapId, int riddleId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;

      if (context == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TrainingService.instance.onTrainingNotificationTap
              ?.call(mapId, riddleId);
        });
        return;
      }

      try {
        final db = DriftService.instance.db;

        final riddle = await (db.select(db.riddles)
              ..where((r) => r.id.equals(riddleId)))
            .getSingle();
        final allRiddles = await (db.select(db.riddles)
              ..where((r) => r.mapId.equals(mapId)))
            .get();
        final int targetIndex =
            allRiddles.indexWhere((r) => r.id == riddleId);

        if (!context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: SafeArea(
                child: RiddleScreen(
                  riddle: riddle,
                  riddleIndex: targetIndex >= 0 ? targetIndex : 0,
                  trainingMode: true,
                  readOnly: false,
                  onDismiss: () => Navigator.pop(context),
                  onSkip: () {
                    TrainingService.instance.onRiddleAnswered(
                      mapId: mapId,
                      riddleId: riddleId,
                      correct: false,
                      riddles: allRiddles,
                    );
                    Navigator.pop(context);
                  },
                  onComplete: (int errorCount) {
                    final bool isCorrect = errorCount == 0;
                    TrainingService.instance.onRiddleAnswered(
                      mapId: mapId,
                      riddleId: riddleId,
                      correct: isCorrect,
                      riddles: allRiddles,
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Training Route Sync Failed'),
            content: Text(
                'Could not safely fetch riddle details from database.\nDetails: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  };

  // ── 3. Launch app, then drain any pending notification ─────────────────────
  // Two addPostFrameCallback calls ensure HomeScreen is fully mounted and
  // the navigator is attached before we attempt to push a route.
  runApp(const ProviderScope(child: EnolaApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.drainPendingLaunchNotification();
    });
  });
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
