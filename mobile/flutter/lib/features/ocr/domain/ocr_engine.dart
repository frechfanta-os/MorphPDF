import '../../../core/ocr/ocr_models.dart';
import '../../../shared/models/text_block.dart';

abstract class OcrEngine {
  String get engineName;
  List<String> get supportedLanguages;

  /// Backward-compatible flat text extraction from an image path.
  Future<List<TextBlock>> recognizeText(String imagePath, {String lang = 'en'});

  /// Structured page-level OCR recognition with full bounding boxes and polygons.
  Future<OcrPageResult> recognizePage({
    required String imagePath,
    required int pageIndex,
    OcrMode mode = OcrMode.auto,
    int maxDimension = 4096,
    OcrCancellationToken? cancellationToken,
  });
}

