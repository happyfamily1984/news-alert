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

/// 뉴스 출처 하나: 언론사 이름 + RSS 주소.
/// [titleSuffix]는 구글 뉴스 RSS 제목 끝에 붙는 ' - YTN' 같은
/// 언론사 꼬리말이다. 있으면 제목에서 떼낸다.
class FeedSource {
  final String name;
  final String url;
  final String? titleSuffix;

  /// 구글 뉴스 RSS 경유 피드인지 여부.
  bool get viaGoogleNews => titleSuffix != null;

  const FeedSource(this.name, this.url, [this.titleSuffix]);
}

/// 뉴스 RSS 수집. API 키가 필요 없다.
///
/// 연합뉴스는 직접 피드(2026-11-15 기준 200 응답).
/// YTN·MBC·KBS는 직접 피드가 막혀 있어 구글 뉴스 RSS(언론사별 site: 검색)로
/// 가져온다. 직접 피드는 2026-11-15에 확인했더니 MBC·KBS는 404 오류 페이지,
/// YTN은 홈페이지로 리디렉션이라 쓸 수 없었다. 구글 뉴스 RSS는 3곳 모두
/// RSS 2.0 정상 확인됨.
/// 구글 뉴스 검색은 최신순이 아니라서 'when:1d'(최근 하루)를 붙여
/// 며칠 지난 기사가 새 뉴스로 잡히지 않게 한다 (2026-11-20 응답 확인).
class RssService {
  static const List<FeedSource> feeds = [
    // 연합뉴스 (직접 피드): 전체·정치·경제·사회·국제·문화·스포츠·산업·연예·지역.
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/news.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/politics.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/economy.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/society.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/international.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/culture.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/sports.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/industry.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/entertainment.xml'),
    FeedSource('연합뉴스', 'https://www.yna.co.kr/rss/local.xml'),
    // YTN·MBC·KBS (구글 뉴스 RSS).
    FeedSource(
      'YTN',
      'https://news.google.com/rss/search?q=site:ytn.co.kr+when:1d&hl=ko&gl=KR&ceid=KR:ko',
      ' - YTN',
    ),
    FeedSource(
      'MBC',
      'https://news.google.com/rss/search?q=site:imnews.imbc.com+when:1d&hl=ko&gl=KR&ceid=KR:ko',
      ' - MBC 뉴스',
    ),
    FeedSource(
      'KBS',
      'https://news.google.com/rss/search?q=site:news.kbs.co.kr+when:1d&hl=ko&gl=KR&ceid=KR:ko',
      ' - KBS 뉴스',
    ),
  ];

  Future<List<RssArticle>> fetchFeed(FeedSource feed) async {
    final response = await http
        .get(
          Uri.parse(feed.url),
          headers: {'User-Agent': 'NewsAlarm/1.0 (keyword news alert)'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return <RssArticle>[];

    final document = XmlDocument.parse(response.body);
    final articles = <RssArticle>[];
    for (final item in document.findAllElements('item')) {
      var title = _decodeEntities(
        item.getElement('title')?.innerText.trim() ?? '',
      );
      // 구글 뉴스 RSS 제목 끝의 ' - YTN' 같은 언론사 꼬리말을 떼낸다.
      // 카드 아래에 출처가 따로 표시되니 제목에 두 번 나올 필요가 없다.
      final suffix = feed.titleSuffix;
      if (suffix != null && title.endsWith(suffix)) {
        title = title.substring(0, title.length - suffix.length).trim();
      }
      final link = item.getElement('link')?.innerText.trim() ?? '';
      final guid = item.getElement('guid')?.innerText.trim() ?? link;
      final pubDateRaw = item.getElement('pubDate')?.innerText.trim() ?? '';
      // 구글 뉴스 RSS의 description은 요약이 아니라 '제목 + 언론사' 링크라서
      // 비워 둔다 (상세 화면에서 제목이 두 번 나오지 않게).
      final description = feed.viaGoogleNews
          ? ''
          : _stripTags(
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
