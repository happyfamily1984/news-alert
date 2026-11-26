import '../models/matched_article.dart';
import '../utils/keyword_match.dart';
import 'notification_service.dart';
import 'rss_service.dart';
import 'storage_service.dart';

/// 한 번 확인한 결과.
class CheckResult {
  /// 이번에 새로 매칭된 기사.
  final List<MatchedArticle> newArticles;

  /// 시도한 피드 수와 성공한 피드 수.
  final int feedsTried;
  final int feedsOk;

  const CheckResult({
    required this.newArticles,
    required this.feedsTried,
    required this.feedsOk,
  });

  /// 피드를 하나도 못 받았다 (네트워크 끊김 등).
  bool get allFailed => feedsTried > 0 && feedsOk == 0;
}

/// RSS 수집 → 최신 뉴스 저장 → 키워드 매칭 → 저장 → 알림.
/// UI 수동 확인과 WorkManager 백그라운드 작업이 같은 로직을 쓴다.
class NewsCheckService {
  NewsCheckService._();

  static final NewsCheckService instance = NewsCheckService._();

  /// 언론사마다 최대 [perSource]건씩 골라 최신순으로 합친다.
  /// 그냥 최신순으로 자르면 기사를 자주 올리는 언론사(연합·조선)만 남아서
  /// 다른 언론사 기사가 최신 뉴스에 안 보인다.
  static List<MatchedArticle> pickLatest(
    Iterable<MatchedArticle> articles, {
    int perSource = 10,
  }) {
    final bySource = <String, List<MatchedArticle>>{};
    for (final a in articles) {
      bySource.putIfAbsent(a.source, () => []).add(a);
    }
    final picked = <MatchedArticle>[];
    for (final list in bySource.values) {
      list.sort((a, b) => b.pubDate.compareTo(a.pubDate));
      picked.addAll(list.take(perSource));
    }
    picked.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return picked;
  }

  Future<CheckResult> runCheck({required bool notify}) async {
    final storage = StorageService.instance;
    final keywords = await storage.getKeywords();
    final now = DateTime.now();
    final enabledSources = await storage.getEnabledSources();

    // 켜진 출처의 피드를 한꺼번에 받는다. 실패한 피드는 건너뛰고 수만 센다.
    // 키워드가 없어도 받는다: '최신 뉴스'는 키워드와 상관없이 보여준다.
    final activeFeeds = RssService.feeds
        .where((feed) => enabledSources.contains(feed.name))
        .toList();
    var feedsOk = 0;
    final results = await Future.wait(
      activeFeeds.map((feed) async {
        try {
          final items = await RssService().fetchFeed(feed);
          feedsOk++;
          return items;
        } catch (_) {
          return <RssArticle>[];
        }
      }),
    );
    final result = CheckResult(
      newArticles: <MatchedArticle>[],
      feedsTried: activeFeeds.length,
      feedsOk: feedsOk,
    );
    await storage.setLastFetchFailed(result.allFailed);
    if (result.allFailed) {
      // 전부 실패면 저장된 목록을 건드리지 않는다 (빈 목록으로 덮어쓰지 않게).
      return result;
    }
    await storage.setLastCheckAt(now);

    // guid 기준으로 합친다. 최신 뉴스는 전체, 매칭 뉴스는 키워드가 맞는 것만.
    final Map<String, MatchedArticle> all = {};
    final Map<String, MatchedArticle> matched = {};
    for (var i = 0; i < activeFeeds.length; i++) {
      final source = activeFeeds[i].name;
      for (final item in results[i]) {
        // 발행일이 미래로 잘못 들어온 기사는 지금 시각으로 맞춘다.
        final pubDate = item.pubDate.isAfter(now) ? now : item.pubDate;
        final article = MatchedArticle(
          id: item.guid,
          title: item.title,
          link: item.link,
          pubDate: pubDate,
          description: item.description,
          keywords: const [],
          fetchedAt: now,
          source: source,
        );
        all.putIfAbsent(item.guid, () => article);

        final hits = keywords
            .where(
              (keyword) =>
                  containsKeyword(item.title, keyword) ||
                  containsKeyword(item.description, keyword),
            )
            .toList();
        if (hits.isEmpty) continue;
        final previous = matched[item.guid];
        matched[item.guid] = (previous ?? article).copyWith(
          keywords: {...?previous?.keywords, ...hits}.toList(),
        );
      }
    }

    await storage.saveLatestArticles(pickLatest(all.values));

    final freshList = matched.values.toList()
      ..sort((a, b) => b.pubDate.compareTo(a.pubDate));

    // 피드를 받는 동안 다른 쪽(백그라운드 작업 ↔ 앱 화면)이 저장했을 수
    // 있으니 저장 직전에 목록을 다시 읽어 합친다.
    final existing = await storage.getArticles();
    final existingIds = existing.map((a) => a.id).toSet();
    final newOnes = freshList
        .where((a) => !existingIds.contains(a.id))
        .toList();
    // 이미 저장된 기사가 피드에 다시 나오면 발행일을 피드 값으로 고친다
    // (1.0.0+16까지는 연합뉴스·조선일보 발행일을 못 읽고 가져온 시각으로 저장했다).
    final corrected = existing.map((a) {
      final fresh = all[a.id];
      return fresh == null ? a : a.copyWith(pubDate: fresh.pubDate);
    });
    // 새 기사 먼저, 기존 기사 뒤에 두고 최대 100건 유지.
    final merged = <MatchedArticle>[...newOnes, ...corrected];
    final seenIds = <String>{};
    final deduped = merged.where((a) => seenIds.add(a.id)).toList()
      ..sort((a, b) => b.pubDate.compareTo(a.pubDate));
    await storage.saveArticles(deduped);

    if (notify) {
      final enabled = await storage.getNotificationsEnabled();
      if (enabled) {
        final newOnly = await storage.getNotifyNewOnly();
        // 하루 넘게 지난 기사는 목록에는 넣되 알림은 보내지 않는다.
        final cutoff = now.subtract(const Duration(hours: 24));
        final targets = (newOnly ? newOnes : freshList)
            .where((a) => a.pubDate.isAfter(cutoff))
            .toList();
        final limited = targets.length > 5 ? targets.sublist(0, 5) : targets;
        for (final article in limited) {
          await NotificationService.instance.showNewsNotification(
            id: article.id.hashCode & 0x7fffffff,
            title: '새 뉴스 · ${article.keywords.join(', ')}',
            body: '[${article.source}] ${article.title}',
            payload: article.link,
          );
        }
      }
    }

    return CheckResult(
      newArticles: newOnes,
      feedsTried: result.feedsTried,
      feedsOk: result.feedsOk,
    );
  }
}
