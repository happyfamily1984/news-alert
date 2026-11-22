import 'package:flutter/material.dart';

import '../background_task.dart';
import 'rss_service.dart';
import 'storage_service.dart';

/// 설정 상태. SharedPreferences에 저장하고 ChangeNotifier로 화면에 알린다.
class SettingsController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool notificationsEnabled = true;
  int checkIntervalMinutes = 15;
  bool notifyNewOnly = true;
  Set<String> enabledSources = RssService.sourceNames;

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
    enabledSources = await storage.getEnabledSources();
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

  /// 출처 하나를 켜고 끈다. 전부 끄면 뉴스를 못 가져오니
  /// 마지막으로 남은 하나는 끌 수 없게 막는다.
  Future<void> setSourceEnabled(String source, bool enabled) async {
    final next = Set<String>.from(enabledSources);
    if (enabled) {
      next.add(source);
    } else {
      if (next.length <= 1) return;
      next.remove(source);
    }
    enabledSources = next;
    await StorageService.instance.setEnabledSources(next);
    notifyListeners();
  }
}
