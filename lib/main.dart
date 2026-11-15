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
  // 시작 전 초기화는 어느 하나가 실패해도 앱이 뜨도록 각각 감싼다.
  // 하나라도 던지면 runApp()에 못 가고 스플래시에서 멈춘다.
  try {
    await settings.load();
  } catch (_) {}
  try {
    await NotificationService.instance.ensureInitialized();
  } catch (_) {}
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await registerPeriodicCheck();
  } catch (_) {}

  // 알림 권한은 여기서 요청하지 않는다. 첫 화면이 그려지기 전에
  // 권한 창을 띄우면 결과가 안 돌아오고 스플래시에서 멈출 수 있다.
  // MainScreen이 첫 프레임 뒤에 요청한다.
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
