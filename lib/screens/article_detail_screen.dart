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
            Text('연합뉴스', style: AppTextStyles.source(brightness)),
            const SizedBox(height: 4),
            Text(
              formatArticleTime(article.pubDate),
              style: AppTextStyles.meta(brightness),
            ),
            const SizedBox(height: 12),
            SelectableText(
              article.title,
              style: AppTextStyles.articleTitle(brightness),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  article.keywords
                      .map(
                        (keyword) => Container(
                          height: AppSizes.keywordTagHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.tagBackground(brightness),
                            borderRadius: BorderRadius.circular(
                              AppSizes.keywordTagHeight / 2,
                            ),
                          ),
                          child: Text(
                            keyword,
                            style: AppTextStyles.tag(brightness),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            SelectableText(
              article.description.isEmpty
                  ? '요약 내용이 없습니다. 원문 보기 버튼으로 기사를 확인해 주세요.'
                  : article.description,
              style: AppTextStyles.articleBody(brightness),
            ),
            const SizedBox(height: 8),
            Text(
              'RSS 요약 내용입니다. 전문은 원문에서 확인하세요.',
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
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  ),
                ),
                child: Text(
                  '원문 보기',
                  style: AppTextStyles.button(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
