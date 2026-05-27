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
   final context = navigatorKey.currentContext;
   if (context == null) return;
   showDialog(
     context: context,
     builder: (_) => AlertDialog(
       title: const Text('TAP RECEIVED'),
       content: Text('mapId: $mapId\nriddleId: $riddleId\ncontext: OK'),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text('OK'),
         ),
       ],
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
