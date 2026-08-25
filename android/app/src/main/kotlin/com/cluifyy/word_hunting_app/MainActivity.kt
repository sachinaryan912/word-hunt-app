package com.cluifyy.word_hunting_app

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Flutter's Dart-side SystemChrome call only drives the modern
    // WindowInsetsController appearance (icon brightness) on some OEM skins —
    // the legacy Window.navigationBarColor attribute it doesn't touch is what
    // the compositor actually paints behind the nav bar, so it must be set
    // here natively or the bar renders opaque black regardless of the Dart call.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }
}
