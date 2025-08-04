package com.example.chrono_list
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.view.*
import android.widget.ImageView
import android.widget.TextView

class FloatingTimerService : Service() {
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var startTime: Long = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        // Extra safety: Check overlay permission AGAIN at the service level!
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(this)) {
            stopSelf()
            return
        }
        startForegroundWithNotification()
        showFloatingView()
    }

    private fun startForegroundWithNotification() {
    val channelId = "overlay_timer_channel"
    val channelName = "Overlay Timer"
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = android.app.NotificationChannel(
            channelId,
            channelName,
            android.app.NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(android.app.NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    val notification = android.app.Notification.Builder(this, channelId)
        .setContentTitle("Recording Actions")
        .setContentText("Timer recording is active")
        .setSmallIcon(android.R.drawable.ic_menu_info_details)
        .setOngoing(true)
        .build()

    // NEW: Specify the foreground service type for Android 14+
    if (Build.VERSION.SDK_INT >= 34) {
        startForeground(
            1,
            notification,
            0x00004000
        )
    } else {
        startForeground(1, notification)
    }
}


    private fun showFloatingView() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        floatingView = LayoutInflater.from(this).inflate(R.layout.overlay_timer, null)

        val timerText = floatingView!!.findViewById<TextView>(R.id.timerText)
        startTime = System.currentTimeMillis()
        val handler = Handler(mainLooper)
        val updater = object : Runnable {
            override fun run() {
                val elapsed = (System.currentTimeMillis() - startTime) / 1000
                val min = elapsed / 60
                val sec = elapsed % 60
                timerText.text = String.format("%02d:%02d", min, sec)
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(updater)

        floatingView!!.findViewById<ImageView>(R.id.stopButton).setOnClickListener {
            handler.removeCallbacks(updater)
            stopSelf()
            // TODO: Optionally notify the Accessibility service to stop recording
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 50
        params.y = 100

        windowManager?.addView(floatingView, params)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (floatingView != null) windowManager?.removeView(floatingView)
    }
}
