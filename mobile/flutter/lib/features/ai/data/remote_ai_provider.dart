import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/ai_provider.dart';
import '../domain/document_analysis_model.dart';

class RemoteAiProvider implements AiProvider {
  final ApiClient _apiClient;

  RemoteAiProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  String get providerName => 'OpenRouter (via MorphPDF Go API)';

  @override
  Future<DocumentAnalysisModel> analyzeStructured(String text, {String? instructions}) async {
    final resp = await _apiClient.analyzeAi(text, instructions: instructions);
    if (!resp.success || resp.data == null) {
      throw resp.error ?? const ApiException(code: 'AI_ERROR', message: 'Erreur lors de l\'analyse');
    }
    return DocumentAnalysisModel.fromJson(resp.data!);
  }

  @override
  Future<String> analyzeDocument(String text, {String? instructions}) async {
    final structured = await analyzeStructured(text, instructions: instructions);
    return structured.summary;
  }

  @override
  Future<String> correctText(String text, {String? context}) async {
    final resp = await _apiClient.correctText(text, context: context);
    if (!resp.success || resp.data == null) {
      throw resp.error ?? const ApiException(code: 'AI_ERROR', message: 'Erreur de correction');
    }
    return resp.data!['corrected'] as String? ?? '';
  }

  @override
  Future<String> summarizeDocument(String text, {int maxLength = 500}) async {
    final resp = await _apiClient.summarize(text, maxLength: maxLength);
    if (!resp.success || resp.data == null) {
      throw resp.error ?? const ApiException(code: 'AI_ERROR', message: 'Erreur de résumé');
    }
    return resp.data!['summary'] as String? ?? '';
  }

  @override
  Future<String> extractStructuredData(String text, {String? schema}) async {
    final resp = await _apiClient.extractAi(text, schema: schema);
    if (!resp.success || resp.data == null) {
      throw resp.error ?? const ApiException(code: 'AI_ERROR', message: 'Erreur d\'extraction');
    }
    return resp.data!['extracted'] as String? ?? '';
  }

  @override
  Future<String> translateText(String text, {required String targetLanguage}) async {
    final resp = await _apiClient.translateAi(text, targetLanguage: targetLanguage);
    if (!resp.success || resp.data == null) {
      throw resp.error ?? const ApiException(code: 'AI_ERROR', message: 'Erreur de traduction');
    }
    return resp.data!['translated'] as String? ?? '';
  }

  @override
  Future<String> chat(String message, {List<Map<String, String>>? history}) async {
    final resp = await _apiClient.chatAi(message, history: history);
    if (!resp.success || resp.data == null) {
      throw resp.error ?? const ApiException(code: 'AI_ERROR', message: 'Erreur de communication IA');
    }
    return resp.data!['response'] as String? ?? '';
  }
}
