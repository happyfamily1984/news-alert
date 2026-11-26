import 'package:flutter/material.dart';

import '../theme.dart';

/// 보여줄 기사가 없을 때의 상태 카드. 화면이 멈춘 것처럼 보이지 않게
/// 불러오는 중 / 불러오기 실패(다시 시도) / 아직 없음(지금 확인)을 구분해 보여준다.
class NewsStatusCard extends StatelessWidget {
  final bool loading;
  final bool failed;
  final VoidCallback? onRetry;

  /// '아직 없음' 상태의 안내 문구.
  final String emptyMessage;

  const NewsStatusCard({
    super.key,
    required this.loading,
    required this.failed,
    required this.onRetry,
    this.emptyMessage = '아직 불러온 뉴스가 없어요.',
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Widget icon;
    final String title;
    final String? body;
    final String? action;
    if (loading) {
      icon = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
      title = '최신 뉴스를 불러오는 중이에요';
      body = '연합뉴스·조선일보·중앙일보·동아일보·YTN·MBC·KBS에서 가져옵니다.';
      action = null;
    } else if (failed) {
      icon = Icon(Icons.wifi_off, size: 32, color: AppColors.error(brightness));
      title = '뉴스를 불러오지 못했어요';
      body = '인터넷 연결을 확인한 뒤 다시 시도해 주세요.';
      action = '다시 시도';
    } else {
      icon = Icon(
        Icons.newspaper,
        size: 32,
        color: AppColors.primary(brightness),
      );
      title = emptyMessage;
      body = '지금 확인을 누르면 최신 뉴스를 바로 가져옵니다.';
      action = '지금 확인';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.emptyTitle(brightness),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.heroSubtitle(brightness),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(action),
            ),
          ],
        ],
      ),
    );
  }
}

/// 기사는 있지만 마지막 확인이 실패했을 때 목록 위에 보여주는 띠.
class StaleNewsBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const StaleNewsBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.tipBackground(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: AppColors.error(brightness)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '최신 뉴스를 받지 못해 이전에 받은 뉴스를 보여드려요.',
              style: AppTextStyles.meta(brightness),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
