import 'conversion_converter.dart';

class ConversionService {
  final PdfToWordConverter _converter;

  ConversionService(this._converter);

  String get converterName => _converter.converterName;

  Future<String> convert(
    String pdfPath,
    String outputDocxPath, {
    ConversionOptions options = const ConversionOptions(),
  }) {
    return _converter.convertPdfToWord(pdfPath, outputDocxPath, options: options);
  }
}
