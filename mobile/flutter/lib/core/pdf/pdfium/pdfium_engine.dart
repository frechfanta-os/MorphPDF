import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../../../shared/models/document.dart';
import '../../../shared/models/page_model.dart';
import '../../../shared/models/text_block.dart';
import '../lru_cache.dart';
import '../pdf_exceptions.dart';
import '../pdf_models.dart';
import '../text_grouper.dart';
import 'pdfium_bindings.dart';
import 'pdfium_loader.dart';

/// RAII Native Document Handle. Automatically tracks native pointer.
class PdfDocumentHandle {
  final Pointer<Void> pointer;
  final String filePath;
  bool isClosed = false;

  PdfDocumentHandle(this.pointer, this.filePath);

  void checkValid() {
    if (isClosed || pointer == nullptr) {
      throw const PdfInvalidDocumentException('Document handle is closed or invalid.');
    }
  }

  void close(PdfiumBindings bindings) {
    if (!isClosed && pointer != nullptr) {
      bindings.closeDocument(pointer);
      isClosed = true;
    }
  }
}

/// Primary PDF Engine implementing rendering, inspection, and text extraction
/// via Google PDFium with dynamic FFI bindings and fallback simulation.
class PdfiumEngine {
  final PdfiumBindings? _bindings;
  final LruCache<String, Uint8List> _pageCache = LruCache<String, Uint8List>(capacity: 25);
  final LruCache<String, Uint8List> _thumbnailCache = LruCache<String, Uint8List>(capacity: 60);
  final Map<String, PdfDocumentHandle> _openDocuments = {};

  PdfiumEngine({PdfiumBindings? bindings})
      : _bindings = bindings ?? PdfiumLoader.bindings;

  bool get isNative => _bindings != null;

  /// Inspects a PDF document and returns typed metadata.
  Future<PdfInspectionResult> inspect(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw PdfFileNotFoundException(filePath);
    }
    final fileSize = await file.length();
    if (fileSize == 0) {
      throw PdfInvalidDocumentException('Le fichier PDF est vide.', filePath);
    }

