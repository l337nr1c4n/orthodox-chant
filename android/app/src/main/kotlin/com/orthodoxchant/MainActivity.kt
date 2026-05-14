package com.orthodoxchant

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.orthodoxchant/audio",
        ).setMethodCallHandler { call, result ->
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            when (call.method) {
                // Route audio to earpiece — keeps speaker far from mic, kills AEC echo loop
                "setModeCommunication" -> {
                    am.mode = AudioManager.MODE_IN_COMMUNICATION
                    result.success(null)
                }
                "setModeNormal" -> {
                    am.mode = AudioManager.MODE_NORMAL
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
