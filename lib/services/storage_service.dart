import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/matched_article.dart';

/// 키워드·매칭 기사·설정을 SharedPreferences에 저장한다.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  /// SharedPreferences는 isolate마다 메모리 캐시를 따로 둔다.
  /// 백그라운드 작업(WorkManager)과 앱 화면이 서로 다른 isolate라서,
  /// 매번 reload()로 디스크 값을 다시 읽지 않으면 상대가 저장한 기사를
  /// 못 보고 오래된 목록으로 덮어쓰게 된다.
  Future<SharedPreferences> get _store async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {}
    return prefs;
  }

  static const String _keywordsKey = 'keywords';
  static const String _articlesKey = 'matched_articles';
  static const String _readIdsKey = 'read_article_ids';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _intervalKey = 'check_interval_minutes';
  static const String _newOnlyKey = 'notify_new_only';
  static const String _lastCheckKey = 'last_check_at';
  static const String _themeKey = 'theme_mode';
  static const String _sourcesKey = 'enabled_sources';

  static const int maxStoredArticles = 100;

  /// 켜진 뉴스 출처 목록. 저장된 게 없으면 전부 켠 것으로 본다.
  Future<Set<String>> getEnabledSources() async {
    final prefs = await _store;
    final saved = prefs.getStringList(_sourcesKey);
    if (saved == null) return _allSources;
    return saved.toSet();
  }

  static const Set<String> _allSources = {'연합뉴스', 'YTN', 'MBC', 'KBS'};

  Future<void> setEnabledSources(Set<String> sources) async {
    final prefs = await _store;
    await prefs.setStringList(_sourcesKey, sources.toList());
  }

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

    // 지운 키워드로만 매칭됐던 기사는 목록에서 빼고,
    // 다른 키워드와도 매칭된 기사는 지운 키워드 태그만 뗀다.
    final articles = await getArticles();
    final kept = <MatchedArticle>[];
    for (final article in articles) {
      if (!article.keywords.contains(keyword)) {
        kept.add(article);
        continue;
      }
      final rest = article.keywords.where((k) => k != keyword).toList();
      if (rest.isNotEmpty) kept.add(article.copyWith(keywords: rest));
    }
    await saveArticles(kept);
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
    final capped = articles.length > maxStoredArticles
        ? articles.sublist(0, maxStoredArticles)
        : articles;
    await prefs.setStringList(
      _articlesKey,
      capped.map((a) => jsonEncode(a.toJson())).toList(),
    );

    // 목록에서 사라진 기사의 읽음 표시는 같이 지운다 (끝없이 쌓이지 않게).
    final readIds = prefs.getStringList(_readIdsKey);
    if (readIds != null && readIds.isNotEmpty) {
      final alive = capped.map((a) => a.id).toSet();
      final pruned = readIds.where(alive.contains).toList();
      if (pruned.length != readIds.length) {
        await prefs.setStringList(_readIdsKey, pruned);
      }
    }
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
