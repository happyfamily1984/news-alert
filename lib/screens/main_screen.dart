import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/app_bottom_navigation.dart';
import 'add_keyword_screen.dart';
import 'home_screen.dart';
import 'news_list_screen.dart';
import 'settings_screen.dart';

/// 하단 내비게이션(홈/뉴스/설정)을 가진 메인 화면.
/// 키워드 추가 플로팅 버튼은 홈 탭에서만 보인다.
class MainScreen extends StatefulWidget {
  final SettingsController settings;

  const MainScreen({super.key, required this.settings});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _index = 0;
  int _newsRefreshSignal = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    // 첫 프레임이 그려진 뒤에 알림 권한 요청. 시작 전에 요청하면
    // 권한 창 결과가 안 돌아오고 스플래시에서 멈출 수 있다.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 알림을 눌러서 앱이 켜졌으면 그 기사를 먼저 연다.
      try {
        await NotificationService.instance.handleLaunchNotification();
      } catch (_) {}
      await NotificationService.instance.requestPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱으로 돌아오면 백그라운드에서 찾은 기사가 바로 보이도록 다시 읽는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _homeKey.currentState?.reload();
    setState(() => _newsRefreshSignal++);
  }

  /// 뒤로가기: 뉴스·설정 탭이면 홈 탭으로, 홈 탭이면 종료할지 묻는다.
  /// (다른 화면이나 창이 열려 있을 때는 그쪽이 먼저 닫히므로 여기까지 오지 않는다.)
  Future<void> _onBack() async {
    if (_index != 0) {
      _onTab(0);
      return;
    }
    final brightness = Theme.of(context).brightness;
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        content: Text('앱을 종료하겠습니까?', style: AppTextStyles.body(brightness)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '아니오',
              style: AppTextStyles.body(
                brightness,
              ).copyWith(color: AppColors.textSecondary(brightness)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '예',
              style: AppTextStyles.body(
                brightness,
              ).copyWith(color: AppColors.primary(brightness)),
            ),
          ),
        ],
      ),
    );
    if (exit == true) {
      await SystemNavigator.pop();
    }
  }

  void _onTab(int index) {
    setState(() {
      _index = index;
      if (index == 1) _newsRefreshSignal++;
    });
    if (index == 0) _homeKey.currentState?.reload();
  }

  Future<void> _openAddKeyword() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddKeywordScreen()),
    );
    if (added == true) {
      _homeKey.currentState?.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('키워드를 등록했습니다.')));
      // 이미 올라와 있던 기사는 알림 없이 목록에만 채운다.
      await _homeKey.currentState?.checkSilently();
      if (!mounted) return;
      setState(() => _newsRefreshSignal++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              key: _homeKey,
              settings: widget.settings,
              onGoNews: () => _onTab(1),
              onAddKeyword: _openAddKeyword,
            ),
            NewsListScreen(refreshSignal: _newsRefreshSignal),
            SettingsScreen(settings: widget.settings),
          ],
        ),
        floatingActionButton: _index == 0
            ? SizedBox(
                width: AppSizes.fabSize,
                height: AppSizes.fabSize,
                child: FloatingActionButton(
                  onPressed: _openAddKeyword,
                  backgroundColor: AppColors.primary(brightness),
                  foregroundColor: AppColors.onPrimary(brightness),
                  shape: const CircleBorder(),
                  tooltip: '키워드 추가',
                  child: const Icon(Icons.add, size: 28),
                ),
              )
            : null,
        // 하단바를 SafeArea로 감싼다. 폰의 시스템 내비게이션(제스처 바·3버튼 바)이
        // 화면 아래를 차지하면 하단바가 그 뒤에 가려져 반쯤 잘리기 때문이다.
        bottomNavigationBar: SafeArea(
          top: false,
          child: AppBottomNavigation(currentIndex: _index, onTap: _onTab),
        ),
      ),
    );
  }
}
