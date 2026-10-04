package com.ghdinteractivestudio.morphpdf

import com.ghdinteractivestudio.morphpdf.ocr.PaddleOcrBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var ocrBridge: PaddleOcrBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ocrBridge = PaddleOcrBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ocrBridge?.detach()
        ocrBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
