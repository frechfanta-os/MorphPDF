import '../data/sovereign_pdf_to_word_converter.dart';
import 'conversion_converter.dart';

class ConversionService {
  final PdfToWordConverter _converter;

  ConversionService([PdfToWordConverter? converter])
      : _converter = converter ?? SovereignPdfToWordConverter();

  String get converterName => _converter.converterName;

  Future<String> convert(
    String pdfPath,
    String outputDocxPath, {
    ConversionOptions options = const ConversionOptions(),
  }) {
    return _converter.convertPdfToWord(pdfPath, outputDocxPath, options: options);
  }
}

