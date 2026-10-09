import 'dart:io';
import 'dart:typed_data';
import '../../../core/ocr/ocr_coordinate_mapper.dart';
import '../../../core/ocr/ocr_models.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../shared/models/text_block.dart';
import 'ocr_engine.dart';

/// Orchestrates OCR operations with strict sequential page processing (N=1),
/// user cancellation, progress updates, and spatial coordinate projection.
class OcrService {
  final OcrEngine _engine;

  OcrService(this._engine);

  String get currentEngineName => _engine.engineName;
  List<String> get supportedLanguages => _engine.supportedLanguages;

  /// Backward-compatible single image extraction.
  Future<List<TextBlock>> processImage(String imagePath, {String lang = 'en'}) {
    return _engine.recognizeText(imagePath, lang: lang);
  }

  /// Processes a single document page through the active OCR engine.
  Future<OcrPageResult> processPage({
    required String imagePath,
    required int pageIndex,
    OcrMode mode = OcrMode.auto,
    OcrCancellationToken? cancellationToken,
    void Function(OcrProgress)? onProgress,
  }) async {
    if (cancellationToken?.isCancelled == true) {
      throw const OcrCancelledException();
    }

    onProgress?.call(
      OcrProgress(
        currentPage: pageIndex,
        totalPages: pageIndex,
        fraction: 0.1,
        statusMessage: 'Analyse OCR de la page $pageIndex en cours...',
      ),
    );

    final result = await _engine.recognizePage(
      imagePath: imagePath,
      pageIndex: pageIndex,
      mode: mode,
      cancellationToken: cancellationToken,
    );

    if (cancellationToken?.isCancelled == true) {
      throw const OcrCancelledException();
    }

    onProgress?.call(
      OcrProgress(
        currentPage: pageIndex,
        totalPages: pageIndex,
        fraction: 1.0,
        statusMessage: 'Page $pageIndex terminée.',
      ),
    );

    return result;
  }

  /// Processes multiple pages strictly sequentially (N=1 page active at any given moment).
  /// Respects user cancellation between and during page inferences.
  Future<List<OcrPageResult>> processDocument({
    required List<String> pageImagePaths,
    OcrMode mode = OcrMode.auto,
    OcrCancellationToken? cancellationToken,
    void Function(OcrProgress)? onProgress,
  }) async {
    final List<OcrPageResult> results = [];
    final int total = pageImagePaths.length;

    for (int i = 0; i < total; i++) {
      if (cancellationToken?.isCancelled == true) {
        throw const OcrCancelledException();
      }

      final pageIndex = i + 1;
      onProgress?.call(
        OcrProgress(
          currentPage: pageIndex,
          totalPages: total,
          fraction: i / total,
          statusMessage: 'Traitement de la page $pageIndex sur $total...',
        ),
      );

      final pageResult = await _engine.recognizePage(
        imagePath: pageImagePaths[i],
        pageIndex: pageIndex,
        mode: mode,
        cancellationToken: cancellationToken,
      );

      results.add(pageResult);

      if (cancellationToken?.isCancelled == true) {
        throw const OcrCancelledException();
      }

      onProgress?.call(
        OcrProgress(
          currentPage: pageIndex,
          totalPages: total,
          fraction: (i + 1) / total,
          statusMessage: 'Page $pageIndex/$total analysée avec succès.',
        ),
      );
    }

    return results;
  }

  /// Converts an [OcrPageResult] into standard [TextBlock] models mapped into PDF points.
  List<TextBlock> mapToPdfTextBlocks(
    OcrPageResult pageResult, {
    required double pageHeightPt,
    required int dpi,
    int rotationDegrees = 0,
    double pageWidthPt = 595.0,
  }) {
    return OcrCoordinateMapper.toTextBlocks(
      pageResult: pageResult,
      pageHeightPt: pageHeightPt,
      dpi: dpi,
      rotationDegrees: rotationDegrees,
      pageWidthPt: pageWidthPt,
    );
  }

  /// Runs the full PDF -> Native Decision -> Render -> OCR -> PDF Coordinates pipeline.
  /// Only executes OCR when native extraction yields no usable text blocks (e.g. scanned document).
  Future<List<TextBlock>> extractTextFromPdfPage({
    required PdfiumEngine pdfEngine,
    required String pdfPath,
    required int pageIndex,
    int dpi = 150,
    OcrMode mode = OcrMode.auto,
    OcrCancellationToken? cancellationToken,
    void Function(OcrProgress)? onProgress,
  }) async {
    if (cancellationToken?.isCancelled == true) {
      throw const OcrCancelledException();
    }

    // Step 1: Attempt native PDF text extraction first
    List<TextBlock> nativeBlocks = const [];
    try {
      nativeBlocks = await pdfEngine.extractTextBlocks(pdfPath, pageIndex);
    } catch (_) {
      nativeBlocks = const [];
    }

    // Decision: If native text exists, preserve it! Do NOT run OCR unnecessarily.
    if (nativeBlocks.isNotEmpty) {
      return nativeBlocks;
    }

    // Step 2: Native text is absent -> Scanned / Raster page requiring OCR
    onProgress?.call(
      OcrProgress(
        currentPage: pageIndex,
        totalPages: pageIndex,
        fraction: 0.1,
        statusMessage: 'Rendu de la page $pageIndex via PDFium pour OCR...',
      ),
    );

    // Step 3: Render page to raster bitmap bytes using PDFium
    final Uint8List imageBytes = await pdfEngine.renderPage(
      pdfPath,
      pageIndex,
      dpi: dpi,
    );

    if (cancellationToken?.isCancelled == true) {
      throw const OcrCancelledException();
    }

    // Step 4: Write to temporary file for OCR engine
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/ocr_page_${pageIndex}_${DateTime.now().microsecondsSinceEpoch}.bmp');
    await tempFile.writeAsBytes(imageBytes);

    try {
      // Step 5: Execute OCR recognition
      final ocrResult = await processPage(
        imagePath: tempFile.path,
        pageIndex: pageIndex,
        mode: mode,
        cancellationToken: cancellationToken,
        onProgress: onProgress,
      );

      // Step 6: Map OCR coordinates from pixel space to PDF point space
      final pages = await pdfEngine.getPages(pdfPath);
      final pageModel = (pageIndex >= 1 && pageIndex <= pages.length)
          ? pages[pageIndex - 1]
          : null;

      final pageHeightPt = pageModel?.height ?? 842.0;
      final pageWidthPt = pageModel?.width ?? 595.0;
      final rotation = pageModel?.rotation ?? 0;

      return mapToPdfTextBlocks(
        ocrResult,
        pageHeightPt: pageHeightPt,
        dpi: dpi,
        rotationDegrees: rotation,
        pageWidthPt: pageWidthPt,
      );
    } finally {
      // Clean up temporary image file
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }
}

