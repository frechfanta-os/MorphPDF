import '../domain/ai_provider.dart';

class OpenRouterProviderMock implements AiProvider {
  @override
  String get providerName => 'OpenRouter (Mock via Go Backend)';

  @override
  Future<String> analyzeDocument(String text, {String? instructions}) async {
    return 'Mock Analysis: Document contient ${text.length} caractères. Sujet identifié : Contrat ou Rapport.';
  }

  @override
  Future<String> correctText(String text, {String? context}) async {
    return 'Mock Correction: $text (orthographe et syntaxe vérifiées).';
  }

  @override
  Future<String> summarizeDocument(String text, {int maxLength = 500}) async {
    return 'Mock Résumé: Synthèse concise du document en $maxLength caractères maximum.';
  }

  @override
  Future<String> extractStructuredData(String text, {String? schema}) async {
    return '{"status": "extracted", "fields": {"title": "Exemple", "type": "Mock"}}';
  }

  @override
  Future<String> translateText(String text, {required String targetLanguage}) async {
    return 'Mock Traduction vers [$targetLanguage]: $text';
  }
}
