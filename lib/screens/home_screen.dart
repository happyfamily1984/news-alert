import 'package:flutter/material.dart';

import '../models/matched_article.dart';
import '../services/news_check_service.dart';
import '../services/settings_controller.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/keyword_card.dart';
import 'news_list_screen.dart';

/// 화면 ① 홈 (키워드 목록).
/// 상단 앱바(64dp), 오늘의 뉴스 요약 카드(최소 148dp, Primary 배경),
/// 키워드 카드 목록(84dp), 오른쪽 상단 마지막 RSS 확인 시간,
/// 키워드 추가는 우측 하단 플로팅 버튼.
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppSizes.appBarHeight,
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('뉴스 알리미', style: AppTextStyles.appTitle(brightness)),
        actions: [
          IconButton(
            onPressed: widget.onGoNews,
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary(brightness),
            tooltip: '뉴스 보기',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            _SummaryCard(
              todayTotal: _todayTotal,
              keywordCount: _keywords.length,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatLastCheck(_lastCheck),
                style: AppTextStyles.meta(brightness),
              ),
            ),
            const SizedBox(height: 12),
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
            SizedBox(
              height: AppSizes.buttonHeight,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checking ? null : _checkNow,
                icon:
                    _checking
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.refresh),
                label: Text(
                  _checking ? '확인 중...' : '지금 확인',
                  style: AppTextStyles.button(brightness),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(brightness),
                  foregroundColor: AppColors.onPrimary(brightness),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.buttonRadius,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int todayTotal;
  final int keywordCount;

  const _SummaryCard({required this.todayTotal, required this.keywordCount});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      // 고정 높이 대신 최소 높이: 콘텐츠가 늘어나도 글자가 잘리지 않는다.
      constraints: const BoxConstraints(
        minHeight: AppSizes.summaryCardMinHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary(brightness),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
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
                const SizedBox(height: 4),
                Text(
                  '키워드 $keywordCount개 모니터링 중',
                  style: AppTextStyles.summarySub(brightness),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.newspaper,
            color: AppColors.summaryIconLight,
            size: 52,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search,
            size: 40,
            color: AppColors.textSecondary(brightness),
          ),
          const SizedBox(height: 12),
          Text(
            '아직 등록된 키워드가 없습니다',
            style: AppTextStyles.cardTitle(brightness),
          ),
          const SizedBox(height: 6),
          Text(
            '관심 있는 키워드를 등록하면\n관련 뉴스가 올라올 때 알려드립니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              brightness,
            ).copyWith(color: AppColors.textSecondary(brightness)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(brightness),
                foregroundColor: AppColors.onPrimary(brightness),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSizes.buttonRadius,
                  ),
                ),
              ),
              child: Text(
                '키워드 추가하기',
                style: AppTextStyles.button(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
