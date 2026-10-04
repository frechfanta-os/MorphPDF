import 'ai_provider.dart';
import 'document_analysis_model.dart';

class AiService {
  final AiProvider _provider;

  AiService(this._provider);

  String get currentProviderName => _provider.providerName;

  Future<DocumentAnalysisModel> analyzeStructured(String text, {String? instructions}) {
    return _provider.analyzeStructured(text, instructions: instructions);
  }

  Future<String> analyze(String text, {String? instructions}) {
    return _provider.analyzeDocument(text, instructions: instructions);
  }

  Future<String> correct(String text, {String? context}) {
    return _provider.correctText(text, context: context);
  }

  Future<String> summarize(String text, {int maxLength = 500}) {
    return _provider.summarizeDocument(text, maxLength: maxLength);
  }

  Future<String> extractStructuredData(String text, {String? schema}) {
    return _provider.extractStructuredData(text, schema: schema);
  }

  Future<String> translate(String text, {required String targetLanguage}) {
    return _provider.translateText(text, targetLanguage: targetLanguage);
  }

  Future<String> chat(String message, {List<Map<String, String>>? history}) {
    return _provider.chat(message, history: history);
  }
}
