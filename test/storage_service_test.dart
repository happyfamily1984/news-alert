import 'package:flutter_test/flutter_test.dart';
import 'package:news_alarm/models/matched_article.dart';
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
    await storage.saveArticles([_article('a', ['k']), _article('b', ['k'])]);
    await storage.markAsRead('a');
    await storage.markAsRead('b');

    await storage.saveArticles([_article('b', ['k'])]);

    expect(await storage.getReadIds(), {'b'});
  });

  test('기사는 최대 100건까지만 저장된다', () async {
    final storage = StorageService.instance;
    await storage.saveArticles(
      List.generate(130, (i) => _article('id$i', ['k'])),
    );
    expect((await storage.getArticles()).length, 100);
  });
}
