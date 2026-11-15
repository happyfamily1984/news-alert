import '../models/matched_article.dart';
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

    // 피드별로 수집하면서 guid 기준으로 합치고 매칭 키워드를 모은다.
    final Map<String, MatchedArticle> fresh = {};
    for (final (_, url) in RssService.feeds) {
      List<RssArticle> items;
      try {
        items = await RssService().fetchFeed(url);
      } catch (_) {
        continue;
      }
      for (final item in items) {
        final matched =
            keywords.where((keyword) {
              final kw = keyword.toLowerCase();
              return item.title.toLowerCase().contains(kw) ||
                  item.description.toLowerCase().contains(kw);
            }).toList();
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
          );
        }
      }
    }

    final freshList =
        fresh.values.toList()
          ..sort((a, b) => b.pubDate.compareTo(a.pubDate));
    final newOnes =
        freshList.where((a) => !existingIds.contains(a.id)).toList();

    // 새 기사 먼저, 기존 기사 뒤에 두고 최대 100건 유지.
    final merged = <MatchedArticle>[...newOnes, ...existing];
    final seenIds = <String>{};
    final deduped = merged.where((a) => seenIds.add(a.id)).toList();
    await storage.saveArticles(deduped);

    if (notify) {
      final enabled = await storage.getNotificationsEnabled();
      if (enabled) {
        final newOnly = await storage.getNotifyNewOnly();
        final targets = newOnly ? newOnes : freshList;
        final limited =
            targets.length > 5 ? targets.sublist(0, 5) : targets;
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
