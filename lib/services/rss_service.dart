import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../utils/rss_date.dart';

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

class HttpStatusException implements Exception {
  final String url;
  final int statusCode;

  HttpStatusException(this.url, this.statusCode);

  @override
  String toString() => 'HTTP $statusCode';
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
  /// 설정 화면에 보여줄 출처 순서와 설명.
  static const List<(String, String)> sources = [
    ('연합뉴스', '연합뉴스 RSS에서 뉴스를 가져옵니다'),
    ('조선일보', '조선일보 RSS에서 뉴스를 가져옵니다'),
    ('중앙일보', '구글 뉴스를 통해 중앙일보 뉴스를 가져옵니다'),
    ('동아일보', '동아일보 RSS에서 뉴스를 가져옵니다'),
    ('YTN', '구글 뉴스를 통해 YTN 뉴스를 가져옵니다'),
    ('MBC', '구글 뉴스를 통해 MBC 뉴스를 가져옵니다'),
    ('KBS', '구글 뉴스를 통해 KBS 뉴스를 가져옵니다'),
  ];

  static Set<String> get sourceNames => {for (final s in sources) s.$1};

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
    // 조선일보 (직접 피드, 2026-11-22 확인): 전체 피드 하나가 100건,
    // 약 5시간 분량이라 카테고리 피드 없이도 15~60분 주기에 충분하다.
    FeedSource(
      '조선일보',
      'https://www.chosun.com/arc/outboundfeeds/rss/?outputType=xml',
    ),
    // 동아일보 (직접 피드, 2026-11-22 확인): 전체 피드가 50건뿐이라
    // 주요 카테고리를 같이 받는다. 응답에 문자셋 표시가 없어 UTF-8로 직접 푼다.
    FeedSource('동아일보', 'https://rss.donga.com/total.xml'),
    FeedSource('동아일보', 'https://rss.donga.com/politics.xml'),
    FeedSource('동아일보', 'https://rss.donga.com/economy.xml'),
    FeedSource('동아일보', 'https://rss.donga.com/national.xml'),
    FeedSource('동아일보', 'https://rss.donga.com/international.xml'),
    // 중앙일보: 직접 피드가 없어졌다 (2026-11-22, joongang.co.kr/rss 404,
    // rss.joins.com 접속 불가). 구글 뉴스 RSS로 가져온다.
    FeedSource(
      '중앙일보',
      'https://news.google.com/rss/search?q=site:joongang.co.kr+when:1d&hl=ko&gl=KR&ceid=KR:ko',
      ' - 중앙일보',
    ),
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
    // 실패를 빈 목록으로 숨기지 않고 던진다: 호출하는 쪽이 '모든 피드 실패'를
    // 알아야 '네트워크 오류, 다시 시도' 안내를 띄울 수 있다.
    if (response.statusCode != 200) {
      throw HttpStatusException(feed.url, response.statusCode);
    }

    // response.body는 응답 헤더에 문자셋이 없으면 latin1로 풀어서 한글이
    // 깨진다 (동아일보). 국내 피드는 모두 UTF-8이라 바이트를 직접 푼다.
    return parse(utf8.decode(response.bodyBytes, allowMalformed: true), feed);
  }

  /// RSS XML 본문을 기사 목록으로 바꾼다.
  static List<RssArticle> parse(String body, FeedSource feed) {
    final document = XmlDocument.parse(body);
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

      // 발행일을 못 읽으면 가져온 시각으로 둔다 (날짜 없는 기사가 빠지지 않게).
      final pubDate = parseRssDate(pubDateRaw) ?? DateTime.now();
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
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }
}
