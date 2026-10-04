import 'dart:typed_data';
import 'dart:ui';
import '../../shared/models/text_block.dart';

/// Detailed inspection result for a PDF document.
class PdfInspectionResult {
  final String fileName;
  final int fileSizeBytes;
  final int pageCount;
  final double defaultWidth;
  final double defaultHeight;
  final String version;
  final bool isEncrypted;
  final bool hasText;

  const PdfInspectionResult({
    required this.fileName,
    required this.fileSizeBytes,
    required this.pageCount,
    this.defaultWidth = 595.0,
    this.defaultHeight = 842.0,
    this.version = '1.4',
    this.isEncrypted = false,
    this.hasText = true,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'pageCount': pageCount,
    'defaultWidth': defaultWidth,
    'defaultHeight': defaultHeight,
    'version': version,
    'isEncrypted': isEncrypted,
    'hasText': hasText,
  };
}

/// Rendered raster image for a single page.
class PdfPageRenderResult {
  final int pageNumber;
  final int widthPixels;
  final int heightPixels;
  final int dpi;
  final Uint8List bytes;

  const PdfPageRenderResult({
    required this.pageNumber,
    required this.widthPixels,
    required this.heightPixels,
    required this.dpi,
    required this.bytes,
  });
}

/// Result of extracting text and spatial coordinates from a page.
class PdfTextExtractionResult {
  final int pageNumber;
  final String fullText;
  final List<TextBlock> textBlocks;
  final int charCount;

  const PdfTextExtractionResult({
    required this.pageNumber,
    required this.fullText,
    required this.textBlocks,
    required this.charCount,
  });
}

/// High-precision conversion utility between PDF points (1/72 inch)
/// and raster pixels at arbitrary DPI.
class CoordinateConverter {
  /// Converts PDF points to pixels at a given DPI.
  static double pointsToPixels(double points, int dpi) {
    return points * dpi / 72.0;
  }

  /// Converts pixels back to PDF points at a given DPI.
  static double pixelsToPoints(double pixels, int dpi) {
    return pixels * 72.0 / dpi;
  }

  /// Converts a PDF rectangle (bottom-left origin) to screen/pixel coordinates (top-left origin).
  static Rect pdfRectToPixelRect(
    Rect pdfRect,
    double pageHeightPoints,
    int dpi,
  ) {
    final scale = dpi / 72.0;
    final left = pdfRect.left * scale;
    final width = pdfRect.width * scale;
    final height = pdfRect.height * scale;
    // Invert Y axis: PDF Y is measured from bottom, screen Y is measured from top
    final top = (pageHeightPoints - pdfRect.top) * scale;
    return Rect.fromLTWH(left, top, width, height);
  }

  /// Converts a screen/pixel rectangle (top-left origin) back to PDF points (bottom-left origin).
  static Rect pixelRectToPdfRect(
    Rect pixelRect,
    double pageHeightPoints,
    int dpi,
  ) {
    final scale = dpi / 72.0;
    final left = pixelRect.left / scale;
    final width = pixelRect.width / scale;
    final height = pixelRect.height / scale;
    final topInPdf = pageHeightPoints - (pixelRect.top / scale);
    return Rect.fromLTWH(left, topInPdf, width, height);
  }
}
