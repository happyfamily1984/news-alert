import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:news_alarm/models/matched_article.dart';
import 'package:news_alarm/services/news_check_service.dart';
import 'package:news_alarm/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 실제 네트워크 대신 정해진 응답을 돌려주는 가짜 서버.
/// 연합뉴스 전체 피드에만 기사 1건(1시간 전, +0900 형식 발행일)이 있고,
/// 나머지 피드는 빈 RSS다. [down]이면 모든 요청이 네트워크 오류로 실패한다.
http.Client _fakeServer({bool down = false}) {
  final kst = DateTime.now().toUtc().add(
    const Duration(hours: 8),
  ); // 1시간 전(KST)
  String two(int n) => n.toString().padLeft(2, '0');
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final pubDate =
      '${two(kst.day)} ${months[kst.month - 1]} ${kst.year} '
      '${two(kst.hour)}:${two(kst.minute)}:00 +0900';
  final yna =
      """<?xml version="1.0" encoding="UTF-8"?><rss><channel>
<item><title>AI 반도체 수출 사상 최대</title><link>https://www.yna.co.kr/view/1</link>
<guid>https://www.yna.co.kr/view/1</guid><pubDate>$pubDate</pubDate>
<description>요약</description></item></channel></rss>""";
  return MockClient((request) async {
    if (down) throw const SocketException('offline');
    final body = request.url.toString() == 'https://www.yna.co.kr/rss/news.xml'
        ? yna
        : '<?xml version="1.0"?><rss><channel></channel></rss>';
    return http.Response.bytes(utf8.encode(body), 200);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('키워드가 없어도 최신 뉴스는 저장한다', () async {
    SharedPreferences.setMockInitialValues({'keywords': <String>[]});
    final result = await http.runWithClient(
      () => NewsCheckService.instance.runCheck(notify: false),
      _fakeServer,
    );
    expect(result.allFailed, isFalse);
    final latest = await StorageService.instance.getLatestArticles();
    expect(latest.map((a) => a.source).toSet(), {'연합뉴스'});
    expect(await StorageService.instance.getArticles(), isEmpty);
  });

  test('첫 실행: 추천 키워드로 매칭 뉴스가 바로 채워진다', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await http.runWithClient(
      () => NewsCheckService.instance.runCheck(notify: false),
      _fakeServer,
    );
    expect(result.newArticles.map((a) => a.id), [
      'https://www.yna.co.kr/view/1',
    ]);
    final saved = await StorageService.instance.getArticles();
    expect(saved.single.keywords, ['AI']);
    expect(saved.single.source, '연합뉴스');
    // +0900 발행일을 제대로 읽었다: 가져온 시각이 아니라 약 1시간 전.
    final age = DateTime.now().difference(saved.single.pubDate);
    expect(age.inMinutes, inInclusiveRange(55, 65));
  });

  test('모든 피드가 실패하면 기존 목록을 지우지 않고 실패로 알린다', () async {
    final kept = MatchedArticle(
      id: 'kept',
      title: '이전 기사',
      link: 'https://example.com/kept',
      pubDate: DateTime.now().subtract(const Duration(hours: 2)),
      description: '',
      keywords: const [],
      fetchedAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      'keywords': <String>['AI'],
    });
    await StorageService.instance.saveLatestArticles([kept]);
    final result = await http.runWithClient(
      () => NewsCheckService.instance.runCheck(notify: false),
      () => _fakeServer(down: true),
    );
    expect(result.allFailed, isTrue);
    expect(await StorageService.instance.getLastFetchFailed(), isTrue);
    expect(
      (await StorageService.instance.getLatestArticles()).map((a) => a.id),
      ['kept'],
    );
  });

  test('최신 뉴스는 언론사마다 골고루 담는다', () {
    MatchedArticle a(String id, String source, int minutesAgo) =>
        MatchedArticle(
          id: id,
          title: id,
          link: 'https://example.com/$id',
          pubDate: DateTime.now().subtract(Duration(minutes: minutesAgo)),
          description: '',
          keywords: const [],
          fetchedAt: DateTime.now(),
          source: source,
        );
    final many = [
      for (var i = 0; i < 30; i++) a('y$i', '연합뉴스', i),
      a('k1', 'KBS', 300),
    ];
    final picked = NewsCheckService.pickLatest(many, perSource: 10);
    expect(picked.where((x) => x.source == '연합뉴스'), hasLength(10));
    expect(picked.last.id, 'k1');
  });
}
