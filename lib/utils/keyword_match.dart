/// 기사 제목·요약에 키워드가 들어 있는지 본다 (대소문자 무시).
///
/// 한글 키워드는 글자 포함으로 본다 ('전기차'는 '中전기차'에도 맞는다).
/// 영문·숫자로만 된 키워드는 앞뒤가 영문·숫자가 아닐 때만 맞는 것으로 본다.
/// 그냥 포함으로 보면 'AI'가 'KORAIL'·'said'에도 걸리기 때문이다.
/// 'AI칩'처럼 뒤에 한글이 붙은 경우는 맞는 것으로 본다.
bool containsKeyword(String text, String keyword) {
  final kw = keyword.trim().toLowerCase();
  if (kw.isEmpty) return false;
  final lower = text.toLowerCase();
  if (!_asciiOnly.hasMatch(kw)) return lower.contains(kw);
  final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(kw)}(?![a-z0-9])');
  return pattern.hasMatch(lower);
}

final RegExp _asciiOnly = RegExp(r'^[\x20-\x7e]+$');
