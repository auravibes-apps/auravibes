package me.auravibes.app

import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.Window
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyCaptionShade()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyCaptionShade()
    }

    private fun applyCaptionShade() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            val transparentCaptionBar =
                WindowInsetsController.APPEARANCE_TRANSPARENT_CAPTION_BAR_BACKGROUND
            val lightCaptionBars =
                WindowInsetsController.APPEARANCE_LIGHT_CAPTION_BARS
            window.insetsController?.setSystemBarsAppearance(
                transparentCaptionBar,
                transparentCaptionBar or lightCaptionBars,
            ) ?: window.setDecorCaptionShade(Window.DECOR_CAPTION_SHADE_LIGHT)
            return
        }

        window.setDecorCaptionShade(Window.DECOR_CAPTION_SHADE_LIGHT)
    }
}
