import '../../../core/ocr/ocr_models.dart';

class ConversionOptions {
  final bool preserveLayout;
  final bool extractImages;
  final bool detectTables;
  final bool ocrScannedPages;
  final OcrMode ocrMode;

  const ConversionOptions({
    this.preserveLayout = true,
    this.extractImages = true,
    this.detectTables = true,
    this.ocrScannedPages = false,
    this.ocrMode = OcrMode.auto,
  });
}

abstract class PdfToWordConverter {
  String get converterName;
  Future<String> convertPdfToWord(
    String pdfPath,
    String outputDocxPath, {
    ConversionOptions options = const ConversionOptions(),
  });
}
