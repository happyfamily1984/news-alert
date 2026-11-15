import 'package:flutter/material.dart';

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
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onTap: _onTab,
      ),
    );
  }
}
