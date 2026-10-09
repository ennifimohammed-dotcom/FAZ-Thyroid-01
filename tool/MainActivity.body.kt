
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val xlsxMime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "faztyroid/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        try {
                            val name = call.argument<String>("name")
                            val bytes = call.argument<ByteArray>("bytes")
                            if (name == null || bytes == null) {
                                result.error("BAD_ARGS", "Arguments manquants", null)
                            } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                                result.error("UNSUPPORTED", "Android 10 ou plus requis", null)
                            } else {
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                                    put(MediaStore.Downloads.MIME_TYPE, xlsxMime)
                                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                }
                                val uri = contentResolver.insert(
                                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, values
                                )
                                if (uri == null) {
                                    result.error("NO_URI", "Création du fichier impossible", null)
                                } else {
                                    contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                                    result.success(uri.toString())
                                }
                            }
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    "shareFile" -> {
                        try {
                            val uriText = call.argument<String>("uri")
                            if (uriText == null) {
                                result.error("BAD_ARGS", "URI manquante", null)
                            } else {
                                val send = Intent(Intent.ACTION_SEND).apply {
                                    type = xlsxMime
                                    putExtra(Intent.EXTRA_STREAM, Uri.parse(uriText))
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivity(Intent.createChooser(send, null))
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            result.error("SHARE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
