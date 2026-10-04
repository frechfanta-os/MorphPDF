import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/features/ai/data/openrouter_provider_mock.dart';
import 'package:morphpdf/features/ai/domain/ai_service.dart';

void main() {
  group('AI Abstraction Tests', () {
    test('OpenRouterProviderMock operations through AiService', () async {
      final provider = OpenRouterProviderMock();
      final service = AiService(provider);

      expect(service.currentProviderName, contains('OpenRouter'));

      final analysis = await service.analyze('Contenu du contrat');
      expect(analysis, contains('Mock Analysis'));

      final correction = await service.correct('Texte avek fotes');
      expect(correction, contains('Mock Correction'));

      final summary = await service.summarize('Long texte', maxLength: 100);
      expect(summary, contains('Mock Résumé'));

      final extracted = await service.extractStructuredData('Facture #123');
      expect(extracted, contains('{"status": "extracted"'));

      final translation = await service.translate('Hello', targetLanguage: 'fr');
      expect(translation, contains('Mock Traduction vers [fr]'));
    });
  });
}
