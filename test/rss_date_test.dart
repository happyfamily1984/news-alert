import 'package:flutter_test/flutter_test.dart';
import 'package:news_alarm/utils/rss_date.dart';

void main() {
  DateTime utc(String raw) => parseRssDate(raw)!.toUtc();

  test('연합뉴스 형식(+0900)', () {
    expect(
      utc('Thu, 26 Nov 2026 15:13:22 +0900'),
      DateTime.utc(2026, 11, 26, 6, 13, 22),
    );
  });

  test('조선일보 형식(+0000)', () {
    expect(
      utc('Thu, 26 Nov 2026 00:50:12 +0000'),
      DateTime.utc(2026, 11, 26, 0, 50, 12),
    );
  });

  test('구글 뉴스 형식(GMT)', () {
    expect(
      utc('Thu, 26 Nov 2026 03:58:00 GMT'),
      DateTime.utc(2026, 11, 26, 3, 58),
    );
  });

  test('요일 없음·초 없음·KST', () {
    expect(utc('26 Nov 2026 09:00 KST'), DateTime.utc(2026, 11, 26, 0, 0));
  });

  test('ISO 8601', () {
    expect(utc('2026-11-26T15:00:00+09:00'), DateTime.utc(2026, 11, 26, 6, 0));
  });

  test('읽을 수 없으면 null', () {
    expect(parseRssDate(''), isNull);
    expect(parseRssDate('어제'), isNull);
  });
}
