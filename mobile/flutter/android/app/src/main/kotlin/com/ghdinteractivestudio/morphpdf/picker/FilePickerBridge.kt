package com.ghdinteractivestudio.morphpdf.picker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class FilePickerBridge(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.ghdinteractivestudio.morphpdf/file_picker"
        const val REQUEST_CODE_PICK_FILE = 2048
    }

    private var channel: MethodChannel? = MethodChannel(messenger, CHANNEL_NAME)
    private var pendingResult: MethodChannel.Result? = null

    init {
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFiles" -> {
                if (pendingResult != null) {
                    result.error("ALREADY_ACTIVE", "Une sélection de fichier est déjà en cours", null)
                    return
                }
                pendingResult = result
                val mimeType = call.argument<String>("mimeType") ?: "*/*"
                val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false

                try {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mimeType
                        if (allowMultiple) {
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        }
                    }
                    activity.startActivityForResult(intent, REQUEST_CODE_PICK_FILE)
                } catch (e: Exception) {
                    pendingResult = null
                    result.error("PICKER_ERROR", "Impossible d'ouvrir le sélecteur de documents: ${e.message}", null)
                }
            }
            "clearCache" -> {
                try {
                    val cacheDir = File(activity.cacheDir, "picker_cache")
                    if (cacheDir.exists()) {
                        cacheDir.deleteRecursively()
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CACHE_ERROR", "Erreur lors du nettoyage du cache: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK_FILE) {
            return false
        }

        val result = pendingResult ?: return false
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return true
        }

        try {
            val selectedPaths = mutableListOf<String>()
            val clipData = data.clipData
            if (clipData != null && clipData.itemCount > 0) {
                for (i in 0 until clipData.itemCount) {
                    val uri = clipData.getItemAt(i).uri
                    val path = copyUriToLocalCache(uri)
                    if (path != null) {
                        selectedPaths.add(path)
                    }
                }
            } else {
                val uri = data.data
                if (uri != null) {
                    val path = copyUriToLocalCache(uri)
                    if (path != null) {
                        selectedPaths.add(path)
                    }
                }
            }
            result.success(selectedPaths)
        } catch (e: Exception) {
            result.error("COPY_ERROR", "Erreur lors de la copie du fichier dans le cache local: ${e.message}", null)
        }

        return true
    }

    private fun copyUriToLocalCache(uri: Uri): String? {
        val cacheDir = File(activity.cacheDir, "picker_cache")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        var fileName = getFileName(uri)
        if (fileName.isNullOrBlank()) {
            fileName = "picked_file_${System.currentTimeMillis()}"
        }

        // Avoid collision
        val targetFile = File(cacheDir, "${System.currentTimeMillis()}_$fileName")
        var inputStream: InputStream? = null
        var outputStream: FileOutputStream? = null

        return try {
            inputStream = activity.contentResolver.openInputStream(uri) ?: return null
            outputStream = FileOutputStream(targetFile)
            val buffer = ByteArray(8192)
            var bytesRead: Int
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                outputStream.write(buffer, 0, bytesRead)
            }
            outputStream.flush()
            targetFile.absolutePath
        } catch (e: Exception) {
            null
        } finally {
            try {
                inputStream?.close()
                outputStream?.close()
            } catch (_: Exception) {}
        }
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        val cursor = activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index != -1) {
                    name = it.getString(index)
                }
            }
        }
        return name
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        pendingResult = null
    }
}
