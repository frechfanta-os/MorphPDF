class ConversionOptions {
  final bool preserveLayout;
  final bool extractImages;
  final bool detectTables;
  final bool ocrScannedPages;

  const ConversionOptions({
    this.preserveLayout = true,
    this.extractImages = true,
    this.detectTables = true,
    this.ocrScannedPages = false,
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
