package com.ghdinteractivestudio.morphpdf.ocr

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Production Kotlin bridge communicating between Flutter and ONNX Runtime Android
 * for PaddleOCR document analysis (PP-OCRv4 Detection, PP-OCRv4 Latin Rec, PP-OCRv3 Arabic Rec).
 */
class PaddleOcrBridge(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.ghdinteractivestudio.morphpdf/ocr"
        const val MAX_IMAGE_DIMENSION = 4096
        const val DET_MAX_SIDE = 960
        const val REC_HEIGHT = 48
        const val REC_MAX_WIDTH = 960
        const val DET_THRESH = 0.3f
        const val BOX_THRESH = 0.5f
        const val UNCLIP_RATIO = 1.5f
    }

    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val isCancelled = AtomicBoolean(false)
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var ortEnv: OrtEnvironment? = null
    private var sessionOptions: OrtSession.SessionOptions? = null

    private var detSession: OrtSession? = null
    private var detInputName: String = "x"

    private var recLatinSession: OrtSession? = null
    private var recLatinInputName: String = "x"
    private var latinDict: List<String> = emptyList()

    private var recArabicSession: OrtSession? = null
    private var recArabicInputName: String = "x"
    private var arabicDict: List<String> = emptyList()

    private var isInitialized = false

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                executor.execute {
                    try {
                        ensureInitialized()
                        mainHandler.post { result.success(true) }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("OCR_INIT_FAILED", "Échec d'initialisation ONNX Runtime : ${e.localizedMessage}", e.toString())
                        }
                    }
                }
            }
            "recognizePage" -> {
                val imagePath = call.argument<String>("imagePath")
                val pageIndex = call.argument<Int>("pageIndex") ?: 1
                val mode = call.argument<String>("mode") ?: "auto"
                val maxDim = call.argument<Int>("maxDimension") ?: MAX_IMAGE_DIMENSION

                if (imagePath == null) {
                    result.error("OCR_INVALID_ARGS", "L'argument 'imagePath' est obligatoire.", null)
                    return
                }

                val file = File(imagePath)
                if (!file.exists()) {
                    result.error("OCR_FILE_NOT_FOUND", "Le fichier image n'existe pas : $imagePath", null)
                    return
                }

                // Check dimensions without loading full raster
                val boundsOptions = BitmapFactory.Options().apply {
                    inJustDecodeBounds = true
                }
                BitmapFactory.decodeFile(imagePath, boundsOptions)
                val width = boundsOptions.outWidth
                val height = boundsOptions.outHeight

                if (width > maxDim || height > maxDim) {
                    result.error(
                        "OCR_IMAGE_TOO_LARGE",
                        "Les dimensions de l'image ($width x $height) dépassent la limite de sécurité ($maxDim px).",
                        mapOf("width" to width, "height" to height, "maxAllowed" to maxDim)
                    )
                    return
                }

                if (isCancelled.get()) {
                    isCancelled.set(false)
                    result.error("OCR_CANCELLED", "Le traitement OCR a été annulé.", null)
                    return
                }

                executor.execute {
                    val startTime = System.currentTimeMillis()
                    var bitmap: Bitmap? = null
                    try {
                        ensureInitialized()

                        if (isCancelled.get()) {
                            isCancelled.set(false)
                            mainHandler.post { result.error("OCR_CANCELLED", "Le traitement OCR a été annulé.", null) }
                            return@execute
                        }

                        bitmap = BitmapFactory.decodeFile(imagePath)
                        if (bitmap == null) {
                            mainHandler.post {
                                result.error("OCR_IMAGE_DECODE_FAILED", "Impossible de décoder le bitmap : $imagePath", null)
                            }
                            return@execute
                        }

                        val isArabicMode = mode == "arabic" || (mode == "auto" && imagePath.contains("arabic", ignoreCase = true))
                        val detectedBlocks = processPageInference(bitmap, isArabicMode)

                        if (isCancelled.get()) {
                            isCancelled.set(false)
                            mainHandler.post { result.error("OCR_CANCELLED", "Le traitement OCR a été annulé.", null) }
                            return@execute
                        }

                        val elapsedTime = System.currentTimeMillis() - startTime
                        val response = mapOf(
                            "pageIndex" to pageIndex,
                            "imageWidth" to width.toDouble(),
                            "imageHeight" to height.toDouble(),
                            "blocks" to detectedBlocks,
                            "processingTimeMs" to elapsedTime,
                            "engineUsed" to "PaddleOCR (ONNX Runtime Android)",
                            "isRightToLeft" to isArabicMode
                        )

                        mainHandler.post { result.success(response) }
                    } catch (e: FileNotFoundException) {
                        mainHandler.post {
                            result.error("OCR_MODEL_NOT_FOUND", "Fichier modèle ou dictionnaire OCR manquant : ${e.localizedMessage}", null)
                        }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("OCR_INFERENCE_FAILED", "Échec de l'inférence OCR ONNX : ${e.localizedMessage}", e.toString())
                        }
                    } finally {
                        bitmap?.recycle()
                    }
                }
            }
            "cancel" -> {
                isCancelled.set(true)
                result.success(true)
            }
            "dispose" -> {
                executor.execute {
                    releaseSessions()
                    isCancelled.set(false)
                    isInitialized = false
                    mainHandler.post { result.success(true) }
                }
            }
            else -> result.notImplemented()
        }
    }

    @Synchronized
    private fun ensureInitialized() {
        if (isInitialized && ortEnv != null && detSession != null) return

        val env = OrtEnvironment.getEnvironment()
        ortEnv = env

        val opts = OrtSession.SessionOptions().apply {
            setInterOpNumThreads(2)
            setIntraOpNumThreads(2)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.BASIC_OPT)
        }
        sessionOptions = opts

        // 1. Detection session (ch_PP-OCRv4_det_infer.onnx)
        val detBytes = loadAssetBytes("detection/ch_PP-OCRv4_det_infer.onnx")
        val det = env.createSession(detBytes, opts)
        detSession = det
        detInputName = det.inputNames.iterator().next()

        // 2. Latin Recognition session (en_PP-OCRv4_rec_infer.onnx) & dict
        val latinBytes = loadAssetBytes("recognition/latin/en_PP-OCRv4_rec_infer.onnx")
        val recLatin = env.createSession(latinBytes, opts)
        recLatinSession = recLatin
        recLatinInputName = recLatin.inputNames.iterator().next()
        latinDict = loadDictionary("dictionaries/en_dict.txt")

        // 3. Arabic Recognition session (arabic_PP-OCRv3_rec_infer.onnx) & dict
        val arabicBytes = loadAssetBytes("recognition/arabic/arabic_PP-OCRv3_rec_infer.onnx")
        val recArabic = env.createSession(arabicBytes, opts)
        recArabicSession = recArabic
        recArabicInputName = recArabic.inputNames.iterator().next()
        arabicDict = loadDictionary("dictionaries/arabic_dict.txt")

        isInitialized = true
    }

    private fun loadAssetBytes(subPath: String): ByteArray {
        val candidates = listOf(
            "flutter_assets/assets/models/ocr/$subPath",
            "assets/models/ocr/$subPath",
            "models/ocr/$subPath"
        )
        for (candidate in candidates) {
            try {
                context.assets.open(candidate).use { return it.readBytes() }
            } catch (_: Exception) {}
        }
        throw FileNotFoundException("Modèle OCR introuvable dans les assets : $subPath")
    }

    private fun loadDictionary(subPath: String): List<String> {
        val bytes = loadAssetBytes(subPath)
        return String(bytes, Charsets.UTF_8).lines()
            .map { it.trim('\r') }
            .filter { it.isNotEmpty() }
    }

    private data class DetBox(
        val left: Double,
        val top: Double,
        val width: Double,
        val height: Double,
        val confidence: Double
    )

    private fun processPageInference(bitmap: Bitmap, isArabic: Boolean): List<Map<String, Any>> {
        val env = ortEnv ?: throw IllegalStateException("ONNX Runtime non initialisé")
        val det = detSession ?: throw IllegalStateException("Session de détection non initialisée")

        val origW = bitmap.width
        val origH = bitmap.height

        // 1. Detection preprocessing: scale so max side <= DET_MAX_SIDE, round to multiples of 32
        var scale = 1.0f
        val maxSide = max(origW, origH)
        if (maxSide > DET_MAX_SIDE) {
            scale = DET_MAX_SIDE.toFloat() / maxSide
        }
        var targetDetW = ((origW * scale / 32).roundToInt() * 32).coerceAtLeast(32)
        var targetDetH = ((origH * scale / 32).roundToInt() * 32).coerceAtLeast(32)

        val detScaled = Bitmap.createScaledBitmap(bitmap, targetDetW, targetDetH, true)
        val detPixels = IntArray(targetDetW * targetDetH)
        detScaled.getPixels(detPixels, 0, targetDetW, 0, 0, targetDetW, targetDetH)
        if (detScaled != bitmap) detScaled.recycle()

        // Normalize RGB (ImageNet stats)
        val detBuffer = ByteBuffer.allocateDirect(1 * 3 * targetDetH * targetDetW * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        val mean = floatArrayOf(0.485f, 0.456f, 0.406f)
        val std = floatArrayOf(0.229f, 0.224f, 0.225f)

        // Channel R
        for (i in 0 until targetDetH * targetDetW) {
            val r = (detPixels[i] shr 16 and 0xFF) / 255.0f
            detBuffer.put((r - mean[0]) / std[0])
        }
        // Channel G
        for (i in 0 until targetDetH * targetDetW) {
            val g = (detPixels[i] shr 8 and 0xFF) / 255.0f
            detBuffer.put((g - mean[1]) / std[1])
        }
        // Channel B
        for (i in 0 until targetDetH * targetDetW) {
            val b = (detPixels[i] and 0xFF) / 255.0f
            detBuffer.put((b - mean[2]) / std[2])
        }
        detBuffer.rewind()

        // Run Detection Session
        val detTensor = OnnxTensor.createTensor(env, detBuffer, longArrayOf(1, 3, targetDetH.toLong(), targetDetW.toLong()))
        val detBoxes = mutableListOf<DetBox>()

        try {
            val detResult = det.run(mapOf(detInputName to detTensor))
            try {
                val outTensor = detResult.get(0) as OnnxTensor
                val probBuffer = outTensor.floatBuffer
                val probMap = FloatArray(targetDetH * targetDetW)
                probBuffer.get(probMap)

                // Connected Components analysis on probMap > DET_THRESH
                val scaleX = origW.toDouble() / targetDetW
                val scaleY = origH.toDouble() / targetDetH
                detBoxes.addAll(extractBoxesFromHeatmap(probMap, targetDetW, targetDetH, scaleX, scaleY))
            } finally {
                detResult.close()
            }
        } finally {
            detTensor.close()
        }

        if (detBoxes.isEmpty()) {
            return emptyList()
        }

        // Sort boxes in reading order (top-to-bottom, then left-to-right or right-to-left)
        detBoxes.sortWith(Comparator { b1, b2 ->
            val yDiff = b1.top - b2.top
            if (Math.abs(yDiff) > min(b1.height, b2.height) * 0.5) {
                b1.top.compareTo(b2.top)
            } else {
                if (isArabic) b2.left.compareTo(b1.left) else b1.left.compareTo(b2.left)
            }
        })

        // 2. Recognition Pipeline
        val blocks = mutableListOf<Map<String, Any>>()
        var blockIdx = 1

        for (box in detBoxes) {
            if (isCancelled.get()) break

            val cropX = box.left.toInt().coerceIn(0, origW - 1)
            val cropY = box.top.toInt().coerceIn(0, origH - 1)
            val cropW = box.width.toInt().coerceIn(1, origW - cropX)
            val cropH = box.height.toInt().coerceIn(1, origH - cropY)
            if (cropW < 4 || cropH < 4) continue

            val cropped = Bitmap.createBitmap(bitmap, cropX, cropY, cropW, cropH)
            val recognized = recognizeTextCrop(cropped, isArabic)
            cropped.recycle()

            if (recognized.text.isNotEmpty()) {
                val poly = listOf(
                    listOf(box.left, box.top),
                    listOf(box.left + box.width, box.top),
                    listOf(box.left + box.width, box.top + box.height),
                    listOf(box.left, box.top + box.height)
                )

                val bboxMap = mapOf(
                    "left" to box.left,
                    "top" to box.top,
                    "width" to box.width,
                    "height" to box.height,
                    "polygonPoints" to poly
                )

                // Break text into words
                val wordsList = mutableListOf<Map<String, Any>>()
                val wordTokens = recognized.text.split(" ").filter { it.isNotEmpty() }
                val wordWidth = if (wordTokens.isNotEmpty()) box.width / wordTokens.size else box.width

                for (wIdx in wordTokens.indices) {
                    val wLeft = if (isArabic) {
                        box.left + box.width - (wIdx + 1) * wordWidth
                    } else {
                        box.left + wIdx * wordWidth
                    }
                    wordsList.add(
                        mapOf(
                            "text" to wordTokens[wIdx],
                            "confidence" to recognized.confidence,
                            "boundingBox" to mapOf(
                                "left" to wLeft,
                                "top" to box.top,
                                "width" to wordWidth,
                                "height" to box.height
                            )
                        )
                    )
                }

                val lineMap = mapOf(
                    "text" to recognized.text,
                    "confidence" to recognized.confidence,
                    "boundingBox" to bboxMap,
                    "words" to wordsList
                )

                blocks.add(
                    mapOf(
                        "id" to "block_$blockIdx",
                        "text" to recognized.text,
                        "confidence" to recognized.confidence,
                        "language" to if (isArabic) "ar" else "fr",
                        "boundingBox" to bboxMap,
                        "lines" to listOf(lineMap)
                    )
                )
                blockIdx++
            }
        }

        return blocks
    }

    private data class RecResult(val text: String, val confidence: Double)

    private fun recognizeTextCrop(crop: Bitmap, isArabic: Boolean): RecResult {
        val env = ortEnv ?: return RecResult("", 0.0)
        val session = if (isArabic) recArabicSession else recLatinSession
        val inputName = if (isArabic) recArabicInputName else recLatinInputName
        val dict = if (isArabic) arabicDict else latinDict

        if (session == null || dict.isEmpty()) return RecResult("", 0.0)

        val targetH = REC_HEIGHT
        val targetW = ((targetH * crop.width.toFloat() / crop.height).roundToInt())
            .coerceIn(48, REC_MAX_WIDTH)

        val resized = Bitmap.createScaledBitmap(crop, targetW, targetH, true)
        val pixels = IntArray(targetW * targetH)
        resized.getPixels(pixels, 0, targetW, 0, 0, targetW, targetH)
        if (resized != crop) resized.recycle()

        // Normalize: (pixel / 255.0 - 0.5) / 0.5
        val recBuffer = ByteBuffer.allocateDirect(1 * 3 * targetH * targetW * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()

        for (i in 0 until targetH * targetW) {
            val r = (pixels[i] shr 16 and 0xFF) / 255.0f
            recBuffer.put((r - 0.5f) / 0.5f)
        }
        for (i in 0 until targetH * targetW) {
            val g = (pixels[i] shr 8 and 0xFF) / 255.0f
            recBuffer.put((g - 0.5f) / 0.5f)
        }
        for (i in 0 until targetH * targetW) {
            val b = (pixels[i] and 0xFF) / 255.0f
            recBuffer.put((b - 0.5f) / 0.5f)
        }
        recBuffer.rewind()

        val recTensor = OnnxTensor.createTensor(env, recBuffer, longArrayOf(1, 3, targetH.toLong(), targetW.toLong()))
        try {
            val recResult = session.run(mapOf(inputName to recTensor))
            try {
                val outTensor = recResult.get(0) as OnnxTensor
                val outBuffer = outTensor.floatBuffer
                val shape = outTensor.info.shape // [1, seq_len, vocab_size]
                val seqLen = shape[1].toInt()
                val vocabSize = shape[2].toInt()

                val sb = StringBuilder()
                var lastIdx = -1
                var probSum = 0.0
                var charCount = 0

                for (t in 0 until seqLen) {
                    var maxIdx = 0
                    var maxProb = -Float.MAX_VALUE
                    val offset = t * vocabSize
                    for (c in 0 until vocabSize) {
                        val p = outBuffer.get(offset + c)
                        if (p > maxProb) {
                            maxProb = p
                            maxIdx = c
                        }
                    }

                    if (maxIdx != 0 && maxIdx != lastIdx) {
                        val ch = if (maxIdx <= dict.size) {
                            dict[maxIdx - 1]
                        } else if (maxIdx == dict.size + 1) {
                            " "
                        } else {
                            ""
                        }
                        if (ch.isNotEmpty()) {
                            sb.append(ch)
                            probSum += maxProb.toDouble()
                            charCount++
                        }
                    }
                    lastIdx = maxIdx
                }

                val text = sb.toString().trim()
                val confidence = if (charCount > 0) (probSum / charCount).coerceIn(0.0, 1.0) else 0.85
                return RecResult(text, confidence)
            } finally {
                recResult.close()
            }
        } finally {
            recTensor.close()
        }
    }

    private fun extractBoxesFromHeatmap(
        probMap: FloatArray,
        w: Int,
        h: Int,
        scaleX: Double,
        scaleY: Double
    ): List<DetBox> {
        val visited = BooleanArray(w * h)
        val boxes = mutableListOf<DetBox>()
        val queue = IntArray(w * h)

        for (y in 0 until h) {
            for (x in 0 until w) {
                val idx = y * w + x
                if (probMap[idx] > DET_THRESH && !visited[idx]) {
                    visited[idx] = true
                    var qHead = 0
                    var qTail = 0
                    queue[qTail++] = idx

                    var minX = x
                    var maxX = x
                    var minY = y
                    var maxY = y
                    var totalScore = 0f
                    var count = 0

                    while (qHead < qTail) {
                        val cur = queue[qHead++]
                        val cy = cur / w
                        val cx = cur % w
                        totalScore += probMap[cur]
                        count++

                        if (cx < minX) minX = cx
                        if (cx > maxX) maxX = cx
                        if (cy < minY) minY = cy
                        if (cy > maxY) maxY = cy

                        // 4-connected neighbors
                        if (cx > 0) {
                            val n = cur - 1
                            if (probMap[n] > DET_THRESH && !visited[n]) {
                                visited[n] = true
                                queue[qTail++] = n
                            }
                        }
                        if (cx < w - 1) {
                            val n = cur + 1
                            if (probMap[n] > DET_THRESH && !visited[n]) {
                                visited[n] = true
                                queue[qTail++] = n
                            }
                        }
                        if (cy > 0) {
                            val n = cur - w
                            if (probMap[n] > DET_THRESH && !visited[n]) {
                                visited[n] = true
                                queue[qTail++] = n
                            }
                        }
                        if (cy < h - 1) {
                            val n = cur + w
                            if (probMap[n] > DET_THRESH && !visited[n]) {
                                visited[n] = true
                                queue[qTail++] = n
                            }
                        }
                    }

                    val avgScore = if (count > 0) totalScore / count else 0f
                    val boxW = maxX - minX + 1
                    val boxH = maxY - minY + 1

                    // Filter noise
                    if (count >= 16 && boxW >= 4 && boxH >= 4 && avgScore >= BOX_THRESH) {
                        val deltaX = ((boxW * UNCLIP_RATIO - boxW) / 2f).coerceAtLeast(1f)
                        val deltaY = ((boxH * UNCLIP_RATIO - boxH) / 2f).coerceAtLeast(1f)

                        val unclipMinX = (minX - deltaX).coerceAtLeast(0f)
                        val unclipMaxX = (maxX + deltaX).coerceAtMost((w - 1).toFloat())
                        val unclipMinY = (minY - deltaY).coerceAtLeast(0f)
                        val unclipMaxY = (maxY + deltaY).coerceAtMost((h - 1).toFloat())

                        val origLeft = unclipMinX * scaleX
                        val origTop = unclipMinY * scaleY
                        val origWidth = (unclipMaxX - unclipMinX) * scaleX
                        val origHeight = (unclipMaxY - unclipMinY) * scaleY

                        if (origWidth >= 6 && origHeight >= 6) {
                            boxes.add(DetBox(origLeft, origTop, origWidth, origHeight, avgScore.toDouble()))
                        }
                    }
                }
            }
        }
        return boxes
    }

    @Synchronized
    private fun releaseSessions() {
        detSession?.close()
        detSession = null

        recLatinSession?.close()
        recLatinSession = null

        recArabicSession?.close()
        recArabicSession = null

        sessionOptions?.close()
        sessionOptions = null

        ortEnv?.close()
        ortEnv = null
    }

    fun detach() {
        channel.setMethodCallHandler(null)
        executor.execute {
            releaseSessions()
        }
    }
}
