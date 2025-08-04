package com.example.chrono_list

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel                                                  // 〈CHANGE〉1
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "touch_recorder/methods"                                   // 〈CHANGE〉2: renamed channel
    private val EVENT_CHANNEL = "touch_recorder/events"                                    // 〈CHANGE〉2

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {           // 〈CHANGE〉3
        super.configureFlutterEngine(flutterEngine)

        // 〈CHANGE〉4: MethodChannel for controlling recording
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccessibilityPermission" -> {                                     // 〈CHANGE〉5
                        val enabled = isAccessibilityServiceEnabled()
                        result.success(enabled)
                    }
                    "requestAccessibilityPermission" -> {                                  // 〈CHANGE〉5
                        openAccessibilitySettings()
                        result.success(null)
                    }
                    "startRecording" -> {                                                  // 〈CHANGE〉6
                        val service = OverlayService.instance                              // See 〈CHANGE〉 in service to expose instance
                        if (service != null) {
                            service.startRecording()
                            result.success(true)
                        } else {
                            result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                        }
                    }
                    "stopRecording" -> {                                                  // 〈CHANGE〉6
                        val service = OverlayService.instance
                        if (service != null) {
                            service.stopRecording()
                            result.success(true)
                        } else {
                            result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                        }
                    }
                    "saveRecording" -> {                                                  // 〈CHANGE〉6
                        val service = OverlayService.instance
                        if (service != null) {
                            val path = service.saveTouchEventsToFile()
                            result.success(path)
                        } else {
                            result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                        }
                    }
                    "replayTouches" -> {                                                   // 〈CHANGE〉6
                        val service = OverlayService.instance
                        if (service != null) {
                            val success = service.replayTouches()
                            result.success(success)
                        } else {
                            result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 〈CHANGE〉7: EventChannel for streaming real-time touch events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    OverlayService.instance?.setEventSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    OverlayService.instance?.setEventSink(null)
                }
            })
    }

    // 〈CHANGE〉8: Helper to check if the accessibility service is enabled
    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${packageName}/${OverlayService::class.java.name}"
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabled?.contains(service) == true
    }

    // 〈CHANGE〉9: Open Accessibility Settings so user can enable your service
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
}
