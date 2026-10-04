import '../../../shared/models/text_block.dart';

abstract class OcrEngine {
  String get engineName;
  List<String> get supportedLanguages;
  Future<List<TextBlock>> recognizeText(String imagePath, {String lang = 'en'});
}
