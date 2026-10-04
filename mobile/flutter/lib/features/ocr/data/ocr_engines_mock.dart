import '../../../shared/models/text_block.dart';
import '../domain/ocr_engine.dart';

class MlKitEngineMock implements OcrEngine {
  @override
  String get engineName => 'Google ML Kit (Local Android)';

  @override
  List<String> get supportedLanguages => ['en', 'fr', 'es', 'de', 'it', 'pt'];

  @override
  Future<List<TextBlock>> recognizeText(String imagePath, {String lang = 'en'}) async {
    return [
      TextBlock(
        id: 'mlkit-mock-1',
        pageNumber: 1,
        text: 'Exemple de texte extrait via ML Kit',
        x: 10,
        y: 20,
        width: 300,
        height: 40,
        confidence: 0.98,
        language: lang,
      ),
    ];
  }
}

class PaddleOcrEngineMock implements OcrEngine {
  @override
  String get engineName => 'PaddleOCR (Multilingue & Arabe)';

  @override
  List<String> get supportedLanguages => ['ar', 'ch', 'ja', 'ko', 'en', 'fr'];

  @override
  Future<List<TextBlock>> recognizeText(String imagePath, {String lang = 'en'}) async {
    return [
      TextBlock(
        id: 'paddle-mock-1',
        pageNumber: 1,
        text: 'نص تجريبي مستخرج بواسطة PaddleOCR',
        x: 20,
        y: 30,
        width: 250,
        height: 35,
        confidence: 0.95,
        language: lang,
      ),
    ];
  }
}
