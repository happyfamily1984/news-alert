import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

/// 로컬 알림. 백그라운드 isolate에서도 ensureInitialized()로 초기화해서 쓴다.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    await _openPayload(response.payload);
  }

  /// 앱이 꺼진 상태에서 알림을 눌러 앱이 켜진 경우, 그 알림의 기사를 연다.
  /// 이 경우에는 onDidReceiveNotificationResponse가 불리지 않아서
  /// 시작 직후에 직접 확인해야 한다. 한 번만 처리한다.
  bool _launchHandled = false;

  Future<void> handleLaunchNotification() async {
    if (_launchHandled) return;
    _launchHandled = true;
    await ensureInitialized();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return;
    await _openPayload(details.notificationResponse?.payload);
  }

  static Future<void> _openPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    final uri = Uri.tryParse(payload);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Android 13+ 알림 권한 요청. 이미 허용됐으면 아무 일도 안 한다.
  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  /// 알림 권한이 허용돼 있는지 확인. 꺼져 있으면 알림을 보내도 안 뜬다.
  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  Future<void> showNewsNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await ensureInitialized();
    const details = AndroidNotificationDetails(
      'news_alert_channel',
      '뉴스 알림',
      channelDescription: '키워드와 일치하는 새 뉴스가 올라오면 알려드립니다.',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: details),
      payload: payload,
    );
  }

  Future<void> showTestNotification() async {
    await showNewsNotification(
      id: 999999,
      title: '뉴스 알리미 테스트 알림',
      body: '알림이 정상적으로 동작합니다.',
    );
  }
}
