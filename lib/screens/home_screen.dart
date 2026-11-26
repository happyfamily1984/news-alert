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
import '../widgets/news_card.dart';
import '../widgets/news_status.dart';
import 'article_detail_screen.dart';
import 'news_list_screen.dart';

/// 화면 ① 홈 (키워드 목록). v3 시안:
/// 그라데이션 배경, 파란 그라데이션 요약 카드, '방금 확인' 행 + 전체보기,
/// 키워드가 없으면 일러스트 빈 상태 + 그라데이션 추가 버튼 + 외곽선 확인 버튼.
/// 키워드 아래에는 키워드와 상관없는 '최신 뉴스'를 항상 보여준다.
/// 화면이 비어 '작동하지 않는 앱'으로 보이지 않게 하기 위해서다 (플레이 심사 거부 사유).
class HomeScreen extends StatefulWidget {
  final SettingsController settings;
  final VoidCallback onGoNews;
  final VoidCallback onGoLatest;
  final VoidCallback onAddKeyword;

  /// 확인이 끝나 저장된 기사가 바뀌었을 때 (뉴스 탭 새로고침용).
  final VoidCallback onArticlesChanged;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.onGoNews,
    required this.onGoLatest,
    required this.onAddKeyword,
    required this.onArticlesChanged,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<String> _keywords = [];
  List<MatchedArticle> _articles = [];
  List<MatchedArticle> _latest = [];
  DateTime? _lastCheck;
  bool _checking = false;
  bool _fetchFailed = false;

  /// 이보다 오래전에 확인했으면 화면을 열 때 바로 다시 확인한다.
  static const Duration _staleAfter = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    reload().then((_) => refreshIfStale());
  }

  Future<void> reload() async {
    final storage = StorageService.instance;
    final keywords = await storage.getKeywords();
    final articles = await storage.getArticles();
    final latest = await storage.getLatestArticles();
    final lastCheck = await storage.getLastCheckAt();
    final fetchFailed = await storage.getLastFetchFailed();
    if (!mounted) return;
    setState(() {
      _keywords = keywords;
      _articles = articles;
      _latest = latest;
      _lastCheck = lastCheck;
      _fetchFailed = fetchFailed;
    });
  }

  /// 첫 실행이거나 마지막 확인이 오래됐으면 알림 없이 바로 확인한다.
  /// 첫 실행 때 홈과 뉴스 탭에 실제 기사가 바로 채워진다.
  Future<void> refreshIfStale() async {
    final last = _lastCheck;
    final stale =
        last == null ||
        DateTime.now().difference(last) > _staleAfter ||
        _latest.isEmpty;
    if (stale) await checkSilently();
  }

  /// 홈에 보여줄 최신 뉴스 5건: 언론사마다 가장 최신 기사부터 한 건씩
  /// 돌아가며 고른다 (여러 언론사 기사가 섞여 보이게).
  List<MatchedArticle> get _latestPreview {
    final bySource = <String, List<MatchedArticle>>{};
    for (final a in _latest) {
      bySource.putIfAbsent(a.source, () => []).add(a);
    }
    final queues = bySource.values.toList();
    final picked = <MatchedArticle>[];
    for (var round = 0; picked.length < 5; round++) {
      var any = false;
      for (final q in queues) {
        if (round < q.length && picked.length < 5) {
          picked.add(q[round]);
          any = true;
        }
      }
      if (!any) break;
    }
    picked.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return picked;
  }

  void _openArticle(MatchedArticle article) {
    StorageService.instance.markAsRead(article.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
    );
  }

  bool _isToday(DateTime dt, DateTime now) {
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  int _todayCount(String keyword) {
    final now = DateTime.now();
    return _articles
        .where((a) => a.keywords.contains(keyword) && _isToday(a.pubDate, now))
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
      final result = await NewsCheckService.instance.runCheck(notify: true);
      await reload();
      widget.onArticlesChanged();
      if (!mounted) return;
      final count = result.newArticles.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.allFailed
                ? '뉴스를 불러오지 못했어요. 인터넷 연결을 확인해 주세요.'
                : count == 0
                ? '새로운 키워드 뉴스가 없습니다. 최신 뉴스는 갱신했어요.'
                : '새 뉴스 $count건을 찾았습니다.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 중 문제가 생겼어요. 잠시 뒤 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// 키워드를 새로 등록한 직후에 알림 없이 한 번 확인한다.
  /// 이미 올라와 있던 기사를 목록에만 채워 넣어서, 다음 확인 때
  /// 옛 기사가 '새 뉴스'로 한꺼번에 알림 오는 것을 막는다.
  Future<void> checkSilently() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await NewsCheckService.instance.runCheck(notify: false);
      await reload();
      widget.onArticlesChanged();
    } catch (_) {
      // 네트워크 실패 등은 조용히 넘긴다. 다음 주기 확인에서 다시 시도된다.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _confirmDelete(String keyword) async {
    final brightness = Theme.of(context).brightness;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        title: Text('키워드 삭제', style: AppTextStyles.cardTitle(brightness)),
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
      MaterialPageRoute(builder: (_) => NewsListScreen(filterKeyword: keyword)),
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
                Text('뉴스 알리미', style: AppTextStyles.appTitle(brightness)),
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
                const SizedBox(height: 12),
                _LatestHeader(onMore: widget.onGoLatest),
                const SizedBox(height: 12),
                if (_latest.isEmpty)
                  NewsStatusCard(
                    loading: _checking,
                    failed: _fetchFailed,
                    onRetry: _checkNow,
                  )
                else ...[
                  if (_fetchFailed) ...[
                    StaleNewsBanner(onRetry: _checking ? null : _checkNow),
                    const SizedBox(height: 12),
                  ],
                  for (final article in _latestPreview) ...[
                    NewsCard(
                      article: article,
                      isRead: true,
                      onTap: () => _openArticle(article),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
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

/// '최신 뉴스' 제목 + 더보기.
class _LatestHeader extends StatelessWidget {
  final VoidCallback onMore;

  const _LatestHeader({required this.onMore});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Icon(Icons.bolt, size: 22, color: AppColors.primary(brightness)),
        const SizedBox(width: 6),
        Text('최신 뉴스', style: AppTextStyles.groupTitle(brightness)),
        const Spacer(),
        TextButton(
          onPressed: onMore,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('더보기', style: AppTextStyles.pillText(brightness)),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary(brightness),
              ),
            ],
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
          Text('아직 등록된 키워드가 없습니다', style: AppTextStyles.emptyTitle(brightness)),
          const SizedBox(height: 8),
          Text(
            '관심 있는 키워드를 등록하면\n관련 뉴스를 알림으로 받아볼 수 있어요!',
            textAlign: TextAlign.center,
            style: AppTextStyles.heroSubtitle(brightness),
          ),
          const SizedBox(height: 20),
          GradientButton(label: '키워드 추가하기', icon: Icons.add, onPressed: onAdd),
        ],
      ),
    );
  }
}
