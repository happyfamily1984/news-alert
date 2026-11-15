import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/matched_article.dart';

/// 키워드·매칭 기사·설정을 SharedPreferences에 저장한다.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static const String _keywordsKey = 'keywords';
  static const String _articlesKey = 'matched_articles';
  static const String _readIdsKey = 'read_article_ids';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _intervalKey = 'check_interval_minutes';
  static const String _newOnlyKey = 'notify_new_only';
  static const String _lastCheckKey = 'last_check_at';
  static const String _themeKey = 'theme_mode';

  static const int maxStoredArticles = 100;

  Future<List<String>> getKeywords() async {
    final prefs = await _store;
    return prefs.getStringList(_keywordsKey) ?? <String>[];
  }

  Future<void> addKeyword(String keyword) async {
    final prefs = await _store;
    final keywords = prefs.getStringList(_keywordsKey) ?? <String>[];
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    if (keywords.any((k) => k.toLowerCase() == trimmed.toLowerCase())) return;
    keywords.add(trimmed);
    await prefs.setStringList(_keywordsKey, keywords);
  }

  Future<void> removeKeyword(String keyword) async {
    final prefs = await _store;
    final keywords = prefs.getStringList(_keywordsKey) ?? <String>[];
    keywords.remove(keyword);
    await prefs.setStringList(_keywordsKey, keywords);
  }

  Future<List<MatchedArticle>> getArticles() async {
    final prefs = await _store;
    final raw = prefs.getStringList(_articlesKey) ?? <String>[];
    final articles = <MatchedArticle>[];
    for (final item in raw) {
      try {
        articles.add(
          MatchedArticle.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (_) {
        // 손상된 항목은 건너뛴다.
      }
    }
    return articles;
  }

  Future<void> saveArticles(List<MatchedArticle> articles) async {
    final prefs = await _store;
    final capped =
        articles.length > maxStoredArticles
            ? articles.sublist(0, maxStoredArticles)
            : articles;
    await prefs.setStringList(
      _articlesKey,
      capped.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  Future<Set<String>> getReadIds() async {
    final prefs = await _store;
    return (prefs.getStringList(_readIdsKey) ?? <String>[]).toSet();
  }

  Future<void> markAsRead(String id) async {
    final prefs = await _store;
    final ids = (prefs.getStringList(_readIdsKey) ?? <String>[]).toSet();
    if (ids.add(id)) {
      await prefs.setStringList(_readIdsKey, ids.toList());
    }
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _store;
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _store;
    await prefs.setBool(_notificationsKey, value);
  }

  Future<int> getCheckIntervalMinutes() async {
    final prefs = await _store;
    return prefs.getInt(_intervalKey) ?? 15;
  }

  Future<void> setCheckIntervalMinutes(int value) async {
    final prefs = await _store;
    await prefs.setInt(_intervalKey, value);
  }

  Future<bool> getNotifyNewOnly() async {
    final prefs = await _store;
    return prefs.getBool(_newOnlyKey) ?? true;
  }

  Future<void> setNotifyNewOnly(bool value) async {
    final prefs = await _store;
    await prefs.setBool(_newOnlyKey, value);
  }

  Future<DateTime?> getLastCheckAt() async {
    final prefs = await _store;
    final raw = prefs.getString(_lastCheckKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastCheckAt(DateTime value) async {
    final prefs = await _store;
    await prefs.setString(_lastCheckKey, value.toIso8601String());
  }

  /// 'system' | 'light' | 'dark'
  Future<String> getThemeMode() async {
    final prefs = await _store;
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await _store;
    await prefs.setString(_themeKey, value);
  }
}
