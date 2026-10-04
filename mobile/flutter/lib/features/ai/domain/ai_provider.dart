import 'document_analysis_model.dart';

abstract class AiProvider {
  String get providerName;

  Future<DocumentAnalysisModel> analyzeStructured(String text, {String? instructions});
  Future<String> analyzeDocument(String text, {String? instructions});
  Future<String> correctText(String text, {String? context});
  Future<String> summarizeDocument(String text, {int maxLength = 500});
  Future<String> extractStructuredData(String text, {String? schema});
  Future<String> translateText(String text, {required String targetLanguage});
  Future<String> chat(String message, {List<Map<String, String>>? history});
}
