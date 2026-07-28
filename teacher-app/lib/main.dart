import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/offline_cache.dart';
import 'core/router.dart';
import 'core/socket_service.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await SharedPreferences.getInstance();

  // Initialize Hive offline cache
  await OfflineCache.init();

  // Initialize Socket.IO for real-time messaging (starts in background)
  SocketService.instance.init();

  runApp(
    const ProviderScope(
      child: TeacherDiwanApp(),
    ),
  );
}

class TeacherDiwanApp extends ConsumerWidget {
  const TeacherDiwanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Student Diwan – Teacher',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
