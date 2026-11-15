import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// RSS에서 가져온 기사 원본 한 건 (키워드 매칭 전).
class RssArticle {
  final String title;
  final String link;
  final String guid;
  final DateTime pubDate;
  final String description;

  const RssArticle({
    required this.title,
    required this.link,
    required this.guid,
    required this.pubDate,
    required this.description,
  });
}

/// 연합뉴스 RSS 수집. API 키가 필요 없다.
///
/// 확인된 피드 (2026-11-15 기준 200 응답):
/// 전체·정치·경제·사회·국제·문화·스포츠·산업·연예·지역.
class RssService {
  static const List<(String, String)> feeds = [
    ('전체', 'https://www.yna.co.kr/rss/news.xml'),
    ('정치', 'https://www.yna.co.kr/rss/politics.xml'),
    ('경제', 'https://www.yna.co.kr/rss/economy.xml'),
    ('사회', 'https://www.yna.co.kr/rss/society.xml'),
    ('국제', 'https://www.yna.co.kr/rss/international.xml'),
    ('문화', 'https://www.yna.co.kr/rss/culture.xml'),
    ('스포츠', 'https://www.yna.co.kr/rss/sports.xml'),
    ('산업', 'https://www.yna.co.kr/rss/industry.xml'),
    ('연예', 'https://www.yna.co.kr/rss/entertainment.xml'),
    ('지역', 'https://www.yna.co.kr/rss/local.xml'),
  ];

  Future<List<RssArticle>> fetchFeed(String url) async {
    final response = await http
        .get(
          Uri.parse(url),
          headers: {'User-Agent': 'NewsAlarm/1.0 (keyword news alert)'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return <RssArticle>[];

    final document = XmlDocument.parse(response.body);
    final articles = <RssArticle>[];
    for (final item in document.findAllElements('item')) {
      final title = _decodeEntities(
        item.getElement('title')?.innerText.trim() ?? '',
      );
      final link = item.getElement('link')?.innerText.trim() ?? '';
      final guid =
          item.getElement('guid')?.innerText.trim() ?? link;
      final pubDateRaw = item.getElement('pubDate')?.innerText.trim() ?? '';
      final description = _stripTags(
        _decodeEntities(
          item.getElement('description')?.innerText.trim() ?? '',
        ),
      );
      if (title.isEmpty || link.isEmpty) continue;

      DateTime pubDate;
      try {
        pubDate = HttpDate.parse(pubDateRaw).toLocal();
      } catch (_) {
        pubDate = DateTime.now();
      }
      articles.add(
        RssArticle(
          title: title,
          link: link,
          guid: guid,
          pubDate: pubDate,
          description: description,
        ),
      );
    }
    return articles;
  }

  static String _stripTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// CDATA 안에는 HTML 엔티티가 그대로 들어 있으므로 직접 푼다.
  static String _decodeEntities(String input) {
    return input
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }
}
