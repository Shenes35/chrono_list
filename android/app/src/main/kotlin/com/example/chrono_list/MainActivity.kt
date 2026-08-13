package com.example.chrono_list

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "touch_recorder/methods"
    private val RECORDER_CHANNEL = "your.plugin/recorder"
    private val EVENT_CHANNEL = "touch_recorder/events"
    private var currentRingtone: android.media.Ringtone? = null
    private var mediaPlayer: android.media.MediaPlayer? = null
    private var toneGenerator: android.media.ToneGenerator? = null
    private var activeVibrator: android.os.Vibrator? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        showPersistentActiveNotification()

        val handler = MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "startPersistentService" -> {
                    showPersistentActiveNotification()
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    val enabled = isAccessibilityServiceEnabled()
                    result.success(enabled)
                }
                "requestAccessibilityPermission" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    result.success(isOverlayPermissionGranted())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "toggleVolumeOverlay" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    if (enable) {
                        if (!isOverlayPermissionGranted()) {
                            requestOverlayPermission()
                            result.error("OVERLAY_PERMISSION_REQUIRED", "Overlay permission required", null)
                            return@MethodCallHandler
                        }
                        FloatingVolumeOverlay.showOverlay(this)
                        result.success(true)
                    } else {
                        FloatingVolumeOverlay.hideOverlay()
                        result.success(false)
                    }
                }
                "isVolumeOverlayShowing" -> {
                    result.success(FloatingVolumeOverlay.isOverlayShowing())
                }
                "adjustSystemVolume" -> {
                    val action = call.argument<String>("action") ?: "up"
                    val audioManager = getSystemService(android.content.Context.AUDIO_SERVICE) as? android.media.AudioManager
                    if (audioManager != null) {
                        when (action) {
                            "up" -> {
                                audioManager.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_RAISE, android.media.AudioManager.FLAG_SHOW_UI)
                            }
                            "down" -> {
                                audioManager.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_LOWER, android.media.AudioManager.FLAG_SHOW_UI)
                            }
                            "mute" -> {
                                val curr = audioManager.getStreamVolume(android.media.AudioManager.STREAM_MUSIC)
                                if (curr > 0) {
                                    audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, 0, android.media.AudioManager.FLAG_SHOW_UI)
                                } else {
                                    val max = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                                    audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, max / 2, android.media.AudioManager.FLAG_SHOW_UI)
                                }
                            }
                        }
                        result.success(true)
                    } else {
                        result.error("AUDIO_UNAVAILABLE", "Audio service not available", null)
                    }
                }
                "showOverlayButton", "startRecording" -> {
                    if (!isOverlayPermissionGranted()) {
                        requestOverlayPermission()
                        result.error("OVERLAY_PERMISSION_REQUIRED", "Overlay permission required", null)
                        return@MethodCallHandler
                    }
                    val service = OverlayService.instance
                    if (service != null) {
                        service.startRecording()
                        result.success(true)
                    } else {
                        openAccessibilitySettings()
                        result.error("SERVICE_UNAVAILABLE", "Accessibility service not enabled", null)
                    }
                }
                "stopRecording" -> {
                    val service = OverlayService.instance
                    if (service != null) {
                        service.stopRecording()
                        result.success(true)
                    } else {
                        result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                    }
                }
                "saveRecording" -> {
                    val service = OverlayService.instance
                    if (service != null) {
                        val path = service.saveTouchEventsToFile()
                        result.success(path)
                    } else {
                        result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                    }
                }
                "replayTouches" -> {
                    val service = OverlayService.instance
                    val filePath = call.argument<String>("filePath")
                    val packageName = call.argument<String>("packageName")

                    if (service != null) {
                        if (!packageName.isNullOrEmpty()) {
                            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                            if (launchIntent != null) {
                                startActivity(launchIntent)
                            }
                        }
                        Handler(Looper.getMainLooper()).postDelayed({
                            val success = service.replayTouches(filePath)
                            result.success(success)
                        }, 2000)
                    } else {
                        result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                    }
                }
                "performClickAt" -> {
                    val service = OverlayService.instance
                    val x = call.argument<Double>("x")?.toFloat() ?: 500f
                    val y = call.argument<Double>("y")?.toFloat() ?: 1000f
                    if (service != null) {
                        val success = service.performClickAt(x, y)
                        result.success(success)
                    } else {
                        result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                    }
                }
                "performHome" -> {
                    val service = OverlayService.instance
                    if (service != null) {
                        val success = service.performHomeAction()
                        result.success(success)
                    } else {
                        result.error("SERVICE_UNAVAILABLE", "Accessibility service not connected", null)
                    }
                }
                "performAppSequence" -> {
                    val service = OverlayService.instance
                    val packageName = call.argument<String>("packageName")
                    val x = call.argument<Double>("x")?.toFloat()
                    val y = call.argument<Double>("y")?.toFloat()
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 2

                    if (packageName.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                        return@MethodCallHandler
                    }

                    try {
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            startActivity(launchIntent)

                            Handler(Looper.getMainLooper()).postDelayed({
                                if (service != null) {
                                    if (x != null && y != null) {
                                        service.performClickAt(x, y)
                                    } else {
                                        service.replayTouches()
                                    }
                                }
                            }, (delaySeconds * 1000).toLong())

                            result.success(true)
                        } else {
                            result.error("APP_NOT_FOUND", "Could not find app $packageName", null)
                        }
                    } catch (e: Exception) {
                        result.error("EXECUTION_ERROR", e.message, null)
                    }
                }
                "playAlarmSound" -> {
                    val soundType = call.argument<String>("soundType") ?: "Default Alarm"
                    val durationSec = call.argument<Int>("durationSeconds") ?: 5
                    val volumeRatio = call.argument<Double>("volume") ?: 0.8
                    val durationMs = (durationSec * 1000).toLong()

                    try {
                        currentRingtone?.stop()
                        currentRingtone = null
                        try { activeVibrator?.cancel() } catch (_: Exception) {}

                        // Set stream volume based on slider
                        try {
                            val audioManager = getSystemService(android.content.Context.AUDIO_SERVICE) as? android.media.AudioManager
                            if (audioManager != null) {
                                val maxAlarm = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
                                val alarmVol = (maxAlarm * volumeRatio).toInt().coerceIn(1, maxAlarm)
                                audioManager.setStreamVolume(android.media.AudioManager.STREAM_ALARM, alarmVol, 0)

                                val maxMusic = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                                val musicVol = (maxMusic * volumeRatio).toInt().coerceIn(1, maxMusic)
                                audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, musicVol, 0)
                            }
                        } catch (_: Exception) {}

                        if (soundType == "Silent") {
                            result.success(true)
                            return@MethodCallHandler
                        }

                        // Start repeating vibration pattern
                        try {
                            val vibrator = getSystemService(android.content.Context.VIBRATOR_SERVICE) as? android.os.Vibrator
                            if (vibrator != null) {
                                activeVibrator = vibrator
                                val pattern = longArrayOf(0, 500, 250, 500, 250)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    vibrator.vibrate(android.os.VibrationEffect.createWaveform(pattern, 0))
                                } else {
                                    @Suppress("DEPRECATION")
                                    vibrator.vibrate(pattern, 0)
                                }
                            }
                        } catch (_: Exception) {}

                        if (soundType == "Vibration Only") {
                            Handler(Looper.getMainLooper()).postDelayed({
                                try { activeVibrator?.cancel() } catch (_: Exception) {}
                            }, durationMs)
                            result.success(true)
                            return@MethodCallHandler
                        }

                        // Play System Ringtone / Alarm tone using RingtoneManager
                        val ringtoneType = when (soundType) {
                            "Digital Chime (Short Beep)" -> android.media.RingtoneManager.TYPE_NOTIFICATION
                            "Gentle Bell (Ringtone)" -> android.media.RingtoneManager.TYPE_RINGTONE
                            "Loud Siren (Emergency)", "Default Alarm Sound" -> android.media.RingtoneManager.TYPE_ALARM
                            else -> android.media.RingtoneManager.TYPE_ALARM
                        }

                        val alarmUri = android.media.RingtoneManager.getDefaultUri(ringtoneType)
                        val ringtone = android.media.RingtoneManager.getRingtone(applicationContext, alarmUri)
                        if (ringtone != null) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                ringtone.audioAttributes = android.media.AudioAttributes.Builder()
                                    .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                    .build()
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                ringtone.volume = volumeRatio.toFloat()
                            }
                            ringtone.play()
                            currentRingtone = ringtone
                        }

                        // Distinct ToneGenerator sound signature
                        try {
                            val volumeInt = (volumeRatio * 100).toInt().coerceIn(10, 100)
                            toneGenerator?.release()
                            toneGenerator = android.media.ToneGenerator(android.media.AudioManager.STREAM_ALARM, volumeInt)
                            val toneType = when (soundType) {
                                "Digital Chime (Short Beep)" -> android.media.ToneGenerator.TONE_PROP_BEEP2
                                "Gentle Bell (Ringtone)" -> android.media.ToneGenerator.TONE_SUP_CONFIRM
                                "Loud Siren (Emergency)" -> android.media.ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK
                                else -> android.media.ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD
                            }
                            toneGenerator?.startTone(toneType, durationMs.toInt().coerceAtMost(5000))
                        } catch (_: Exception) {}

                        // Schedule auto-stop after exact durationSec
                        Handler(Looper.getMainLooper()).postDelayed({
                            try {
                                if (currentRingtone == ringtone) {
                                    ringtone?.stop()
                                }
                                activeVibrator?.cancel()
                            } catch (_: Exception) {}
                        }, durationMs)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.message, null)
                    }
                }
                "stopAlarmSound" -> {
                    try {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                        mediaPlayer = null
                        currentRingtone?.stop()
                        currentRingtone = null
                        activeVibrator?.cancel()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.message, null)
                    }
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Chrono List Task"
                    val message = call.argument<String>("message") ?: "Upcoming task reminder"
                    showSystemNotification(title, message)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler(handler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECORDER_CHANNEL).setMethodCallHandler(handler)

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

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${packageName}/${OverlayService::class.java.name}"
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabled?.contains(service) == true
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun isOverlayPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun showSystemNotification(title: String, message: String) {
        try {
            val channelId = "chrono_list_notifications"
            val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = android.app.NotificationChannel(
                    channelId,
                    "Task Notifications",
                    android.app.NotificationManager.IMPORTANCE_HIGH
                )
                channel.description = "Notifications for upcoming scheduled tasks"
                notificationManager.createNotificationChannel(channel)
            }

            val builder = androidx.core.app.NotificationCompat.Builder(this, channelId)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle(title)
                .setContentText(message)
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)

            notificationManager.notify((System.currentTimeMillis() % 10000).toInt(), builder.build())
        } catch (_: Exception) {}
    }

    private fun showPersistentActiveNotification() {
        try {
            val channelId = "chrono_list_persistent_active"
            val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = android.app.NotificationChannel(
                    channelId,
                    "Background Active Service",
                    android.app.NotificationManager.IMPORTANCE_LOW
                )
                channel.description = "Persistent background service for Chrono List task monitoring"
                notificationManager.createNotificationChannel(channel)
            }

            val builder = androidx.core.app.NotificationCompat.Builder(this, channelId)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("Chrono List is currently active")
                .setContentText("Monitoring scheduled task alarms & gesture automation")
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)

            notificationManager.notify(9999, builder.build())
        } catch (_: Exception) {}
    }
}
