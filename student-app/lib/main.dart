import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_settings.dart';
import 'core/offline_cache.dart';
import 'core/parent_offline_cache.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/data_provider.dart';
import 'core/server_config.dart';
// Ported-portal offline caches (own Hive boxes; init is idempotent).
import 'portals/parent/core/offline_cache.dart'  as parent_cache;
import 'portals/teacher/core/offline_cache.dart' as teacher_cache;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — icons adjust via AppBar/AnnotatedRegion per screen
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // light icons over gradient headers
    statusBarBrightness: Brightness.dark,
  ));

  final sharedPreferences = await SharedPreferences.getInstance();
  ServerConfig.init(sharedPreferences);

  // Initialize Hive offline caches (student + both ported portals).
  // Hive.initFlutter() is idempotent, so repeated calls are safe.
  await OfflineCache.init();
  await ParentOfflineCache.init();
  await parent_cache.OfflineCache.init();
  await teacher_cache.OfflineCache.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sharedPreferences),
      ],
      child: const StudentDiwanApp(),
    ),
  );
}

class StudentDiwanApp extends ConsumerWidget {
  const StudentDiwanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Student Diwan',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
