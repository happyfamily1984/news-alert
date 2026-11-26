import 'package:flutter/material.dart';

import '../models/matched_article.dart';
import '../services/news_check_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/app_background.dart';
import '../widgets/news_card.dart';
import '../widgets/news_status.dart';
import 'article_detail_screen.dart';

/// 화면 ③ 뉴스 목록.
///
/// 탭 화면(필터 없음)은 위쪽에서 '키워드 뉴스'와 '최신 뉴스'를 고른다.
/// - 키워드 뉴스: 등록한 키워드와 매칭된 기사. 같은 기사가 여러 키워드에 맞으면
///   한 번만 보여주고 키워드를 함께 표시한다.
/// - 최신 뉴스: 키워드와 상관없이 켜진 언론사의 최신 기사.
/// 키워드 뉴스가 없으면 처음부터 최신 뉴스를 보여준다. 화면이 비어
/// '뉴스 섹션이 작동하지 않는 앱'으로 보이지 않게 하기 위해서다 (플레이 심사 거부 사유).
///
/// 홈의 키워드 카드에서 들어오면([filterKeyword]) 그 키워드 기사만 보여준다.
class NewsListScreen extends StatefulWidget {
  final String? filterKeyword;
  final int refreshSignal;

  /// 값이 바뀌면 '최신 뉴스' 쪽을 연다 (홈의 '최신 뉴스 더보기').
  final int showLatestSignal;

  const NewsListScreen({
    super.key,
    this.filterKeyword,
    this.refreshSignal = 0,
    this.showLatestSignal = 0,
  });

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<MatchedArticle> _articles = [];
  List<MatchedArticle> _latest = [];
  Set<String> _readIds = {};
  bool _checking = false;
  bool _fetchFailed = false;
  bool _loaded = false;

  /// true면 최신 뉴스, false면 키워드 뉴스. null이면 아직 고르지 않음
  /// (키워드 뉴스가 있으면 키워드 뉴스, 없으면 최신 뉴스).
  bool? _showLatestChoice;

  bool get _isTab => widget.filterKeyword == null;

  bool get _showLatest => _isTab && (_showLatestChoice ?? _articles.isEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.showLatestSignal > 0) _showLatestChoice = true;
    _load();
  }

  @override
  void didUpdateWidget(covariant NewsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLatestSignal != oldWidget.showLatestSignal) {
      setState(() => _showLatestChoice = true);
    }
    if (widget.refreshSignal != oldWidget.refreshSignal) {
      _load();
    }
  }

  Future<void> _load() async {
    final storage = StorageService.instance;
    final articles = await storage.getArticles();
    final latest = await storage.getLatestArticles();
    final readIds = await storage.getReadIds();
    final fetchFailed = await storage.getLastFetchFailed();
    if (!mounted) return;
    setState(() {
      _articles = articles;
      _latest = latest;
      _readIds = readIds;
      _fetchFailed = fetchFailed;
      _loaded = true;
    });
    // 아직 아무 기사도 받은 적이 없으면 바로 받아 온다.
    if (articles.isEmpty && latest.isEmpty && !fetchFailed) {
      await _checkNow(quiet: true);
    }
  }

  List<MatchedArticle> get _visible {
    if (_showLatest) return _latest;
    final list = widget.filterKeyword == null
        ? List<MatchedArticle>.from(_articles)
        : _articles
              .where((a) => a.keywords.contains(widget.filterKeyword))
              .toList();
    list.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return list;
  }

  Future<void> _checkNow({bool quiet = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await NewsCheckService.instance.runCheck(notify: !quiet);
      if (!mounted) return;
      setState(() => _checking = false);
      await _load();
      if (!mounted || quiet) return;
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
      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 중 문제가 생겼어요. 잠시 뒤 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted && _checking) setState(() => _checking = false);
    }
  }

  Future<void> _openArticle(MatchedArticle article) async {
    await StorageService.instance.markAsRead(article.id);
    if (mounted) {
      setState(() => _readIds = {..._readIds, article.id});
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final visible = _visible;
    final title = widget.filterKeyword == null
        ? '매칭 뉴스'
        : '‘${widget.filterKeyword}’ 뉴스';
    return Stack(
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: AppColors.primary(brightness),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.screenTitle(brightness)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _checking ? null : () => _checkNow(),
                icon: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                color: AppColors.textPrimary(brightness),
                tooltip: '지금 확인',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _checkNow(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.pagePadding,
                AppSizes.pagePadding,
                AppSizes.tabListBottomPadding,
              ),
              children: [
                if (_isTab) ...[
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text('키워드 뉴스 ${_articles.length}'),
                        icon: const Icon(Icons.label_outline),
                      ),
                      const ButtonSegment(
                        value: true,
                        label: Text('최신 뉴스'),
                        icon: Icon(Icons.bolt),
                      ),
                    ],
                    selected: {_showLatest},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: AppColors.surface(brightness),
                      foregroundColor: AppColors.textSecondary(brightness),
                      selectedBackgroundColor: AppColors.primary(brightness),
                      selectedForegroundColor: AppColors.onPrimary(brightness),
                      side: BorderSide(color: AppColors.border(brightness)),
                    ),
                    onSelectionChanged: (v) =>
                        setState(() => _showLatestChoice = v.first),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_fetchFailed && visible.isNotEmpty) ...[
                  StaleNewsBanner(onRetry: _checking ? null : _checkNow),
                  const SizedBox(height: 16),
                ],
                if (visible.isEmpty)
                  ..._emptyState(brightness)
                else
                  for (final article in visible) ...[
                    NewsCard(
                      article: article,
                      isRead: _showLatest || _readIds.contains(article.id),
                      onTap: () => _openArticle(article),
                    ),
                    const SizedBox(height: 16),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _emptyState(Brightness brightness) {
    // 최신 뉴스가 비었거나(첫 실행·네트워크 오류) 아직 읽지 못한 상태.
    if (_showLatest || !_loaded) {
      return [
        NewsStatusCard(
          loading: _checking || !_loaded,
          failed: _fetchFailed,
          onRetry: _checkNow,
        ),
      ];
    }
    // 키워드 뉴스만 비었다: 최신 뉴스로 안내한다.
    return [
      const SizedBox(height: 24),
      Image.asset(
        'assets/illustrations/empty_news.png',
        height: 180,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: 20),
      Text(
        widget.filterKeyword == null
            ? '아직 키워드와 맞는 뉴스가 없어요.'
            : '‘${widget.filterKeyword}’ 뉴스가 아직 없어요.',
        textAlign: TextAlign.center,
        style: AppTextStyles.emptyTitle(brightness),
      ),
      const SizedBox(height: 8),
      Text(
        '새 기사가 올라오면 알려드릴게요.',
        textAlign: TextAlign.center,
        style: AppTextStyles.heroSubtitle(brightness),
      ),
      if (_isTab) ...[
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: () => setState(() => _showLatestChoice = true),
            icon: const Icon(Icons.bolt),
            label: const Text('최신 뉴스 보기'),
          ),
        ),
      ],
    ];
  }
}
