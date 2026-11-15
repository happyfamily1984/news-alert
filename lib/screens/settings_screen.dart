import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/settings_controller.dart';
import '../theme.dart';

/// 화면 ⑤ 설정.
/// 알림 설정 그룹(전체 알림, 확인 주기, 새 뉴스만 알림, 알림 테스트)
/// + 앱 설정 그룹(테마, RSS 출처, 앱 버전).
class SettingsScreen extends StatefulWidget {
  final SettingsController settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _testing = false;

  Future<void> _testNotification() async {
    if (_testing) return;
    setState(() => _testing = true);
    await NotificationService.instance.showTestNotification();
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('테스트 알림을 보냈습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final settings = widget.settings;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('설정', style: AppTextStyles.screenTitle(brightness)),
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            children: [
              Text('알림 설정', style: AppTextStyles.groupTitle(brightness)),
              const SizedBox(height: 8),
              _SettingsCard(
                brightness: brightness,
                children: [
                  _SwitchRow(
                    title: '전체 알림',
                    subtitle: '키워드 뉴스가 올라오면 알림을 받습니다',
                    value: settings.notificationsEnabled,
                    onChanged: settings.setNotificationsEnabled,
                  ),
                  const _Divider(),
                  _DropdownRow<int>(
                    title: '알림 확인 주기',
                    subtitle: '백그라운드에서 RSS를 확인하는 간격',
                    value: settings.checkIntervalMinutes,
                    options: const [
                      (15, '15분'),
                      (30, '30분'),
                      (60, '60분'),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.setCheckIntervalMinutes(value);
                      }
                    },
                  ),
                  const _Divider(),
                  _SwitchRow(
                    title: '새 뉴스만 알림',
                    subtitle: '이미 본 뉴스는 다시 알리지 않습니다',
                    value: settings.notifyNewOnly,
                    onChanged: settings.setNotifyNewOnly,
                  ),
                  const _Divider(),
                  _ActionRow(
                    title: '알림 테스트',
                    subtitle: '테스트 알림을 바로 보내봅니다',
                    trailing:
                        _testing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.chevron_right),
                    onTap: _testNotification,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('앱 설정', style: AppTextStyles.groupTitle(brightness)),
              const SizedBox(height: 8),
              _SettingsCard(
                brightness: brightness,
                children: [
                  _DropdownRow<ThemeMode>(
                    title: '테마',
                    subtitle: '시스템 설정에 따라 라이트/다크 전환',
                    value: settings.themeMode,
                    options: const [
                      (ThemeMode.system, '시스템'),
                      (ThemeMode.light, '라이트'),
                      (ThemeMode.dark, '다크'),
                    ],
                    onChanged: (value) {
                      if (value != null) settings.setThemeMode(value);
                    },
                  ),
                  const _Divider(),
                  const _InfoRow(title: 'RSS 출처', value: '연합뉴스'),
                  const _Divider(),
                  const _InfoRow(title: '앱 버전', value: '1.0.0'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Brightness brightness;
  final List<Widget> children;

  const _SettingsCard({required this.brightness, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border(brightness)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border(brightness),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: AppSizes.settingsRowHeight,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(brightness)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption(brightness)),
                ],
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary(brightness),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  const _DropdownRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: AppSizes.settingsRowHeight,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(brightness)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption(brightness)),
                ],
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary(brightness),
            ),
            style: AppTextStyles.body(brightness),
            items:
                options
                    .map(
                      (option) => DropdownMenuItem<T>(
                        value: option.$1,
                        child: Text(option.$2),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: AppSizes.settingsRowHeight,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body(brightness)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption(brightness)),
                  ],
                ),
              ),
            ),
            trailing,
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: AppSizes.settingsRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.body(brightness)),
            ),
            Text(
              value,
              style: AppTextStyles.body(
                brightness,
              ).copyWith(color: AppColors.textSecondary(brightness)),
            ),
          ],
        ),
      ),
    );
  }
}
