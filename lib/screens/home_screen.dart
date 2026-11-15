import 'package:flutter/material.dart';

import '../models/matched_article.dart';
import '../services/news_check_service.dart';
import '../services/settings_controller.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/app_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/keyword_card.dart';
import 'news_list_screen.dart';

/// 화면 ① 홈 (키워드 목록). v3 시안:
/// 그라데이션 배경, 파란 그라데이션 요약 카드, '방금 확인' 행 + 전체보기,
/// 키워드가 없으면 일러스트 빈 상태 + 그라데이션 추가 버튼 + 외곽선 확인 버튼.
class HomeScreen extends StatefulWidget {
  final SettingsController settings;
  final VoidCallback onGoNews;
  final VoidCallback onAddKeyword;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.onGoNews,
    required this.onAddKeyword,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<String> _keywords = [];
  List<MatchedArticle> _articles = [];
  DateTime? _lastCheck;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final storage = StorageService.instance;
    final keywords = await storage.getKeywords();
    final articles = await storage.getArticles();
    final lastCheck = await storage.getLastCheckAt();
    if (!mounted) return;
    setState(() {
      _keywords = keywords;
      _articles = articles;
      _lastCheck = lastCheck;
    });
  }

  bool _isToday(DateTime dt, DateTime now) {
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  int _todayCount(String keyword) {
    final now = DateTime.now();
    return _articles
        .where(
          (a) => a.keywords.contains(keyword) && _isToday(a.pubDate, now),
        )
        .length;
  }

  int get _todayTotal {
    final now = DateTime.now();
    return _articles.where((a) => _isToday(a.pubDate, now)).length;
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final fresh = await NewsCheckService.instance.runCheck(notify: true);
      await reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fresh.isEmpty
                ? '새로운 뉴스가 없습니다.'
                : '새 뉴스 ${fresh.length}건을 찾았습니다.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _confirmDelete(String keyword) async {
    final brightness = Theme.of(context).brightness;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface(brightness),
            title: Text(
              '키워드 삭제',
              style: AppTextStyles.cardTitle(brightness),
            ),
            content: Text(
              '‘$keyword’ 키워드를 삭제할까요?',
              style: AppTextStyles.body(brightness),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '취소',
                  style: AppTextStyles.body(
                    brightness,
                  ).copyWith(color: AppColors.textSecondary(brightness)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '삭제',
                  style: AppTextStyles.body(
                    brightness,
                  ).copyWith(color: AppColors.error(brightness)),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await StorageService.instance.removeKeyword(keyword);
      await reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('키워드를 삭제했습니다.')));
    }
  }

  void _openKeywordNews(String keyword) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsListScreen(filterKeyword: keyword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Stack(
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: AppSizes.appBarHeight,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.buttonGradientLight,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '뉴스 알리미',
                  style: AppTextStyles.appTitle(brightness),
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: widget.onGoNews,
                    icon: const Icon(Icons.notifications_outlined),
                    color: AppColors.textPrimary(brightness),
                    tooltip: '뉴스 보기',
                  ),
                  if (_todayTotal > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5484D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.pagePadding,
                AppSizes.pagePadding,
                AppSizes.tabListBottomPadding,
              ),
              children: [
                _SummaryCard(
                  todayTotal: _todayTotal,
                  keywordCount: _keywords.length,
                  onTap: widget.onGoNews,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.textPrimary(brightness),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatLastCheck(_lastCheck),
                      style: AppTextStyles.checkRowLabel(brightness),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: widget.onGoNews,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(brightness),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border(brightness),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '전체보기',
                              style: AppTextStyles.pillText(brightness),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.textSecondary(brightness),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_keywords.isEmpty)
                  _EmptyKeywords(onAdd: widget.onAddKeyword)
                else
                  ..._keywords.map(
                    (keyword) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: KeywordCard(
                        keyword: keyword,
                        todayCount: _todayCount(keyword),
                        onTap: () => _openKeywordNews(keyword),
                        onDelete: () => _confirmDelete(keyword),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlineButton(
                  label: _checking ? '확인 중...' : '지금 확인',
                  icon: Icons.refresh,
                  onPressed: _checking ? null : _checkNow,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int todayTotal;
  final int keywordCount;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.todayTotal,
    required this.keywordCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.summaryGradientLight,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2462E9).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.summaryCardMinHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '오늘의 매칭 뉴스',
                            style: AppTextStyles.summaryLabel(brightness),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$todayTotal건',
                            style: AppTextStyles.summaryCount(brightness),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '키워드 $keywordCount개 모니터링 중',
                                  style: AppTextStyles.summarySub(brightness),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.newspaper,
                      color: AppColors.summaryIconLight,
                      size: 56,
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyKeywords extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyKeywords({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A6B).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/illustrations/empty_search.png',
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 등록된 키워드가 없습니다',
            style: AppTextStyles.emptyTitle(brightness),
          ),
          const SizedBox(height: 8),
          Text(
            '관심 있는 키워드를 등록하면\n관련 뉴스를 알림으로 받아볼 수 있어요!',
            textAlign: TextAlign.center,
            style: AppTextStyles.heroSubtitle(brightness),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: '키워드 추가하기',
            icon: Icons.add,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
