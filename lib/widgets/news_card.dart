import 'package:flutter/material.dart';

import '../models/matched_article.dart';
import '../theme.dart';
import '../utils/date_format.dart';

/// 뉴스 목록의 뉴스 카드 (매칭 뉴스·최신 뉴스 공용).
/// 맨 위에 원본 출처(언론사)와 발행 일시를 표시한다 (플레이 뉴스 정책 요건).
/// 기사 제목 17sp SemiBold (줄 간격 1.4), 매칭 키워드는 제목 안에서 노란 배경으로 강조,
/// 키워드 태그는 작은 캡슐(높이 30dp). 최신 뉴스는 키워드 태그가 없다.
/// 새 뉴스는 출처 줄 오른쪽 배지.
class NewsCard extends StatelessWidget {
  final MatchedArticle article;
  final bool isRead;
  final VoidCallback onTap;

  const NewsCard({
    super.key,
    required this.article,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 새 뉴스 배지는 카드 오른쪽 상단에 따로 둔다.
              if (!isRead) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_NewBadge(brightness: brightness)],
                ),
                const SizedBox(height: 4),
              ],
              // 원본 출처 + 발행 일시. 좁은 화면에서는 줄을 바꾼다.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(article.source, style: AppTextStyles.source(brightness)),
                  Text(
                    formatPublished(article.pubDate),
                    style: AppTextStyles.meta(brightness),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: _highlightSpans(
                    article.title,
                    article.keywords,
                    brightness,
                  ),
                ),
              ),
              if (article.keywords.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: article.keywords
                      .map(
                        (keyword) => _KeywordTag(
                          keyword: keyword,
                          brightness: brightness,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 제목 안에서 매칭된 키워드 부분을 노란 배경으로 강조한다.
  /// 대소문자를 무시하고 모든 등장 위치를 찾는다.
  List<TextSpan> _highlightSpans(
    String text,
    List<String> keywords,
    Brightness brightness,
  ) {
    final baseStyle = AppTextStyles.cardTitle(brightness).copyWith(height: 1.4);
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: AppColors.highlight(brightness),
    );
    final lower = text.toLowerCase();
    final ranges = <_TextRange>[];
    for (final keyword in keywords) {
      final kw = keyword.toLowerCase();
      if (kw.isEmpty) continue;
      var index = lower.indexOf(kw);
      while (index != -1) {
        ranges.add(_TextRange(index, index + kw.length));
        index = lower.indexOf(kw, index + kw.length);
      }
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_TextRange>[];
    for (final range in ranges) {
      if (merged.isEmpty || range.start > merged.last.end) {
        merged.add(range);
      } else if (range.end > merged.last.end) {
        merged.last.end = range.end;
      }
    }
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in merged) {
      if (range.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, range.start), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: highlightStyle,
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    return spans;
  }
}

class _TextRange {
  int start;
  int end;

  _TextRange(this.start, this.end);
}

class _NewBadge extends StatelessWidget {
  final Brightness brightness;

  const _NewBadge({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.success(brightness),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('새 뉴스', style: AppTextStyles.newBadge(brightness)),
      ],
    );
  }
}

class _KeywordTag extends StatelessWidget {
  final String keyword;
  final Brightness brightness;

  const _KeywordTag({required this.keyword, required this.brightness});

  @override
  Widget build(BuildContext context) {
    // alignment를 주면 Container가 줄 전체 폭으로 늘어나서 태그가 길게 보였다.
    return Container(
      height: AppSizes.keywordTagHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.tagBackground(brightness),
        borderRadius: BorderRadius.circular(AppSizes.keywordTagHeight / 2),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(keyword, style: AppTextStyles.tag(brightness)),
      ),
    );
  }
}
