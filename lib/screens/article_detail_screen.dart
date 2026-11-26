import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/matched_article.dart';
import '../theme.dart';
import '../utils/date_format.dart';

/// 화면 ④ 기사 상세.
/// 출처·시간·제목·키워드 태그·RSS 요약 본문·원문 보기 버튼.
/// 제목·본문은 텍스트 선택/복사 가능, 원문 보기는 외부 브라우저로 연결.
class ArticleDetailScreen extends StatelessWidget {
  final MatchedArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  Future<void> _openOriginal() async {
    final uri = Uri.tryParse(article.link);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => Share.share(article.link),
            icon: const Icon(Icons.share_outlined),
            color: AppColors.textPrimary(brightness),
            tooltip: '공유하기',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 원본 출처와 발행 일시 (플레이 뉴스 정책 요건).
            _MetaLine(
              label: '출처',
              value: article.source,
              valueStyle: AppTextStyles.source(brightness),
            ),
            const SizedBox(height: 6),
            _MetaLine(
              label: '발행',
              value: formatPublishedLong(article.pubDate),
              valueStyle: AppTextStyles.meta(brightness).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 22),
            SelectableText(
              article.title,
              style: AppTextStyles.articleTitle(brightness),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: article.keywords
                  .map(
                    (keyword) => Container(
                      height: AppSizes.keywordTagHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.tagBackground(brightness),
                        borderRadius: BorderRadius.circular(
                          AppSizes.keywordTagHeight / 2,
                        ),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          keyword,
                          style: AppTextStyles.tag(brightness),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            SelectableText(
              article.description.isEmpty
                  ? '${article.source}는 RSS 요약을 제공하지 않아요. 원문 보기로 기사 내용을 확인해 주세요.'
                  : article.description,
              style: AppTextStyles.articleBody(brightness),
            ),
            const SizedBox(height: 8),
            // 요약이 없는 기사(구글 뉴스 경유)에도 출처·저작권 안내는 항상 보인다.
            Text(
              '기사 전문과 저작권은 ${article.source}에 있으며, '
              '아래 원문 보기로 ${article.source} 기사를 확인할 수 있습니다.',
              style: AppTextStyles.caption(brightness),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: AppSizes.buttonHeight,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openOriginal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(brightness),
                  foregroundColor: AppColors.onPrimary(brightness),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  ),
                ),
                child: Text('원문 보기', style: AppTextStyles.button(brightness)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// '출처  동아일보' / '발행  2026년 11월 26일 (목) 15:13' 한 줄.
class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;

  const _MetaLine({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: AppTextStyles.meta(brightness).copyWith(fontSize: 14),
          ),
        ),
        Expanded(child: Text(value, style: valueStyle)),
      ],
    );
  }
}
