import 'package:flutter_test/flutter_test.dart';
import 'package:news_alarm/utils/keyword_match.dart';

void main() {
  test('한글 키워드는 글자 포함으로 맞춘다', () {
    expect(containsKeyword('‘저가’ 中전기차, 韓 잠식', '전기차'), isTrue);
    expect(containsKeyword('반도체 수출 사상 최대', '반도체'), isTrue);
    expect(containsKeyword('수출 증가', '반도체'), isFalse);
  });

  test('영문 키워드는 다른 단어 속 글자에 걸리지 않는다', () {
    expect(containsKeyword('統合を誇ったKORAIL、3度目の脱線', 'AI'), isFalse);
    expect(containsKeyword('he said yes', 'ai'), isFalse);
    expect(containsKeyword('美, ‘AI 패닉 셀’', 'AI'), isTrue);
    expect(containsKeyword('생체 AI칩 시대', 'ai'), isTrue);
    expect(containsKeyword('엔비디아(NVIDIA) 주가', 'nvidia'), isTrue);
    expect(containsKeyword('Apple Watch', 'apple watch'), isTrue);
  });

  test('빈 키워드는 맞지 않는다', () {
    expect(containsKeyword('아무 제목', '  '), isFalse);
  });
}
