package com.happyfamily.newsalarm

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // 배터리 최적화(절전) 확인·해제 요청 채널.
    // 최적화가 켜져 있으면 폰이 잠든 동안 백그라운드 확인이 몇 시간씩 미뤄져
    // 알림이 안 오고, 앱을 열어 '지금 확인'을 눌러야만 알림이 온다.
    private val batteryChannel = "com.happyfamily.newsalarm/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, batteryChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "requestIgnoreBatteryOptimizations" ->
                        result.success(requestIgnoreBatteryOptimizations())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    /// 시스템 '배터리 최적화 제외' 확인 창을 띄운다. 막힌 폰이면
    /// 배터리 최적화 목록 화면을, 그것도 안 되면 앱 정보 화면을 연다.
    private fun requestIgnoreBatteryOptimizations(): Boolean {
        val intents = listOf(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:$packageName")),
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:$packageName")),
        )
        for (intent in intents) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
            }
        }
        return false
    }
}