    if (_bindings != null) {
      final handle = _getOrOpenDocument(filePath);
      final pageCount = _bindings.getPageCount(handle.pointer);
      double width = 595.0;
      double height = 842.0;

      if (pageCount > 0) {
        final pagePtr = _bindings.loadPage(handle.pointer, 0);
        if (pagePtr != nullptr) {
          width = _bindings.getPageWidth(pagePtr);
          height = _bindings.getPageHeight(pagePtr);
          _bindings.closePage(pagePtr);
        }
      }

      return PdfInspectionResult(
        fileName: file.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => 'document.pdf'),
        fileSizeBytes: fileSize,
        pageCount: max(1, pageCount),
        defaultWidth: width,
        defaultHeight: height,
        version: '1.4',
        hasText: true,
      );
    }

    // Fallback parser for test environments
    return _inspectFallback(file, fileSize);
  }

  /// Returns total page count of a document.
  Future<int> getPageCount(String filePath) async {
    final result = await inspect(filePath);
    return result.pageCount;
  }

  /// Returns all pages of a document with dimensions and rotation.
  Future<List<PageModel>> getPages(String filePath) async {
    final inspection = await inspect(filePath);
    final count = inspection.pageCount;
    final List<PageModel> pages = [];

    if (_bindings != null) {
      final handle = _getOrOpenDocument(filePath);
      for (int i = 0; i < count; i++) {
        final pagePtr = _bindings.loadPage(handle.pointer, i);
        double w = inspection.defaultWidth;
        double h = inspection.defaultHeight;
        if (pagePtr != nullptr) {
          w = _bindings.getPageWidth(pagePtr);
          h = _bindings.getPageHeight(pagePtr);
          _bindings.closePage(pagePtr);
        }
        pages.add(PageModel(pageNumber: i + 1, width: w, height: h, rotation: 0));
      }
      return pages;
    }

    for (int i = 1; i <= count; i++) {
      pages.add(
        PageModel(
          pageNumber: i,
          width: inspection.defaultWidth,
          height: inspection.defaultHeight,
          rotation: 0,
        ),
      );
    }
    return pages;
  }

  /// Renders a page to an image buffer (Uint8List) at the specified DPI.
  Future<Uint8List> renderPage(
    String filePath,
    int pageNumber, {
    int dpi = 150,
  }) async {
    final cacheKey = '$filePath-$pageNumber-$dpi';
    final cached = _pageCache.get(cacheKey);
    if (cached != null) return cached;

    final pages = await getPages(filePath);
    if (pageNumber < 1 || pageNumber > pages.length) {
      throw PdfPageOutOfRangeException(pageNumber, pages.length);
    }

    final page = pages[pageNumber - 1];
    final widthPx = CoordinateConverter.pointsToPixels(page.width, dpi).round();
    final heightPx = CoordinateConverter.pointsToPixels(page.height, dpi).round();

    if (_bindings != null) {
      final handle = _getOrOpenDocument(filePath);
      final pagePtr = _bindings.loadPage(handle.pointer, pageNumber - 1);
      if (pagePtr == nullptr) {
        throw PdfRenderFailedException(pageNumber);
      }

      try {
        final bitmap = _bindings.bitmapCreateEx(widthPx, heightPx, 4, nullptr, 0);
        if (bitmap == nullptr) {
          throw PdfRenderFailedException(pageNumber, 'Allocation bitmap échouée');
        }

        // Fill with white background (0xFFFFFFFF)
        _bindings.bitmapFillRect(bitmap, 0, 0, widthPx, heightPx, 0xFFFFFFFF);
        // Render page with antialiasing and text render flags (0x01 | 0x02)
        _bindings.renderPageBitmap(bitmap, pagePtr, 0, 0, widthPx, heightPx, 0, 0x03);

        final bufferPtr = _bindings.bitmapGetBuffer(bitmap);
        final bufferSize = widthPx * heightPx * 4;
        final rawBytes = bufferPtr.asTypedList(bufferSize);

        final bytes = _createBmpFromRgba(rawBytes, widthPx, heightPx);
        _bindings.bitmapDestroy(bitmap);

        _pageCache.put(cacheKey, bytes);
        return bytes;
      } finally {
        _bindings.closePage(pagePtr);
      }
    }

    // Fallback synthetic rendering for test runner
    final syntheticBytes = _generateSyntheticBitmap(widthPx, heightPx, pageNumber);
    _pageCache.put(cacheKey, syntheticBytes);
    return syntheticBytes;
  }

  /// Generates a fast thumbnail for a page.
  Future<Uint8List> renderThumbnail(
    String filePath,
    int pageNumber, {
    int size = 120,
  }) async {
    final cacheKey = '$filePath-thumb-$pageNumber-$size';
    final cached = _thumbnailCache.get(cacheKey);
    if (cached != null) return cached;

    // Use lower DPI (72) for thumbnail efficiency
    final thumbBytes = await renderPage(filePath, pageNumber, dpi: 72);
    _thumbnailCache.put(cacheKey, thumbBytes);
    return thumbBytes;
  }

  /// Extracts raw plain text from a specific page.
  Future<String> extractText(String filePath, int pageNumber) async {
    final blocks = await extractTextBlocks(filePath, pageNumber);
    return blocks.map((b) => b.text).join('\n');
  }

  /// Extracts structured text blocks with spatial coordinates (PDF points).
  Future<List<TextBlock>> extractTextBlocks(String filePath, int pageNumber) async {
    final pages = await getPages(filePath);
    if (pageNumber < 1 || pageNumber > pages.length) {
      throw PdfPageOutOfRangeException(pageNumber, pages.length);
    }

    if (_bindings != null) {
      final handle = _getOrOpenDocument(filePath);
      final pagePtr = _bindings.loadPage(handle.pointer, pageNumber - 1);
      if (pagePtr == nullptr) {
        throw PdfTextExtractionFailedException(pageNumber);
      }

      final textPagePtr = _bindings.textLoadPage(pagePtr);
      if (textPagePtr == nullptr) {
        _bindings.closePage(pagePtr);
        return const [];
      }

      try {
        final charCount = _bindings.textCountChars(textPagePtr);
        if (charCount <= 0) return const [];

        final List<RawCharBox> rawChars = [];
        final leftPtr = calloc<Double>();
        final rightPtr = calloc<Double>();
        final bottomPtr = calloc<Double>();
        final topPtr = calloc<Double>();
        final charBuffer = calloc<Uint16>(2);

        try {
          for (int i = 0; i < charCount; i++) {
            final len = _bindings.textGetText(textPagePtr, i, 1, charBuffer);
            if (len <= 0) continue;
            final charStr = String.fromCharCode(charBuffer[0]);

            _bindings.textGetCharBox(textPagePtr, i, leftPtr, rightPtr, bottomPtr, topPtr);
            final fontSize = _bindings.textGetFontSize(textPagePtr, i);

            final l = leftPtr.value;
            final r = rightPtr.value;
            final b = bottomPtr.value;
            final t = topPtr.value;

            rawChars.add(
              RawCharBox(
                char: charStr,
                x: l,
                y: b,
                width: max(0.0, r - l),
                height: max(0.0, t - b),
                fontSize: fontSize > 0 ? fontSize : 12.0,
              ),
            );
          }
        } finally {
          calloc.free(leftPtr);
          calloc.free(rightPtr);
          calloc.free(bottomPtr);
          calloc.free(topPtr);
          calloc.free(charBuffer);
        }

        return TextGrouper.groupCharacters(
          pageNumber: pageNumber,
          rawChars: rawChars,
        );
      } finally {
        _bindings.textClosePage(textPagePtr);
        _bindings.closePage(pagePtr);
      }
    }

    // Fallback extraction for test environments
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);

    // Look for text operators like (Some text) Tj
    final regex = RegExp(r'\((.*?)\)\s*Tj');
    final matches = regex.allMatches(content);
    final List<TextBlock> blocks = [];
    int idx = 1;
    double currentY = 780.0;

    for (final match in matches) {
      final text = match.group(1);
      if (text != null && text.isNotEmpty) {
        blocks.add(
          TextBlock(
            id: 'block_${pageNumber}_$idx',
            pageNumber: pageNumber,
            text: text,
            x: 50.0,
            y: currentY,
            width: text.length * 8.0,
            height: 16.0,
            confidence: 1.0,
            language: 'fr',
          ),
        );
        currentY -= 24.0;
        idx++;
      }
    }

    if (blocks.isEmpty) {
      blocks.add(
        TextBlock(
          id: 'block_${pageNumber}_1',
          pageNumber: pageNumber,
          text: 'Texte extrait de la page $pageNumber.',
          x: 50.0,
          y: 780.0,
          width: 250.0,
          height: 16.0,
          confidence: 1.0,
          language: 'fr',
        ),
      );
    }

    return blocks;
  }

  /// Maps an inspected document to the unified [DocumentModel].
  Future<DocumentModel> toDocumentModel(String filePath) async {
    final inspection = await inspect(filePath);
    return DocumentModel(
      id: filePath.hashCode.toString(),
      fileName: inspection.fileName,
      mimeType: 'application/pdf',
      fileSize: inspection.fileSizeBytes,
      pageCount: inspection.pageCount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Closes a document and releases its native resources.
  void closeDocument(String filePath) {
    final handle = _openDocuments.remove(filePath);
    if (handle != null && _bindings != null) {
      handle.close(_bindings);
    }
  }

  /// Closes all active documents and clears caches.
  void dispose() {
    if (_bindings != null) {
      for (final handle in _openDocuments.values) {
        handle.close(_bindings);
      }
    }
    _openDocuments.clear();
    _pageCache.clear();
    _thumbnailCache.clear();
  }

  PdfDocumentHandle _getOrOpenDocument(String filePath) {
    if (_openDocuments.containsKey(filePath)) {
      final handle = _openDocuments[filePath]!;
      if (!handle.isClosed) return handle;
    }

    final cPath = filePath.toNativeUtf8();
    try {
      final docPtr = _bindings!.loadDocument(cPath, nullptr);
      if (docPtr == nullptr) {
        final err = _bindings.getLastError();
        if (err == 1) { // FPDF_ERR_PASSWORD
          throw const PdfPasswordRequiredException();
        }
        throw PdfInvalidDocumentException('Échec de chargement PDFium (code: $err)', filePath);
      }
      final handle = PdfDocumentHandle(docPtr, filePath);
      _openDocuments[filePath] = handle;
      return handle;
    } finally {
      calloc.free(cPath);
    }
  }

  Future<PdfInspectionResult> _inspectFallback(File file, int fileSize) async {
    final bytes = await file.readAsBytes();
    final content = utf8.decode(bytes, allowMalformed: true);

    int pageCount = 1;
    final countMatch = RegExp(r'/Count\s+(\d+)').firstMatch(content);
    if (countMatch != null) {
      pageCount = int.tryParse(countMatch.group(1) ?? '1') ?? 1;
    }

    String version = '1.4';
    if (content.startsWith('%PDF-')) {
      final endLine = content.indexOf('\n');
      if (endLine > 5) {
        version = content.substring(5, endLine).trim();
      }
    }

    return PdfInspectionResult(
      fileName: file.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => 'document.pdf'),
      fileSizeBytes: fileSize,
      pageCount: max(1, pageCount),
      defaultWidth: 595.0,
      defaultHeight: 842.0,
      version: version,
      hasText: content.contains('BT') && content.contains('ET'),
    );
  }

  Uint8List _generateSyntheticBitmap(int width, int height, int pageNumber) {
    // Generate valid uncompressed 24-bit BMP image for Flutter Image.memory
    final rowSize = ((width * 3 + 3) ~/ 4) * 4;
    final imageSize = rowSize * height;
    final fileSize = 54 + imageSize;

    final bytes = ByteData(fileSize);
    // BMP Header
    bytes.setUint8(0, 0x42); // 'B'
    bytes.setUint8(1, 0x4D); // 'M'
    bytes.setUint32(2, fileSize, Endian.little);
    bytes.setUint32(10, 54, Endian.little); // Offset

    // DIB Header
    bytes.setUint32(14, 40, Endian.little); // Header size
    bytes.setInt32(18, width, Endian.little);
    bytes.setInt32(22, height, Endian.little);
    bytes.setUint16(26, 1, Endian.little); // Color planes
    bytes.setUint16(28, 24, Endian.little); // Bits per pixel
    bytes.setUint32(34, imageSize, Endian.little);

    // Fill with pleasant white/light-gray background
    for (int y = 0; y < height; y++) {
      final rowOffset = 54 + y * rowSize;
      for (int x = 0; x < width; x++) {
        final pixelOffset = rowOffset + x * 3;
        // Light subtle tint border
        if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
          bytes.setUint8(pixelOffset, 200);
          bytes.setUint8(pixelOffset + 1, 200);
          bytes.setUint8(pixelOffset + 2, 200);
        } else {
          bytes.setUint8(pixelOffset, 252);
          bytes.setUint8(pixelOffset + 1, 252);
          bytes.setUint8(pixelOffset + 2, 252);
        }
      }
    }

    return bytes.buffer.asUint8List();
  }

  Uint8List _createBmpFromRgba(Uint8List rgba, int width, int height) {
    final rowSize = ((width * 3 + 3) ~/ 4) * 4;
    final imageSize = rowSize * height;
    final fileSize = 54 + imageSize;

    final bytes = ByteData(fileSize);
    bytes.setUint8(0, 0x42);
    bytes.setUint8(1, 0x4D);
    bytes.setUint32(2, fileSize, Endian.little);
    bytes.setUint32(10, 54, Endian.little);

    bytes.setUint32(14, 40, Endian.little);
    bytes.setInt32(18, width, Endian.little);
    bytes.setInt32(22, height, Endian.little);
    bytes.setUint16(26, 1, Endian.little);
    bytes.setUint16(28, 24, Endian.little);
    bytes.setUint32(34, imageSize, Endian.little);

    for (int y = 0; y < height; y++) {
      final srcY = height - 1 - y; // BMP is bottom-up
      final srcRow = srcY * width * 4;
      final dstRow = 54 + y * rowSize;

      for (int x = 0; x < width; x++) {
        final srcIdx = srcRow + x * 4;
        final dstIdx = dstRow + x * 3;
        final b = rgba[srcIdx];
        final g = rgba[srcIdx + 1];
        final r = rgba[srcIdx + 2];
        bytes.setUint8(dstIdx, b);
        bytes.setUint8(dstIdx + 1, g);
        bytes.setUint8(dstIdx + 2, r);
      }
    }

    return bytes.buffer.asUint8List();
  }
}
