package com.example.chrono_list

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Color
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import java.io.File
import java.io.FileOutputStream

class OverlayService : AccessibilityService() {

    companion object {
        var instance: OverlayService? = null
            private set
    }

    data class TouchRecord(
        val x: Float,
        val y: Float,
        val timestamp: Long,
        val packageName: String,
        val eventType: String
    )

    private val touchEvents = mutableListOf<TouchRecord>()
    private var isRecording = false
    private var eventSink: EventChannel.EventSink? = null
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("OverlayService", "Accessibility Service connected")
        showPersistentActiveNotification()
    }

    fun showPersistentActiveNotification() {
        try {
            val channelId = "chrono_list_persistent_active"
            val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = android.app.NotificationChannel(
                    channelId,
                    "Background Active Service",
                    android.app.NotificationManager.IMPORTANCE_DEFAULT
                )
                channel.description = "Persistent background service for Chrono List task monitoring"
                notificationManager.createNotificationChannel(channel)
            }

            val builder = androidx.core.app.NotificationCompat.Builder(this, channelId)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("Chrono List is currently active")
                .setContentText("Monitoring scheduled task alarms & gesture automation")
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_DEFAULT)
                .setOngoing(true)

            notificationManager.notify(9999, builder.build())
        } catch (_: Exception) {}
    }

    override fun onUnbind(intent: Intent?): Boolean {
        removeFloatingOverlay()
        instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        removeFloatingOverlay()
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isRecording || event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED,
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED,
            AccessibilityEvent.TYPE_TOUCH_INTERACTION_START,
            AccessibilityEvent.TYPE_TOUCH_INTERACTION_END -> recordTouch(event)
            else -> { }
        }
    }

    private fun recordTouch(event: AccessibilityEvent) {
        val source: AccessibilityNodeInfo? = event.source
        if (source != null) {
            val rect = Rect()
            source.getBoundsInScreen(rect)
            val x = rect.centerX().toFloat()
            val y = rect.centerY().toFloat()
            val ts = System.currentTimeMillis()
            val pkg = event.packageName?.toString() ?: "unknown"
            val type = when (event.eventType) {
                AccessibilityEvent.TYPE_VIEW_CLICKED -> "CLICK"
                AccessibilityEvent.TYPE_VIEW_LONG_CLICKED -> "LONG_CLICK"
                AccessibilityEvent.TYPE_TOUCH_INTERACTION_START -> "TOUCH_START"
                AccessibilityEvent.TYPE_TOUCH_INTERACTION_END -> "TOUCH_END"
                else -> "UNKNOWN"
            }
            val record = TouchRecord(x, y, ts, pkg, type)
            touchEvents.add(record)
            Log.d("OverlayService", "Recorded $type at [$x,$y] in $pkg at $ts")

            eventSink?.success(mapOf(
                "x" to x,
                "y" to y,
                "timestamp" to ts,
                "packageName" to pkg,
                "eventType" to type
            ))
        }
    }

    override fun onInterrupt() { }

    fun startRecording() {
        isRecording = true
        touchEvents.clear()
        showFloatingOverlay()
        Log.d("OverlayService", "Recording started")
    }

    fun stopRecording() {
        isRecording = false
        removeFloatingOverlay()
        Log.d("OverlayService", "Recording stopped, total events: ${touchEvents.size}")
    }

    fun showFloatingOverlay() {
        if (overlayView != null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.w("OverlayService", "Overlay permission not granted!")
            return
        }
        try {
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

            val button = Button(this).apply {
                text = "⏹ STOP RECORDING"
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#D32F2F"))
                textSize = 16f
                setPadding(40, 24, 40, 24)
                setOnClickListener {
                    stopRecording()
                    saveTouchEventsToFile()
                    removeFloatingOverlay()

                    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        startActivity(launchIntent)
                    }
                }
            }

            val paramsType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                paramsType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                x = 0
                y = 150
            }

            windowManager?.addView(button, params)
            overlayView = button
            Log.d("OverlayService", "Floating overlay added to WindowManager at top center")
        } catch (e: Exception) {
            Log.e("OverlayService", "Failed to add floating overlay", e)
        }
    }

    fun removeFloatingOverlay() {
        try {
            if (overlayView != null && windowManager != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
            }
        } catch (e: Exception) {
            Log.e("OverlayService", "Failed to remove floating overlay", e)
        }
    }

    fun saveTouchEventsToFile(): String? {
        return try {
            val filename = "touch_${System.currentTimeMillis()}.json"
            val file = File(filesDir, filename)
            FileOutputStream(file).bufferedWriter().use { w ->
                w.write("[")
                touchEvents.forEachIndexed { i, t ->
                    w.write("""
                        {
                          "x":${t.x},
                          "y":${t.y},
                          "timestamp":${t.timestamp},
                          "package":"${t.packageName}",
                          "event":"${t.eventType}"
                        }${if (i < touchEvents.size - 1) "," else ""}
                    """.trimIndent())
                }
                w.write("]")
            }
            Log.d("OverlayService", "Saved to ${file.absolutePath}")
            file.absolutePath
        } catch (e: Exception) {
            Log.e("OverlayService", "Save failed", e)
            null
        }
    }

    private fun loadTouchEventsFromFile(filePath: String): List<TouchRecord> {
        return try {
            val file = File(filePath)
            if (!file.exists()) return emptyList()
            val jsonStr = file.readText()
            val list = mutableListOf<TouchRecord>()
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    TouchRecord(
                        x = obj.getDouble("x").toFloat(),
                        y = obj.getDouble("y").toFloat(),
                        timestamp = obj.getLong("timestamp"),
                        packageName = obj.optString("package", "unknown"),
                        eventType = obj.optString("event", "CLICK")
                    )
                )
            }
            list
        } catch (e: Exception) {
            Log.e("OverlayService", "Failed to load touches from $filePath", e)
            emptyList()
        }
    }

    fun performClickAt(x: Float, y: Float, callback: ((Boolean) -> Unit)? = null): Boolean {
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0, 100)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        return dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                callback?.invoke(true)
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                callback?.invoke(false)
            }
        }, null)
    }

    fun performHomeAction(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_HOME)
    }

    fun replayTouches(filePath: String? = null): Boolean {
        var eventsToReplay = touchEvents.toList()

        if (eventsToReplay.isEmpty() && !filePath.isNullOrEmpty()) {
            eventsToReplay = loadTouchEventsFromFile(filePath)
        }

        if (eventsToReplay.isEmpty()) {
            Log.w("OverlayService", "No touch events to replay")
            return false
        }

        val clicks = eventsToReplay.filter { it.eventType == "CLICK" || it.eventType == "TOUCH_START" }
        val records = if (clicks.isNotEmpty()) clicks else eventsToReplay

        Log.d("OverlayService", "Replaying ${records.size} gesture events...")
        val firstTimestamp = records.first().timestamp
        val handler = Handler(Looper.getMainLooper())

        for (touch in records) {
            val delay = (touch.timestamp - firstTimestamp).coerceAtLeast(0L)
            handler.postDelayed({
                performClickAt(touch.x, touch.y)
                Log.d("OverlayService", "Replayed click at [${touch.x}, ${touch.y}]")
            }, delay)
        }

        return true
    }
}
