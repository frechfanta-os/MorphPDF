package com.ghdinteractivestudio.morphpdf

import android.content.Intent
import com.ghdinteractivestudio.morphpdf.ocr.PaddleOcrBridge
import com.ghdinteractivestudio.morphpdf.picker.FilePickerBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var ocrBridge: PaddleOcrBridge? = null
    private var filePickerBridge: FilePickerBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ocrBridge = PaddleOcrBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        filePickerBridge = FilePickerBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (filePickerBridge?.handleActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ocrBridge?.detach()
        ocrBridge = null
        filePickerBridge?.detach()
        filePickerBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
