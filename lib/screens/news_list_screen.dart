import 'package:flutter/material.dart';

import '../models/matched_article.dart';
import '../services/news_check_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/news_card.dart';
import 'article_detail_screen.dart';

/// 화면 ③ 매칭 뉴스 목록.
/// 상단에 선택된 키워드 표시, 아래 매칭 뉴스를 최신순으로.
/// 같은 기사가 여러 키워드에 매칭되면 한 번만 노출하고 키워드를 함께 표시.
/// 새로 들어온 뉴스는 읽지 않음 표시.
class NewsListScreen extends StatefulWidget {
  final String? filterKeyword;
  final int refreshSignal;

  const NewsListScreen({
    super.key,
    this.filterKeyword,
    this.refreshSignal = 0,
  });

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<MatchedArticle> _articles = [];
  Set<String> _readIds = {};
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NewsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != oldWidget.refreshSignal) {
      _load();
    }
  }

  Future<void> _load() async {
    final storage = StorageService.instance;
    final articles = await storage.getArticles();
    final readIds = await storage.getReadIds();
    if (!mounted) return;
    setState(() {
      _articles = articles;
      _readIds = readIds;
    });
  }

  List<MatchedArticle> get _visible {
    final list =
        widget.filterKeyword == null
            ? List<MatchedArticle>.from(_articles)
            : _articles
                .where((a) => a.keywords.contains(widget.filterKeyword))
                .toList();
    list.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return list;
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final fresh = await NewsCheckService.instance.runCheck(notify: true);
      await _load();
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

  Future<void> _openArticle(MatchedArticle article) async {
    await StorageService.instance.markAsRead(article.id);
    if (mounted) {
      setState(() => _readIds = {..._readIds, article.id});
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.filterKeyword == null
              ? '매칭 뉴스'
              : '‘${widget.filterKeyword}’ 뉴스',
          style: AppTextStyles.screenTitle(brightness),
        ),
        actions: [
          IconButton(
            onPressed: _checking ? null : _checkNow,
            icon: const Icon(Icons.refresh),
            color: AppColors.textPrimary(brightness),
            tooltip: '지금 확인',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child:
            visible.isEmpty
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text(
                        widget.filterKeyword == null
                            ? '아직 매칭된 뉴스가 없습니다.\n키워드를 등록하고 ‘지금 확인’을 눌러보세요.'
                            : '‘${widget.filterKeyword}’와(과) 매칭된 뉴스가 아직 없습니다.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(brightness).copyWith(
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ),
                  ],
                )
                : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final article = visible[index];
                    return NewsCard(
                      article: article,
                      isRead: _readIds.contains(article.id),
                      onTap: () => _openArticle(article),
                    );
                  },
                ),
      ),
    );
  }
}
