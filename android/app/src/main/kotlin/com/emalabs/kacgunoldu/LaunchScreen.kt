package com.emalabs.kacgunoldu

import android.animation.ValueAnimator
import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.AnimatedVectorDrawable
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView

/**
 * The launch screen's picture: the colour theme's launch colour with the app
 * icon's mark (a ring and a question mark) in the middle - animated
 * (avd_splash_mark, started with [play]) or finished and still
 * (ic_splash_mark).
 *
 * SplashActivity and MainActivity both show it, one after the other, and the
 * hand-over must not move a pixel: so it always covers the whole window
 * (added to the decor view, not the content area, whose size differs between
 * the two) and the system bars are set the same way in both.
 */
object LaunchScreen {
    /** The mark's canvas (ic_splash_mark.xml). */
    private const val ICON_DP = 288

    /**
     * Length of avd_splash_mark (ring 1000ms, mark 600 + 800ms). Android
     * plays it at the phone's animator speed (Developer options can halve
     * it); [remainingMs] accounts for that.
     */
    const val ANIMATION_MS = 1400L

    /** The saved colour theme's launch colour (the default on a first launch). */
    fun colour(activity: Activity): Int {
        // Flutter's shared_preferences keeps the theme id under a "flutter."
        // prefix.
        val themeId = activity.getSharedPreferences("FlutterSharedPreferences", Activity.MODE_PRIVATE)
            .getString("flutter.nezaman.theme.v1", null) ?: "kiremit"
        var res = activity.resources.getIdentifier("launch_$themeId", "color", activity.packageName)
        if (res == 0) res = R.color.launch_kiremit
        return activity.getColor(res)
    }

    /**
     * Status bar see-through, navigation bar in the launch colour - no black
     * strip under the picture. Call before `super.onCreate`, so the very
     * first frame already has them.
     */
    fun prepareWindow(activity: Activity, paintNavigationBar: Boolean = false) {
        val window = activity.window
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        // Edge to edge, with both bars see-through: the picture (which covers
        // the whole window) shows under them in the launch colour. Colouring
        // the navigation bar instead does not work for SplashActivity's
        // translucent window - Android leaves that bar black.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        window.statusBarColor = Color.TRANSPARENT
        // MainActivity paints the bar itself in the launch colour: its window
        // (FlutterActivity's) showed a black bar through a transparent one.
        window.navigationBarColor = if (paintNavigationBar) colour(activity) else Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // No grey scrim the system would otherwise add for contrast.
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
    }

    /** Puts the picture over the whole window and returns it. */
    fun attach(activity: Activity, animated: Boolean): FrameLayout {
        val drawable = activity.getDrawable(if (animated) R.drawable.avd_splash_mark else R.drawable.ic_splash_mark)
        val size = (ICON_DP * activity.resources.displayMetrics.density).toInt()
        val root = FrameLayout(activity).apply {
            setBackgroundColor(colour(activity))
            isClickable = true // swallow touches
            addView(
                ImageView(activity).apply { setImageDrawable(drawable) },
                FrameLayout.LayoutParams(size, size, Gravity.CENTER),
            )
        }
        (activity.window.decorView as ViewGroup).addView(
            root,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        return root
    }

    /** When the animation last started (uptime ms); 0 if it never did. */
    private var playedAt = 0L

    /** Plays the animation from its start (again, if it already ran). */
    fun play(root: FrameLayout) {
        val avd = (root.getChildAt(0) as? ImageView)?.drawable as? AnimatedVectorDrawable ?: return
        avd.reset()
        avd.start()
        playedAt = SystemClock.uptimeMillis()
    }

    /**
     * How long until the animation has finished and been held on screen for
     * [holdMs] - measured from when it really started, in the phone's own
     * animation speed (Developer options can halve or slow it).
     */
    fun remainingMs(holdMs: Long): Long {
        if (playedAt == 0L) return 0
        val length = (ANIMATION_MS * ValueAnimator.getDurationScale()).toLong()
        return (length + holdMs - (SystemClock.uptimeMillis() - playedAt)).coerceAtLeast(0)
    }
}
