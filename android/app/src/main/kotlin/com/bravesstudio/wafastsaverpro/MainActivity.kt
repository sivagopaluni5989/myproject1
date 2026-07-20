package com.bravesstudio.wafastsaverpro

import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val MEDIA_CHANNEL = "media_scanner"
    private val WA_CHANNEL = "wa_status_channel"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        // Media scanner channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "scanFile") {
                val path = call.argument<String>("path")

                if (path != null) {
                    MediaScannerConnection.scanFile(
                        this,
                        arrayOf(path),
                        null,
                        null
                    )
                    result.success(true)
                } else {
                    result.error(
                        "NO_PATH",
                        "File path missing",
                        null
                    )
                }
            } else {
                result.notImplemented()
            }
        }

        // WhatsApp detection channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WA_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "isWhatsAppInstalled" -> {
                    result.success(
                        isPackageInstalled("com.whatsapp")
                    )
                }

                "isWhatsAppBusinessInstalled" -> {
                    result.success(
                        isPackageInstalled("com.whatsapp.w4b")
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isPackageInstalled(
        packageName: String
    ): Boolean {
        return try {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_ACTIVITIES
            )
            true
        } catch (e: Exception) {
            false
        }
    }
}
