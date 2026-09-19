package com.emalabs.kacgunoldu

import android.os.Build
import android.os.Bundle
import android.view.ViewGroup
import android.widget.FrameLayout
import com.emalabs.kacgunoldu.widget.WidgetSnapshot
import com.emalabs.kacgunoldu.widget.WidgetViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var launchView: FrameLayout? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        running = true
        LaunchScreen.prepareWindow(this, paintNavigationBar = true)
        super.onCreate(savedInstanceState)
        // Again: FlutterActivity's own set-up changes the window's bars, and
        // the navigation bar went black under the launch view.
        LaunchScreen.prepareWindow(this, paintNavigationBar = true)
        showLaunchView()
    }

    override fun onPostResume() {
        super.onPostResume()
        // FlutterActivity re-applies its system UI here too; keep the bars
        // see-through for as long as the launch view is up.
        if (launchView != null) LaunchScreen.prepareWindow(this, paintNavigationBar = true)
    }

    override fun onDestroy() {
        running = false
        WidgetViews.onPinned = null
        super.onDestroy()
    }

    /**
     * The finished logo on the launch colour, laid over the (still empty)
     * Flutter view: SplashActivity's animation has been playing underneath
     * while this activity started, and this looks the same, so the hand-over
     * is invisible. When the app reports its first frame it fades away.
     */
    private fun showLaunchView() {
        val root = LaunchScreen.attach(this, animated = false)
        launchView = root
        // Safety net: never leave the logo covering a dead app.
        root.postDelayed({ reveal(null) }, GIVE_UP_MS)
    }

    /** Waits out the animation if it hasn't finished, then fades the view away. */
    private fun reveal(done: MethodChannel.Result?) {
        val view = launchView
        if (view == null) {
            done?.success(null)
            return
        }
        launchView = null
        val wait = LaunchScreen.remainingMs(HOLD_MS)
        view.postDelayed({
            view.animate().alpha(0f).setDuration(FADE_MS).withEndAction {
                (view.parent as? ViewGroup)?.removeView(view)
                done?.success(null)
            }.start()
        }, wait)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // The app drew its first frame: lift the animation. The
                    // reply comes when it is gone.
                    "ready" -> reveal(result)
                    // The app's colour theme decides the launch screen's
                    // colour. Android only lets the system launch screen's be
                    // chosen ahead of time, so each change is reported and it
                    // applies from the next launch (Android 13+).
                    "setTheme" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            // Resource names keep the dot ("LaunchTheme.Okyanus");
                            // only the R class turns it into an underscore.
                            val name = "LaunchTheme." + (call.arguments as? String ?: "")
                            val style = resources.getIdentifier(name, "style", packageName)
                            if (style != 0) splashScreen.setSplashScreenTheme(style)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // The home screen widgets (lib/services/home_widgets.dart): their
        // snapshot, the days marked on them, and placing one from the app.
        val widgets = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGETS_CHANNEL)
        WidgetViews.onPinned = { widgets.invokeMethod("pinned", null) }
        widgets
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publish" -> {
                        (call.arguments as? String)?.let { WidgetSnapshot.save(this, it) }
                        WidgetViews.refreshAll(this)
                        result.success(null)
                    }
                    // Days marked with a widget's "Bugün yaptım", for CardStore.
                    "takeMarks" -> result.success(WidgetSnapshot.takeMarks(this))
                    "canPin" -> result.success(WidgetViews.canPin(this))
                    // "Ana ekrana ekle": the launcher asks the person to confirm.
                    "pin" -> result.success(
                        WidgetViews.pin(this, call.argument<String>("cardId"), call.argument<Boolean>("list") == true),
                    )
                    // The permission MIUI keeps once its dialog is refused.
                    "openPinPermission" -> {
                        WidgetViews.openPinPermission(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        /** True while a MainActivity exists - the app is already running. */
        @Volatile
        var running = false

        private const val CHANNEL = "kac_gun_oldu/launch"
        private const val WIDGETS_CHANNEL = "kac_gun_oldu/widgets"

        /** A beat on the finished mark before the app is revealed. */
        private const val HOLD_MS = 500L
        private const val FADE_MS = 220L
        private const val GIVE_UP_MS = 20_000L
    }
}
