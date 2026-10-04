import '../domain/conversion_converter.dart';

class MockPdfToWordConverter implements PdfToWordConverter {
  @override
  String get converterName => 'Mock DOCX Converter';

  @override
  Future<String> convertPdfToWord(
    String pdfPath,
    String outputDocxPath, {
    ConversionOptions options = const ConversionOptions(),
  }) async {
    return outputDocxPath;
  }
}
