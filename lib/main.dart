import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/gemini_service.dart';
import 'services/notification_service.dart';
import 'services/training_service.dart';
import 'services/supabase_service.dart';
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
          MaterialPageRoute(
              builder: (_) => const TrainingDashboardScreen()),
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
              onComplete: (int errorCount) =>
                  onDone(riddleContext, errorCount),
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

  try {
  print('STEP 1: orientation');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  print('STEP 2: overlay style');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  print('STEP 3: gemini key');
  GeminiService.instance.apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  print('STEP 4: env vars check');
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase env vars missing.');
  }

  print('STEP 5: before Supabase.init');
  await SupabaseService.init(url: supabaseUrl, anonKey: supabaseAnonKey);
  print('STEP 6: after Supabase.init, before signIn');

  await SupabaseService.instance.ensureSignedIn();
  print('STEP 7: after signIn');

  await NotificationService.instance.init();
  print('STEP 8: after notification init');

  TrainingService.instance.init();
  print('STEP 9: after training init');

  TrainingService.instance.onTrainingNotificationTap =
      (String mapId, int riddleId) {
    openTrainingRiddle(mapId, riddleId, fromNotification: true);
  };
  print('STEP 10: before runApp');

  runApp(const ProviderScope(child: EnolaApp()));
  print('STEP 11: runApp called');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.drainPendingLaunchNotification();
    });
  });
} catch (e, st) {
  print('STARTUP FAILED: $e\n$st');
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Startup failed:\n$e',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    ),
  ));
}

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
