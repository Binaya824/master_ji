package com.omrparser.master_ji

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "masterji/device_id"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidId") {
                try {
                    result.success(
                        Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ANDROID_ID
                        )
                    )
                } catch (e: Exception) {
                    result.error("ANDROID_ID_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
