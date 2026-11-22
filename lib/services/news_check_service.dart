import '../models/matched_article.dart';
import '../utils/keyword_match.dart';
import 'notification_service.dart';
import 'rss_service.dart';
import 'storage_service.dart';

/// RSS 수집 → 키워드 매칭 → 저장 → 알림. UI 수동 확인과
/// WorkManager 백그라운드 작업이 같은 로직을 쓴다.
class NewsCheckService {
  NewsCheckService._();

  static final NewsCheckService instance = NewsCheckService._();

  /// 새로 매칭된 기사 목록을 반환한다.
  Future<List<MatchedArticle>> runCheck({required bool notify}) async {
    final storage = StorageService.instance;
    final keywords = await storage.getKeywords();
    final now = DateTime.now();
    await storage.setLastCheckAt(now);
    if (keywords.isEmpty) return <MatchedArticle>[];

    final existing = await storage.getArticles();
    final existingIds = existing.map((a) => a.id).toSet();
    final enabledSources = await storage.getEnabledSources();

    // 피드별로 수집하면서 guid 기준으로 합치고 매칭 키워드를 모은다.
    // 켜진 출처의 피드만 가져온다.
    // 피드는 한꺼번에 받아서 확인 시간을 줄인다. 실패한 피드는 건너뛴다.
    final Map<String, MatchedArticle> fresh = {};
    final activeFeeds = RssService.feeds
        .where((feed) => enabledSources.contains(feed.name))
        .toList();
    final results = await Future.wait(
      activeFeeds.map((feed) async {
        try {
          return await RssService().fetchFeed(feed);
        } catch (_) {
          return <RssArticle>[];
        }
      }),
    );
    for (var i = 0; i < activeFeeds.length; i++) {
      final source = activeFeeds[i].name;
      for (final item in results[i]) {
        final matched = keywords
            .where(
              (keyword) =>
                  containsKeyword(item.title, keyword) ||
                  containsKeyword(item.description, keyword),
            )
            .toList();
        if (matched.isEmpty) continue;

        final previous = fresh[item.guid];
        if (previous != null) {
          fresh[item.guid] = previous.copyWith(
            keywords: {...previous.keywords, ...matched}.toList(),
          );
        } else {
          fresh[item.guid] = MatchedArticle(
            id: item.guid,
            title: item.title,
            link: item.link,
            pubDate: item.pubDate,
            description: item.description,
            keywords: matched,
            fetchedAt: now,
            source: source,
          );
        }
      }
    }

    final freshList = fresh.values.toList()
      ..sort((a, b) => b.pubDate.compareTo(a.pubDate));
    final newOnes = freshList
        .where((a) => !existingIds.contains(a.id))
        .toList();

    // 피드를 받는 동안 다른 쪽(백그라운드 작업 ↔ 앱 화면)이 저장했을 수
    // 있으니 저장 직전에 목록을 다시 읽어 합친다.
    final latest = await storage.getArticles();
    // 새 기사 먼저, 기존 기사 뒤에 두고 최대 100건 유지.
    final merged = <MatchedArticle>[...newOnes, ...latest];
    final seenIds = <String>{};
    final deduped = merged.where((a) => seenIds.add(a.id)).toList();
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
            body: article.title,
            payload: article.link,
          );
        }
      }
    }

    return newOnes;
  }
}
