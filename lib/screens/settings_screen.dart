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
    try {
      // 알림 권한이 꺼져 있으면 보내도 안 뜨니 먼저 확인하고, 꺼져 있으면
      // 권한 요청을 한 번 더 띄운다.
      var enabled =
          await NotificationService.instance.areNotificationsEnabled();
      if (!enabled) {
        await NotificationService.instance.requestPermission();
        enabled = await NotificationService.instance.areNotificationsEnabled();
      }
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '알림 권한이 꺼져 있어요. 폰 설정 > 앱 > 뉴스 알리미 > 알림에서 켜주세요.',
            ),
          ),
        );
        return;
      }
      // 보내기가 끝나지 않고 멈추는 경우에도 빙글빙글만 돌지 않게 시간 제한을 둔다.
      await NotificationService.instance
          .showTestNotification()
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('테스트 알림을 보냈습니다.')));
    } catch (e) {
      // 보내기가 실패해도 원인을 보여주고 멈춘다. 예전 코드는 여기서
      // 예외가 나면 로딩 상태가 그대로 남아 빙글빙글만 돌았다.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('알림을 보내지 못했어요: $e')));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.settingsName(brightness)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.settingsDesc(brightness)),
                ],
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary(brightness),
          ),
          const SizedBox(width: 20),
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
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.settingsName(brightness)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.settingsDesc(brightness)),
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
          const SizedBox(width: 20),
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
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.settingsName(brightness)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.settingsDesc(brightness)),
                  ],
                ),
              ),
            ),
            trailing,
            const SizedBox(width: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.settingsName(brightness)),
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
