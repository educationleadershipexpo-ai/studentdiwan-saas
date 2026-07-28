import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/fcm_service.dart';
import 'core/offline_cache.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await SharedPreferences.getInstance();

  // Offline cache (Hive)
  await OfflineCache.init();

  // Firebase + FCM
  // NOTE: Requires google-services.json (Android) and GoogleService-Info.plist (iOS)
  // in the respective platform folders. Run: flutterfire configure
  try {
    await Firebase.initializeApp();
    await FcmService.init();
  } catch (_) {
    // Firebase not configured yet — app still runs without push notifications.
    debugPrint('[FCM] Firebase not initialized. Add google-services.json to enable push notifications.');
  }

  runApp(const ProviderScope(child: StudentDiwanApp()));
}

class StudentDiwanApp extends ConsumerWidget {
  const StudentDiwanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Student Diwan – Parent',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
