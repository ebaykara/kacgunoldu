package com.emalabs.kacgunoldu

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.ViewTreeObserver
import android.widget.FrameLayout

/**
 * The app's front door. FlutterActivity's start-up (loading the engine)
 * blocks the main thread for a second or more, and nothing can be drawn
 * until it finishes - so a launch animation inside MainActivity is only ever
 * seen after everything is ready. This activity has nothing to load: it
 * plays the animated logo, then starts MainActivity. The animation keeps
 * running on the render thread while MainActivity blocks the main one, and
 * MainActivity's own launch view (the finished logo, same colour, same
 * place) takes over seamlessly.
 *
 * Its theme is translucent, which means Android shows no launch screen of its
 * own for it: the first thing on screen is this animation. (A system launch
 * screen first meant a plain field of colour - darkened by some phones in
 * dark mode - and then the animation: two screens instead of one.)
 */
class SplashActivity : Activity() {
    private lateinit var root: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        LaunchScreen.prepareWindow(this)
        super.onCreate(savedInstanceState)

        // The app is already running (a notification tapped while it is
        // open): no animation, straight to it.
        if (MainActivity.running) {
            openApp()
            return
        }

        root = LaunchScreen.attach(this, animated = true)

        // Start when the picture is first drawn, then hand over once those
        // first frames are on screen.
        root.viewTreeObserver.addOnPreDrawListener(object : ViewTreeObserver.OnPreDrawListener {
            override fun onPreDraw(): Boolean {
                root.viewTreeObserver.removeOnPreDrawListener(this)
                LaunchScreen.play(root)
                root.postDelayed({ openApp() }, FIRST_FRAMES_MS)
                return true
            }
        })

        // Should a phone show a system launch screen anyway, it goes at
        // once and the animation starts over, so none of it plays unseen.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { systemSplash ->
                systemSplash.remove()
                LaunchScreen.play(root)
            }
        }
    }

    private fun openApp() {
        // What launched us (a notification's action and payload, for
        // instance) is passed on - but NOT its flags. A launcher intent
        // carries FLAG_ACTIVITY_NEW_TASK; copied along, it started
        // MainActivity in a second task: two entries in Recents, and Android
        // showing a fresh launch screen for it (the "cut and reopen").
        // CLEAR_TOP + SINGLE_TOP: if the app is already running, its one
        // MainActivity gets the intent (onNewIntent) instead of a second copy.
        val next = Intent(this, MainActivity::class.java).apply {
            action = intent.action
            data = intent.data
            intent.extras?.let { putExtras(it) }
            addFlags(
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION,
            )
        }
        startActivity(next)
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    private companion object {
        /** Lets the first frames reach the screen before the engine starts. */
        const val FIRST_FRAMES_MS = 120L
    }
}
