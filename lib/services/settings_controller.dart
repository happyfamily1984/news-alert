import 'package:flutter/material.dart';

import '../background_task.dart';
import 'storage_service.dart';

/// 설정 상태. SharedPreferences에 저장하고 ChangeNotifier로 화면에 알린다.
class SettingsController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool notificationsEnabled = true;
  int checkIntervalMinutes = 15;
  bool notifyNewOnly = true;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final storage = StorageService.instance;
    final theme = await storage.getThemeMode();
    themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notificationsEnabled = await storage.getNotificationsEnabled();
    checkIntervalMinutes = await storage.getCheckIntervalMinutes();
    notifyNewOnly = await storage.getNotifyNewOnly();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await StorageService.instance.setThemeMode(value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    await StorageService.instance.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setCheckIntervalMinutes(int value) async {
    checkIntervalMinutes = value;
    await StorageService.instance.setCheckIntervalMinutes(value);
    // 주기가 바뀌면 백그라운드 작업을 다시 등록한다.
    await registerPeriodicCheck();
    notifyListeners();
  }

  Future<void> setNotifyNewOnly(bool value) async {
    notifyNewOnly = value;
    await StorageService.instance.setNotifyNewOnly(value);
    notifyListeners();
  }
}
