import 'package:flutter_test/flutter_test.dart';
import 'package:news_alarm/models/matched_article.dart';
import 'package:news_alarm/services/rss_service.dart';
import 'package:news_alarm/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

MatchedArticle _article(String id, List<String> keywords) {
  final now = DateTime(2026, 11, 20, 12);
  return MatchedArticle(
    id: id,
    title: '제목 $id',
    link: 'https://example.com/$id',
    pubDate: now,
    description: '',
    keywords: keywords,
    fetchedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('키워드를 지우면 그 키워드로만 매칭된 기사도 지워진다', () async {
    final storage = StorageService.instance;
    await storage.addKeyword('부동산');
    await storage.addKeyword('전기차');
    await storage.saveArticles([
      _article('a', ['부동산']),
      _article('b', ['부동산', '전기차']),
      _article('c', ['전기차']),
    ]);

    await storage.removeKeyword('부동산');

    expect(await storage.getKeywords(), ['전기차']);
    final articles = await storage.getArticles();
    expect(articles.map((a) => a.id), ['b', 'c']);
    expect(articles.first.keywords, ['전기차']);
  });

  test('목록에서 사라진 기사의 읽음 표시는 정리된다', () async {
    final storage = StorageService.instance;
    await storage.saveArticles([
      _article('a', ['k']),
      _article('b', ['k']),
    ]);
    await storage.markAsRead('a');
    await storage.markAsRead('b');

    await storage.saveArticles([
      _article('b', ['k']),
    ]);

    expect(await storage.getReadIds(), {'b'});
  });

  test('기사는 최대 100건까지만 저장된다', () async {
    final storage = StorageService.instance;
    await storage.saveArticles(
      List.generate(130, (i) => _article('id$i', ['k'])),
    );
    expect((await storage.getArticles()).length, 100);
  });

  test('업데이트로 새 출처가 생기면 켠 상태로 시작하고, 끈 출처는 유지한다', () async {
    // 1.0.0+15 사용자: YTN을 끈 상태로 저장돼 있었다.
    SharedPreferences.setMockInitialValues({
      'enabled_sources': ['연합뉴스', 'MBC', 'KBS'],
    });
    final storage = StorageService.instance;
    final enabled = await storage.getEnabledSources();
    expect(enabled, contains('조선일보'));
    expect(enabled, contains('중앙일보'));
    expect(enabled, contains('동아일보'));
    expect(enabled, isNot(contains('YTN')));

    // 사용자가 새 출처를 끈 뒤에는 다시 켜지지 않는다.
    await storage.setEnabledSources(enabled..remove('조선일보'));
    expect(await storage.getEnabledSources(), isNot(contains('조선일보')));
  });

  test('처음 설치하면 모든 출처가 켜져 있다', () async {
    expect(
      await StorageService.instance.getEnabledSources(),
      RssService.sourceNames,
    );
  });
}
