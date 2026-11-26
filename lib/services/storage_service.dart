import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/matched_article.dart';
import 'rss_service.dart';

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
  static const String _bgRunAtKey = 'bg_last_run_at';
  static const String _bgResultKey = 'bg_last_result';
  static const String _batteryAskedKey = 'battery_prompt_shown';

  static const int maxStoredArticles = 100;

  /// 매칭·최신 기사 모두 발행 후 30일이 지나면 지운다.
  static const Duration articleRetention = Duration(days: 30);

  static const String _latestKey = 'latest_articles';
  static const String _fetchFailedKey = 'last_fetch_failed';
  static const int maxLatestArticles = 60;

  /// 키워드와 상관없는 전체 최신 기사 (홈 '최신 뉴스', 뉴스 탭 '최신 뉴스').
  Future<List<MatchedArticle>> getLatestArticles() async {
    final prefs = await _store;
    return _decodeArticles(prefs.getStringList(_latestKey));
  }

  Future<void> saveLatestArticles(List<MatchedArticle> articles) async {
    final prefs = await _store;
    final kept = _withinRetention(articles);
    final capped = kept.length > maxLatestArticles
        ? kept.sublist(0, maxLatestArticles)
        : kept;
    await prefs.setStringList(
      _latestKey,
      capped.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  /// 마지막 확인에서 모든 피드를 가져오지 못했는지 (네트워크 오류 안내용).
  Future<bool> getLastFetchFailed() async {
    final prefs = await _store;
    return prefs.getBool(_fetchFailedKey) ?? false;
  }

  Future<void> setLastFetchFailed(bool value) async {
    final prefs = await _store;
    await prefs.setBool(_fetchFailedKey, value);
  }

  static List<MatchedArticle> _withinRetention(List<MatchedArticle> list) {
    final cutoff = DateTime.now().subtract(articleRetention);
    return list.where((a) => a.pubDate.isAfter(cutoff)).toList();
  }

  static List<MatchedArticle> _decodeArticles(List<String>? raw) {
    final articles = <MatchedArticle>[];
    for (final item in raw ?? const <String>[]) {
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

  /// 켜진 뉴스 출처 목록. 저장된 게 없으면 전부 켠 것으로 본다.
  /// 앱 업데이트로 새로 생긴 출처(사용자가 본 적 없는 출처)는 켠 상태로 시작한다.
  Future<Set<String>> getEnabledSources() async {
    final prefs = await _store;
    final all = RssService.sourceNames;
    final saved = prefs.getStringList(_sourcesKey);
    if (saved == null) return all;
    final known =
        prefs.getStringList(_knownSourcesKey)?.toSet() ?? _sourcesBeforeV16;
    final added = all.difference(known);
    final enabled = saved.toSet().intersection(all)..addAll(added);
    if (added.isNotEmpty) {
      await prefs.setStringList(_sourcesKey, enabled.toList());
      await prefs.setStringList(_knownSourcesKey, all.toList());
    }
    return enabled.isEmpty ? all : enabled;
  }

  static const String _knownSourcesKey = 'known_sources';

  /// 출처 목록을 기억하기 전(1.0.0+15까지) 버전에 있던 출처.
  static const Set<String> _sourcesBeforeV16 = {'연합뉴스', 'YTN', 'MBC', 'KBS'};

  Future<void> setEnabledSources(Set<String> sources) async {
    final prefs = await _store;
    await prefs.setStringList(_sourcesKey, sources.toList());
    await prefs.setStringList(
      _knownSourcesKey,
      RssService.sourceNames.toList(),
    );
  }

  /// 처음 설치했을 때 미리 등록해 두는 추천 키워드.
  /// 키워드가 하나도 없으면 첫 화면이 비어 '작동하지 않는 앱'처럼 보이므로
  /// (플레이 심사 거부 사유), 바로 기사가 보이도록 넣어 둔다. 사용자가 지울 수 있다.
  static const List<String> defaultKeywords = ['경제', '부동산', 'AI'];

  /// 키워드 목록. 한 번도 저장된 적이 없으면(첫 실행) 추천 키워드를 등록한다.
  /// 사용자가 키워드를 모두 지운 경우(빈 목록이 저장됨)에는 다시 넣지 않는다.
  Future<List<String>> getKeywords() async {
    final prefs = await _store;
    final saved = prefs.getStringList(_keywordsKey);
    if (saved != null) return saved;
    await prefs.setStringList(_keywordsKey, defaultKeywords);
    return List<String>.from(defaultKeywords);
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
    return _decodeArticles(prefs.getStringList(_articlesKey));
  }

  Future<void> saveArticles(List<MatchedArticle> articles) async {
    final prefs = await _store;
    final kept = _withinRetention(articles);
    final capped = kept.length > maxStoredArticles
        ? kept.sublist(0, maxStoredArticles)
        : kept;
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

  /// 백그라운드 자동 확인이 마지막으로 돈 시각과 결과.
  /// 알림이 안 올 때 자동 확인이 실제로 도는지 설정 화면에서 보려고 남긴다.
  Future<(DateTime?, String?)> getBackgroundRun() async {
    final prefs = await _store;
    final raw = prefs.getString(_bgRunAtKey);
    return (
      raw == null ? null : DateTime.tryParse(raw),
      prefs.getString(_bgResultKey),
    );
  }

  Future<void> setBackgroundRun(DateTime at, String result) async {
    final prefs = await _store;
    await prefs.setString(_bgRunAtKey, at.toIso8601String());
    await prefs.setString(_bgResultKey, result);
  }

  /// 배터리 최적화 해제 안내 창을 이미 한 번 보여줬는지.
  Future<bool> getBatteryPromptShown() async {
    final prefs = await _store;
    return prefs.getBool(_batteryAskedKey) ?? false;
  }

  Future<void> setBatteryPromptShown() async {
    final prefs = await _store;
    await prefs.setBool(_batteryAskedKey, true);
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
