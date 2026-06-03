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
  bool fromNotification = false,
}) {
  if (fromNotification) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushTrainingRiddle(mapId, riddleId, fromNotification: true);
    });
  } else {
    _pushTrainingRiddle(mapId, riddleId, fromNotification: false);
  }
}

Future<void> _pushTrainingRiddle(
  String mapId,
  int riddleId, {
  required bool fromNotification,
}) async {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  try {
    final db = DriftService.instance.db;

    final riddle = await (db.select(db.riddles)
          ..where((r) => r.id.equals(riddleId)))
        .getSingle();
    final allRiddles = await (db.select(db.riddles)
          ..where((r) => r.mapId.equals(mapId)))
        .get();
    final int targetIndex = allRiddles.indexWhere((r) => r.id == riddleId);

    // ── Mark as notified the moment the user opens the riddle ─────────────
    // Covers both notification taps and dashboard taps on failed riddles.
    // insertNotifiedRiddle is idempotent (insertOnConflictUpdate) so calling
    // it again on a re-attempt is safe.
    final session = await TrainingService.instance.getActiveSession(mapId);
    if (session != null) {
      await DriftService.instance.insertNotifiedRiddle(
        sessionId: session.id,
        mapId: mapId,
        riddleId: riddleId,
      );
    }

    if (!context.mounted) return;

    void onDone(BuildContext riddleContext, int errorCount) {
      TrainingService.instance.onRiddleAnswered(
        mapId: mapId,
        riddleId: riddleId,
        correct: errorCount == 0,
        riddles: allRiddles,
      );
      if (fromNotification) {
        Navigator.pushReplacement(
          riddleContext,
          MaterialPageRoute(builder: (_) => const TrainingDashboardScreen()),
        );
      } else {
        Navigator.pop(riddleContext);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (riddleContext) => Scaffold(
          body: SafeArea(
            child: RiddleScreen(
              riddle: riddle,
              riddleIndex: targetIndex >= 0 ? targetIndex : 0,
              trainingMode: true,
              readOnly: false,
              onDismiss: () => Navigator.pop(riddleContext),
              onSkip: () => onDone(riddleContext, 1),
              onComplete: (int errorCount) => onDone(riddleContext, errorCount),
            ),
          ),
        ),
      ),
    );
  } catch (e) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Training Route Sync Failed'),
        content: Text('Could not fetch riddle details.\nDetails: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
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
    openTrainingRiddle(mapId, riddleId, fromNotification: true);
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
