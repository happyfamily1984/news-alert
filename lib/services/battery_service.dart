import 'package:flutter/services.dart';

/// 배터리 최적화(절전) 상태 확인·해제 요청. 안드로이드 MainActivity와 통신한다.
///
/// 최적화가 켜져 있으면 폰이 잠든 동안 WorkManager 백그라운드 확인이
/// 몇 시간씩 미뤄져서 알림이 제때 오지 않는다.
class BatteryService {
  BatteryService._();

  static final BatteryService instance = BatteryService._();

  static const _channel = MethodChannel('com.happyfamily.newsalarm/battery');

  /// 이 앱이 배터리 최적화에서 제외돼 있으면 true.
  /// 확인할 수 없는 환경(테스트 등)에서는 true로 보고 안내를 띄우지 않는다.
  Future<bool> isIgnoringOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          true;
    } catch (_) {
      return true;
    }
  }

  /// 이 앱의 '앱 정보' 화면을 연다 (배터리 → 제한 없음). 화면을 열었으면 true.
  Future<bool> requestIgnoreOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'requestIgnoreBatteryOptimizations',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
