package com.example.chrono_list

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs

class FloatingVolumeOverlay(private val context: Context) {

    companion object {
        var instance: FloatingVolumeOverlay? = null
            private set

        fun showOverlay(context: Context) {
            if (instance == null) {
                val overlay = FloatingVolumeOverlay(context.applicationContext)
                overlay.show()
            }
        }

        fun hideOverlay() {
            instance?.hide()
        }

        fun isOverlayShowing(): Boolean {
            return instance?.isShowing() == true
        }
    }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var expandedPanel: LinearLayout? = null
    private var txtVolume: TextView? = null
    private var isExpanded = false
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private var collapseRunnable: Runnable? = null

    fun show() {
        if (floatingView != null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            return
        }

        try {
            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            floatingView = buildOverlayView()

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
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 20
                y = 400
            }

            windowManager?.addView(floatingView, params)
            instance = this
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun hide() {
        try {
            cancelCollapseTimer()
            if (floatingView != null && windowManager != null) {
                windowManager?.removeView(floatingView)
                floatingView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            instance = null
        }
    }

    fun isShowing(): Boolean = floatingView != null

    private fun buildOverlayView(): View {
        val rootLayout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(10, 12, 10, 12)

            val background = GradientDrawable().apply {
                setColor(Color.parseColor("#EE1E293B")) // dark slate background
                cornerRadius = 45f
                setStroke(3, Color.parseColor("#3B82F6")) // vibrant blue border accent
            }
            setBackground(background)
            elevation = 16f
        }

        val mainIconButton = TextView(context).apply {
            text = "🔊"
            textSize = 22f
            gravity = Gravity.CENTER
            setPadding(10, 8, 10, 8)
            setTextColor(Color.WHITE)
        }

        val panel = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            visibility = View.GONE
        }
        expandedPanel = panel

        val btnUp = TextView(context).apply {
            text = "➕"
            textSize = 20f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(10, 10, 10, 10)
            setOnClickListener {
                adjustVolume(AudioManager.ADJUST_RAISE)
                resetCollapseTimer()
                updateVolumeText()
            }
        }

        val volText = TextView(context).apply {
            text = getVolumePercentText()
            textSize = 13f
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#38BDF8"))
            setPadding(4, 6, 4, 6)
        }
        txtVolume = volText

        val btnDown = TextView(context).apply {
            text = "➖"
            textSize = 20f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(10, 10, 10, 10)
            setOnClickListener {
                adjustVolume(AudioManager.ADJUST_LOWER)
                resetCollapseTimer()
                updateVolumeText()
            }
        }

        val btnMute = TextView(context).apply {
            text = "🔇"
            textSize = 18f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(10, 10, 10, 10)
            setOnClickListener {
                toggleMute()
                resetCollapseTimer()
                updateVolumeText()
            }
        }

        panel.addView(btnUp)
        panel.addView(volText)
        panel.addView(btnDown)
        panel.addView(btnMute)

        rootLayout.addView(mainIconButton)
        rootLayout.addView(panel)

        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isClick = true

        rootLayout.setOnTouchListener { view, event ->
            val params = view.layoutParams as WindowManager.LayoutParams
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isClick = true
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (abs(dx) > 10 || abs(dy) > 10) {
                        isClick = false
                        params.x = initialX + dx
                        params.y = initialY + dy
                        windowManager?.updateViewLayout(view, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (isClick) {
                        isExpanded = !isExpanded
                        expandedPanel?.visibility = if (isExpanded) View.VISIBLE else View.GONE
                        updateVolumeText()
                        if (isExpanded) {
                            resetCollapseTimer()
                        } else {
                            cancelCollapseTimer()
                        }
                    }
                    true
                }
                else -> false
            }
        }

        return rootLayout
    }

    fun adjustVolume(direction: Int) {
        try {
            audioManager?.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                direction,
                AudioManager.FLAG_SHOW_UI
            )
            audioManager?.adjustStreamVolume(
                AudioManager.STREAM_RING,
                direction,
                0
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun toggleMute() {
        try {
            audioManager?.let { am ->
                val currentVol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                if (currentVol > 0) {
                    am.setStreamVolume(AudioManager.STREAM_MUSIC, 0, AudioManager.FLAG_SHOW_UI)
                } else {
                    val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    am.setStreamVolume(AudioManager.STREAM_MUSIC, maxVol / 2, AudioManager.FLAG_SHOW_UI)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getVolumePercentText(): String {
        return try {
            val curr = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
            val max = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 100
            val pct = if (max > 0) (curr * 100 / max) else 0
            "$pct%"
        } catch (e: Exception) {
            "Vol"
        }
    }

    private fun updateVolumeText() {
        txtVolume?.text = getVolumePercentText()
    }

    private fun resetCollapseTimer() {
        cancelCollapseTimer()
        collapseRunnable = Runnable {
            isExpanded = false
            expandedPanel?.visibility = View.GONE
        }
        mainHandler.postDelayed(collapseRunnable!!, 4000)
    }

    private fun cancelCollapseTimer() {
        collapseRunnable?.let { mainHandler.removeCallbacks(it) }
        collapseRunnable = null
    }
}
