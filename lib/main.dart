import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/gemini_service.dart';
import 'services/notification_service.dart';
import 'services/training_service.dart';
import 'theme/enola_theme.dart';
import 'screens/home_screen.dart';
import 'screens/riddle_screen.dart';
import 'screens/training_dashboard_screen.dart';
import 'services/drift_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ── Training navigation ───────────────────────────────────────────────────────

void openTrainingRiddle(
  String mapId,
  int riddleId, {
  bool fromDashboard = false,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final context = navigatorKey.currentContext;

    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openTrainingRiddle(mapId, riddleId, fromDashboard: fromDashboard);
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
                  if (fromDashboard) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingDashboardScreen(),
                      ),
                    );
                  }
                },
                onComplete: (int errorCount) {
                  final bool isCorrect = errorCount == 0;
                  TrainingService.instance.onRiddleAnswered(
                    mapId: mapId,
                    riddleId: riddleId,
                    correct: isCorrect,
                    riddles: allRiddles,
                  );
                  if (isCorrect || fromDashboard) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingDashboardScreen(),
                      ),
                    );
                  }
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
}

// ─────────────────────────────────────────────────────────────────────────────

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

  TrainingService.instance.onTrainingNotificationTap =
      (String mapId, int riddleId) {
    openTrainingRiddle(mapId, riddleId);
  };

  runApp(const ProviderScope(child: EnolaApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.drainPendingLaunchNotification();
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
