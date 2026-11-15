import 'package:flutter/material.dart';

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

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  int _newsRefreshSignal = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    // 첫 프레임이 그려진 뒤에 알림 권한 요청. 시작 전에 요청하면
    // 권한 창 결과가 안 돌아오고 스플래시에서 멈출 수 있다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermission();
    });
  }

  void _onTab(int index) {
    setState(() {
      _index = index;
      if (index == 1) _newsRefreshSignal++;
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
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
      floatingActionButton:
          _index == 0
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
        child: AppBottomNavigation(
          currentIndex: _index,
          onTap: _onTab,
        ),
      ),
    );
  }
}
