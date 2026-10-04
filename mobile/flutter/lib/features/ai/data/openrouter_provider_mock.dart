import '../domain/ai_provider.dart';
import '../domain/document_analysis_model.dart';

class OpenRouterProviderMock implements AiProvider {
  @override
  String get providerName => 'OpenRouter (Mock via Go Backend)';

  @override
  Future<DocumentAnalysisModel> analyzeStructured(String text, {String? instructions}) async {
    return DocumentAnalysisModel(
      summary: 'Mock Analysis: Document contient ${text.length} caractères. Contrat de prestation de services.',
      language: 'fr',
      documentType: 'Contrat',
      importantInformation: const ['Prestation valide 1 an', 'Clause de résiliation 30 jours'],
      dates: const ['04/10/2026'],
      amounts: const ['12 500 €'],
      people: const ['Jean Dupont', 'Marie Curie'],
      organizations: const ['GHD Interactive Studio'],
      issues: const [],
      suggestions: const ['Valider par signature électronique'],
    );
  }

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

  @override
  Future<String> chat(String message, {List<Map<String, String>>? history}) async {
    return 'Mock Assistant: Réponse à votre question sur le document ("$message").';
  }
}
