package com.example.chrono_list

import android.accessibilityservice.AccessibilityService                                       // 〈CHANGE〉1: Use AccessibilityService
import android.accessibilityservice.AccessibilityService.GestureResultCallback              // 〈CHANGE〉1
import android.graphics.Path                                                                  // 〈CHANGE〉1
import android.view.accessibility.AccessibilityEvent                                          // 〈CHANGE〉1
import android.view.accessibility.AccessibilityNodeInfo                                      // 〈CHANGE〉1
import android.util.Log
import java.io.File
import java.io.FileOutputStream

class OverlayService : AccessibilityService() {                                               // 〈CHANGE〉1: Extend AccessibilityService
    // 1. Remove WindowManager/floatingButton logic entirely—AccessibilityService runs in background.

    // 〈CHANGE〉2: Data class now includes packageName and eventType
    data class TouchRecord(
        val x: Float,
        val y: Float,
        val timestamp: Long,
        val packageName: String,
        val eventType: String
    )

    private val touchEvents = mutableListOf<TouchRecord>()
    private var isRecording = false                                                           // 〈CHANGE〉2: recording flag as before

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("OverlayService", "Accessibility Service connected")                             // 〈CHANGE〉3: service start log
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isRecording || event == null) return                                             // 〈CHANGE〉4: only record when flag true

        // 〈CHANGE〉5: filter relevant event types
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED,
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED,
            AccessibilityEvent.TYPE_TOUCH_INTERACTION_START,
            AccessibilityEvent.TYPE_TOUCH_INTERACTION_END -> recordTouch(event)
            else -> { /* ignore others */ }
        }
    }

    private fun recordTouch(event: AccessibilityEvent) {                                       // 〈CHANGE〉6: central recording logic
        val source: AccessibilityNodeInfo? = event.source
        source?.getBoundsInScreen(android.graphics.Rect()).let { rect ->
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
            touchEvents.add(TouchRecord(x, y, ts, pkg, type))
            Log.d("OverlayService", "Recorded $type at [$x,$y] in $pkg at $ts")               // 〈CHANGE〉6
        }
    }

    override fun onInterrupt() {
        // Required override—no action needed
    }

    /** 〈CHANGE〉7: public methods to start/stop/save **/
    fun startRecording() {
        isRecording = true
        touchEvents.clear()
        Log.d("OverlayService", "Recording started")
    }

    fun stopRecording() {
        isRecording = false
        Log.d("OverlayService", "Recording stopped, total events: ${touchEvents.size}")
    }

    fun saveTouchEventsToFile(): Boolean {
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
                        }${if (i < touchEvents.size -1) "," else ""}
                    """.trimIndent())
                }
                w.write("]")
            }
            Log.d("OverlayService", "Saved to ${file.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e("OverlayService", "Save failed", e)
            false
        }
    }
}
