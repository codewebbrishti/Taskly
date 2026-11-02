import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_page.dart';
import 'services/app_settings.dart';
import 'services/notification_service.dart';
import 'services/task_store.dart';
import 'theme/app_colors.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings and tasks before the first screen, so the app opens
  // straight onto the home screen with no extra splash page.
  try {
    await settings.load();
    await store.load();
  } catch (_) {}

  runApp(const TodoApp());

  // Set up reminders after the first frame so start-up stays fast.
  unawaited(_setUpReminders());
}

Future<void> _setUpReminders() async {
  try {
    await notifications.init();
    await store.rescheduleReminders();
  } catch (_) {}
}

ThemeData _buildTheme(Brightness brightness) {
  final pal = brightness == Brightness.dark ? Palette.dark : Palette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: pal.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: brightness,
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the theme setting changes.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value:
                  (dark
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark)
                      .copyWith(statusBarColor: Colors.transparent),
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.2,
                child: child!,
              ),
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
