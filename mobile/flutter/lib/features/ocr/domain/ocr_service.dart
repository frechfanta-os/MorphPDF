import '../../../shared/models/text_block.dart';
import 'ocr_engine.dart';

class OcrService {
  final OcrEngine _engine;

  OcrService(this._engine);

  String get currentEngineName => _engine.engineName;
  List<String> get supportedLanguages => _engine.supportedLanguages;

  Future<List<TextBlock>> processImage(String imagePath, {String lang = 'en'}) {
    return _engine.recognizeText(imagePath, lang: lang);
  }
}
