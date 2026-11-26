/// RSS 발행일 문자열을 읽는다.
///
/// 언론사마다 형식이 다르다 (2026-11-26 확인):
/// - 연합뉴스: `Thu, 26 Nov 2026 15:13:22 +0900`
/// - 조선일보: `Thu, 26 Nov 2026 00:50:12 +0000`
/// - 구글 뉴스: `Thu, 26 Nov 2026 03:58:00 GMT`
/// dart:io의 HttpDate.parse는 GMT 형식만 읽어서, 예전에는 연합뉴스·조선일보
/// 기사의 발행일을 못 읽고 '가져온 시각'으로 잘못 표시했다.
///
/// 읽지 못하면 null을 돌려준다. 반환값은 현지 시각이다.
DateTime? parseRssDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final m = _rfc822.firstMatch(s);
  if (m != null) {
    final day = int.parse(m.group(1)!);
    final month = _months[m.group(2)!.toLowerCase()];
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    final hour = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    final second = int.parse(m.group(6) ?? '0');
    if (month == null) return null;
    final offset = _offsetMinutes(m.group(7));
    if (offset == null) return null;
    final utc = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
    ).subtract(Duration(minutes: offset));
    return utc.toLocal();
  }
  // ISO 8601 (dc:date 등): 시간대가 없으면 현지 시각으로 본다.
  return DateTime.tryParse(s)?.toLocal();
}

final RegExp _rfc822 = RegExp(
  r'(\d{1,2})\s+([A-Za-z]{3})[A-Za-z]*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[+-]\d{2}:\d{2}|[A-Za-z]{1,4})?',
);

const Map<String, int> _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

/// UTC 기준 시간대 차이(분). 시간대가 없으면 한국 시각(+09:00)으로 본다.
int? _offsetMinutes(String? zone) {
  if (zone == null) return 9 * 60;
  final z = zone.toUpperCase();
  final numeric = RegExp(r'^([+-])(\d{2}):?(\d{2})$').firstMatch(z);
  if (numeric != null) {
    final sign = numeric.group(1) == '-' ? -1 : 1;
    return sign *
        (int.parse(numeric.group(2)!) * 60 + int.parse(numeric.group(3)!));
  }
  const named = {
    'GMT': 0,
    'UT': 0,
    'UTC': 0,
    'Z': 0,
    'KST': 540,
    'EST': -300,
    'EDT': -240,
    'CST': -360,
    'CDT': -300,
    'MST': -420,
    'MDT': -360,
    'PST': -480,
    'PDT': -420,
  };
  return named[z];
}
