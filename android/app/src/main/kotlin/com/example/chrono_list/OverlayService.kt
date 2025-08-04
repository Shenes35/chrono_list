package com.example.chrono_list

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.Toast
import java.io.File
import java.io.FileOutputStream

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var floatingButton: View? = null
    private var isRecording = false

    // Data class to hold touch records
    data class TouchRecord(val x: Float, val y: Float, val timestamp: Long)

    // List to store recorded touch events
    private val touchEvents = mutableListOf<TouchRecord>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()

        // Foreground service block for Android O+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "overlay_service_channel"
            val channelName = "Overlay Service"
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(channelId) == null) {
                val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
                manager.createNotificationChannel(channel)
            }
            val notification = Notification.Builder(this, channelId)
                .setContentTitle("Overlay Running")
                .setContentText("Overlay button is active")
                .setSmallIcon(android.R.drawable.ic_menu_view)
                .build()
            startForeground(1, notification)
        }

        // Initialize WindowManager and inflate the overlay layout
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        floatingButton = LayoutInflater.from(this).inflate(R.layout.overlay_button_with_save, null)

        // LayoutParams for overlay window
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.END
        params.x = 30
        params.y = 130

        // Find buttons inside the overlay view:
        val recordButton = floatingButton?.findViewById<Button>(R.id.btn_overlay_record)
        val saveButton = floatingButton?.findViewById<Button>(R.id.btn_overlay_save)

        recordButton?.text = "Start"

        // Start/Stop recording toggle
        recordButton?.setOnClickListener {
            isRecording = !isRecording
            if (isRecording) {
                recordButton.text = "Stop"
                Toast.makeText(this, "Recording started!", Toast.LENGTH_SHORT).show()
                touchEvents.clear()
            } else {
                recordButton.text = "Start"
                Toast.makeText(this, "Recording stopped!", Toast.LENGTH_SHORT).show()
                // Optionally log recorded touches for debug
                touchEvents.forEach { touch ->
                    Log.d("OverlayService", "Touch at x=${touch.x}, y=${touch.y}, time=${touch.timestamp}")
                }
            }
        }

        // Save button writes recorded events to a file
        saveButton?.setOnClickListener {
            if (touchEvents.isEmpty()) {
                Toast.makeText(this, "No recorded touches to save!", Toast.LENGTH_SHORT).show()
            } else {
                val success = saveTouchEventsToFile()
                if (success) {
                    Toast.makeText(this, "Touch recording saved.", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(this, "Failed to save touch recording.", Toast.LENGTH_SHORT).show()
                }
            }
        }

        // Record touch events on the overlay view while recording is active
        floatingButton?.setOnTouchListener { _, event ->
            if (isRecording && event.action == MotionEvent.ACTION_DOWN) {
                val x = event.rawX
                val y = event.rawY
                val timestamp = System.currentTimeMillis()
                touchEvents.add(TouchRecord(x, y, timestamp))
                Log.d("OverlayService", "Recorded touch at: x=$x, y=$y, time=$timestamp")
            }
            // Let touch events pass through (important for button clicks)
            false
        }

        floatingButton?.let { windowManager?.addView(it, params) }
    }

    override fun onDestroy() {
        super.onDestroy()
        floatingButton?.let { windowManager?.removeView(it) }
        floatingButton = null
    }

    private fun saveTouchEventsToFile(): Boolean {
        return try {
            val filename = "touch_recordings_${System.currentTimeMillis()}.txt"
            val file = File(filesDir, filename)
            FileOutputStream(file).bufferedWriter().use { writer ->
                writer.write("Touch events recording\n")
                writer.write("Format: x, y, timestamp\n\n")
                for (touch in touchEvents) {
                    writer.write("${touch.x},${touch.y},${touch.timestamp}\n")
                }
            }
            Log.d("OverlayService", "Saved touch events to ${file.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e("OverlayService", "Error saving touch events: ${e.localizedMessage}", e)
            false
        }
    }
}
