import 'dart:ui';
import '../pdf/pdf_models.dart';
import '../../shared/models/text_block.dart';
import 'ocr_models.dart';

/// Unifies OCR pixel coordinate outputs with the MorphPDF [DocumentModel] coordinate space (PDF points)
/// strictly reusing the verified [CoordinateConverter].
class OcrCoordinateMapper {
  /// Converts an [OcrBoundingBox] (in OCR rendered image pixels)
  /// to a standard PDF point [Rect] (origin at bottom-left, Y-axis pointing upwards).
  static Rect ocrBoxToPdfRect({
    required OcrBoundingBox box,
    required double pageHeightPt,
    required int dpi,
    int rotationDegrees = 0,
    double pageWidthPt = 595.0,
  }) {
    final pixelRect = Rect.fromLTWH(box.left, box.top, box.width, box.height);
    final pdfRect = CoordinateConverter.pixelRectToPdfRect(
      pixelRect,
      pageHeightPt,
      dpi,
    );

    if (rotationDegrees == 0) {
      return pdfRect;
    }

    // Handle standard PDF page rotations (90, 180, 270)
    final normRotation = (rotationDegrees % 360 + 360) % 360;
    switch (normRotation) {
      case 90:
        return Rect.fromLTWH(
          pdfRect.top,
          pageWidthPt - pdfRect.right,
          pdfRect.height,
          pdfRect.width,
        );
      case 180:
        return Rect.fromLTWH(
          pageWidthPt - pdfRect.right,
          pageHeightPt - pdfRect.bottom,
          pdfRect.width,
          pdfRect.height,
        );
      case 270:
        return Rect.fromLTWH(
          pageHeightPt - pdfRect.bottom,
          pdfRect.left,
          pdfRect.height,
          pdfRect.width,
        );
      default:
        return pdfRect;
    }
  }

  /// Transforms an entire [OcrPageResult] into a list of unified [TextBlock]s
  /// ready for integration into [DocumentModel] and searchable overlay.
  static List<TextBlock> toTextBlocks({
    required OcrPageResult pageResult,
    required double pageHeightPt,
    required int dpi,
    int rotationDegrees = 0,
    double pageWidthPt = 595.0,
  }) {
    final List<TextBlock> blocks = [];
    int blockIdx = 1;

    for (final block in pageResult.blocks) {
      final rect = ocrBoxToPdfRect(
        box: block.boundingBox,
        pageHeightPt: pageHeightPt,
        dpi: dpi,
        rotationDegrees: rotationDegrees,
        pageWidthPt: pageWidthPt,
      );

      blocks.add(
        TextBlock(
          id: 'ocr_${pageResult.pageIndex}_$blockIdx',
          pageNumber: pageResult.pageIndex,
          text: block.text,
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
          confidence: block.confidence,
          language: block.language,
        ),
      );
      blockIdx++;
    }

    return blocks;
  }
}
