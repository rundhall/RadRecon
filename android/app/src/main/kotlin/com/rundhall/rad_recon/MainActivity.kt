package com.rundhall.rad_recon

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A telefon hangerő gombjai és a Bluetooth-os média gombok billentyű-
 * eseményként az előtérben lévő Activity-hez érkeznek. Itt továbbítjuk őket
 * a Dartnak, ahol a gombhoz rendelt parancs fut. A Dart mondja meg, melyik
 * gombot nyelje el az app; a "nincs" parancsú gomb rendszer-viselkedésű marad.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val handled = mutableSetOf<String>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val c = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        c.setMethodCallHandler { call, result ->
            when (call.method) {
                "setHandled" -> {
                    handled.clear()
                    (call.arguments as? List<*>)?.forEach { if (it is String) handled.add(it) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        channel = c
    }

    private fun nameOf(code: Int): String? = when (code) {
        KeyEvent.KEYCODE_VOLUME_UP -> "volumeUp"
        KeyEvent.KEYCODE_VOLUME_DOWN -> "volumeDown"
        KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
        KeyEvent.KEYCODE_MEDIA_PLAY,
        KeyEvent.KEYCODE_MEDIA_PAUSE,
        KeyEvent.KEYCODE_HEADSETHOOK -> "play"
        KeyEvent.KEYCODE_MEDIA_NEXT -> "next"
        KeyEvent.KEYCODE_MEDIA_PREVIOUS -> "previous"
        else -> null
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val name = nameOf(event.keyCode)
        if (name == null || name !in handled) return super.dispatchKeyEvent(event)
        // Csak a lenyomás számít, a nyomva tartás ismétlése nem.
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
            channel?.invokeMethod("key", name)
        }
        return true // a gombot elnyeljük
    }

    companion object {
        private const val CHANNEL = "radrecon/keys"
    }
}
