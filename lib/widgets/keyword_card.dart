import 'package:flutter/material.dart';

import '../theme.dart';

/// 홈 화면의 키워드 카드 (높이 84dp, 모서리 18dp).
/// 키워드 17sp Bold + 오늘 매칭 건수 15sp Medium Primary 색.
class KeywordCard extends StatelessWidget {
  final String keyword;
  final int todayCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const KeywordCard({
    super.key,
    required this.keyword,
    required this.todayCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      height: AppSizes.keywordCardHeight,
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keyword,
                      style: AppTextStyles.cardTitle(
                        brightness,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '오늘 매칭 $todayCount건',
                      style: AppTextStyles.count(brightness),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppColors.textSecondary(brightness),
                tooltip: '키워드 삭제',
              ),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: AppColors.textSecondary(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
