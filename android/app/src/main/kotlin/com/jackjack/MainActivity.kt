package com.jackjack

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.jackjack/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        val intent =
                            Intent(this, BleForegroundService::class.java).apply {
                                putExtra(
                                    BleForegroundService.EXTRA_TITLE,
                                    call.argument<String>("title")
                                        ?: "Monitoring devices",
                                )
                                putExtra(
                                    BleForegroundService.EXTRA_TEXT,
                                    call.argument<String>("text")
                                        ?: "Listening for sound alerts",
                                )
                            }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stop" -> {
                    stopService(Intent(this, BleForegroundService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
