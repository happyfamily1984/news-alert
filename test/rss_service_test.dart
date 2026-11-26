import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:news_alarm/services/rss_service.dart';

FeedSource _feed(String name) =>
    RssService.feeds.firstWhere((f) => f.name == name);

void main() {
  test('모든 피드의 출처가 설정 화면 출처 목록에 있다', () {
    for (final feed in RssService.feeds) {
      expect(RssService.sourceNames, contains(feed.name));
    }
    for (final name in RssService.sourceNames) {
      expect(RssService.feeds.any((f) => f.name == name), isTrue, reason: name);
    }
  });

  test('동아일보: guid가 없으면 링크를 쓰고 이미지 태그를 지운다', () {
    final body = File('test/fixtures/donga.xml').readAsStringSync();
    final items = RssService.parse(body, _feed('동아일보'));
    expect(items, hasLength(2));
    final first = items.first;
    expect(first.title, isNotEmpty);
    expect(first.guid, first.link);
    expect(first.link, startsWith('https://www.donga.com/'));
    expect(first.description, isNot(contains('<img')));
    expect(first.description, isNotEmpty);
  });

  test('조선일보: 제목·링크·발행 시간을 읽는다', () {
    final body = File('test/fixtures/chosun.xml').readAsStringSync();
    final items = RssService.parse(body, _feed('조선일보'));
    expect(items, hasLength(2));
    expect(items.first.link, startsWith('https://www.chosun.com/'));
    // 픽스처 첫 기사: Sun, 22 Nov 2026 20:40:00 +0000 (가져온 시각이 아니라 발행 시각)
    expect(items.first.pubDate.toUtc(), DateTime.utc(2026, 11, 22, 20, 40));
  });

  test('구글 뉴스 피드: 제목 끝 언론사 꼬리말을 떼고 요약은 비운다', () {
    const body = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel>
<item><title>반도체 수출 사상 최대 - 중앙일보</title>
<link>https://news.google.com/rss/articles/abc</link>
<guid isPermaLink="false">abc</guid>
<pubDate>Sun, 22 Nov 2026 10:00:00 GMT</pubDate>
<description>&lt;a href="x"&gt;반도체 수출 사상 최대&lt;/a&gt;</description></item>
</channel></rss>''';
    final items = RssService.parse(body, _feed('중앙일보'));
    expect(items.single.title, '반도체 수출 사상 최대');
    expect(items.single.description, isEmpty);
  });
}
