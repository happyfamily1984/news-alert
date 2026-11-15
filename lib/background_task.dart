import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'services/news_check_service.dart';
import 'services/storage_service.dart';

const String kPeriodicTaskName = 'news-alarm-periodic-check';
const String kPeriodicTaskType = 'periodic-news-check';

/// WorkManager 백그라운드 콜백. 반드시 최상위 함수여야 한다.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await NewsCheckService.instance.runCheck(notify: true);
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// 저장된 주기(15/30/60분)로 주기 작업을 등록한다.
/// Android WorkManager 최소 간격이 15분이므로 그보다 짧게는 등록하지 않는다.
Future<void> registerPeriodicCheck() async {
  final interval = await StorageService.instance.getCheckIntervalMinutes();
  await Workmanager().registerPeriodicTask(
    kPeriodicTaskName,
    kPeriodicTaskType,
    frequency: Duration(minutes: interval),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
}
