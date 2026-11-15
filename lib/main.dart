import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'background_task.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController();
  await settings.load();

  await NotificationService.instance.ensureInitialized();
  await NotificationService.instance.requestPermission();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await registerPeriodicCheck();

  runApp(NewsAlarmApp(settings: settings));
}

class NewsAlarmApp extends StatelessWidget {
  final SettingsController settings;

  const NewsAlarmApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: '뉴스 알리미',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settings.themeMode,
          home: MainScreen(settings: settings),
        );
      },
    );
  }
}
