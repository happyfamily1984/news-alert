import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'services/news_check_service.dart';
import 'services/storage_service.dart';

const String kPeriodicTaskName = 'news-alarm-periodic-check';
const String kPeriodicTaskType = 'periodic-news-check';

/// WorkManager 백그라운드 콜백. 반드시 최상위 함수여야 한다.
/// 돌 때마다 시각과 결과를 남겨서, 알림이 안 올 때 자동 확인이
/// 아예 안 도는 건지(폰 절전) 돌았는데 새 기사가 없던 건지 구분할 수 있게 한다.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final startedAt = DateTime.now();
    try {
      final result = await NewsCheckService.instance.runCheck(notify: true);
      if (result.allFailed) {
        await _logRun(startedAt, '실패: 뉴스 서버에 연결하지 못함');
        return false; // WorkManager가 잠시 뒤 다시 시도한다.
      }
      final count = result.newArticles.length;
      await _logRun(startedAt, count == 0 ? '새 뉴스 없음' : '새 뉴스 $count건');
      return true;
    } catch (e) {
      await _logRun(startedAt, '실패: $e');
      return false;
    }
  });
}

Future<void> _logRun(DateTime at, String result) async {
  try {
    await StorageService.instance.setBackgroundRun(at, result);
  } catch (_) {}
}

/// 저장된 주기(15/30/60분)로 주기 작업을 등록한다.
/// Android WorkManager 최소 간격이 15분이므로 그보다 짧게는 등록하지 않는다.
///
/// 정책은 update: 이미 등록된 작업의 다음 실행 일정은 그대로 두고 주기만
/// 바꾼다. 예전에는 replace라서 앱을 열 때마다 작업을 지우고 새로 만들어
/// 15분 타이머가 매번 처음부터 다시 시작됐다.
Future<void> registerPeriodicCheck() async {
  final interval = await StorageService.instance.getCheckIntervalMinutes();
  await Workmanager().registerPeriodicTask(
    kPeriodicTaskName,
    kPeriodicTaskType,
    frequency: Duration(minutes: interval),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}
