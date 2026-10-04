abstract class AiProvider {
  String get providerName;

  Future<String> analyzeDocument(String text, {String? instructions});
  Future<String> correctText(String text, {String? context});
  Future<String> summarizeDocument(String text, {int maxLength = 500});
  Future<String> extractStructuredData(String text, {String? schema});
  Future<String> translateText(String text, {required String targetLanguage});
}
