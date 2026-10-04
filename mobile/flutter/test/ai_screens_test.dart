import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morphpdf/core/network/api_client.dart';
import 'package:morphpdf/core/network/api_exception.dart';
import 'package:morphpdf/features/ai/data/openrouter_provider_mock.dart';
import 'package:morphpdf/features/ai/domain/ai_provider.dart';
import 'package:morphpdf/features/ai/domain/ai_service.dart';
import 'package:morphpdf/features/ai/domain/document_analysis_model.dart';
import 'package:morphpdf/features/ai/presentation/ai_result_screen.dart';
import 'package:morphpdf/features/ai/presentation/ai_screen.dart';
import 'package:morphpdf/features/settings/presentation/settings_screen.dart';

class FailingAiProvider implements AiProvider {
  final Exception exception;
  FailingAiProvider(this.exception);

  @override
  String get providerName => 'Failing';
  @override
  Future<DocumentAnalysisModel> analyzeStructured(String text, {String? instructions}) async => throw exception;
  @override
  Future<String> analyzeDocument(String text, {String? instructions}) async => throw exception;
  @override
  Future<String> correctText(String text, {String? context}) async => throw exception;
  @override
  Future<String> summarizeDocument(String text, {int maxLength = 500}) async => throw exception;
  @override
  Future<String> extractStructuredData(String text, {String? schema}) async => throw exception;
  @override
  Future<String> translateText(String text, {required String targetLanguage}) async => throw exception;
  @override
  Future<String> chat(String message, {List<Map<String, String>>? history}) async => throw exception;
}

void main() {
  group('AI Screens & States Tests', () {
    testWidgets('AiScreen renders all action chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AiScreen(aiService: AiService(OpenRouterProviderMock())),
        ),
      );

      expect(find.text('Assistant IA PDF'), findsOneWidget);
      expect(find.text('Analyser le document'), findsOneWidget);
      expect(find.text('Corriger le texte'), findsOneWidget);
      expect(find.text('Résumer'), findsOneWidget);
      expect(find.text('Extraire les informations'), findsOneWidget);
      expect(find.text('Traduire'), findsOneWidget);
    });

    testWidgets('AiScreen handles offline error gracefully', (tester) async {
      final offlineService = AiService(FailingAiProvider(const NetworkException()));

      await tester.pumpWidget(
        MaterialApp(
          home: AiScreen(aiService: offlineService),
        ),
      );

      // Enter text and tap Summarize
      await tester.enterText(find.byType(TextField).first, 'Document text');
      await tester.tap(find.text('Résumer'));
      await tester.pumpAndSettle();

      expect(find.text('Connexion Internet requise pour l\'IA.'), findsOneWidget);
    });

    testWidgets('AiScreen success state displays result', (tester) async {
      final service = AiService(OpenRouterProviderMock());

      await tester.pumpWidget(
        MaterialApp(
          home: AiScreen(aiService: service),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Texte à corriger');
      await tester.tap(find.text('Corriger le texte'));
      await tester.pumpAndSettle();

      expect(find.text('Résultat IA'), findsOneWidget);
      expect(find.textContaining('Mock Correction:'), findsOneWidget);
    });

    testWidgets('AiResultScreen displays structured cards', (tester) async {
      const result = DocumentAnalysisModel(
        summary: 'Résumé exécutif du document de test.',
        language: 'fr',
        documentType: 'Facture',
        importantInformation: ['TVA 20%', 'Échéance 30 jours'],
        dates: ['04/10/2026'],
        amounts: ['1 200,00 €'],
        people: ['Jean Valjean'],
        organizations: ['Société Générale'],
        issues: ['Paiement en retard'],
        suggestions: ['Relancer le client'],
      );

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AiResultScreen(result: result, pageCount: 2),
        ),
      );

      expect(find.text('Rapport d\'analyse IA'), findsOneWidget);
      expect(find.text('Facture'), findsOneWidget);
      expect(find.text('Résumé exécutif du document de test.'), findsOneWidget);
      expect(find.text('Informations Importantes'), findsOneWidget);
      expect(find.text('1 200,00 €'), findsOneWidget);
      expect(find.text('04/10/2026'), findsOneWidget);
      expect(find.text('Points d\'attention / Problèmes détectés'), findsOneWidget);
      expect(find.text('Suggestions & Actions Recommandées'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays AI provider status without leaking secret', (tester) async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/ai/status')) {
          return http.Response(
            '{"success": true, "data": {"provider": "OpenRouter", "configured": true, "model": "meta-llama/llama-3.3-70b-instruct:free"}, "error": null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp, baseUrl: 'http://127.0.0.1:8080/api/v1');

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(apiClient: apiClient),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Intelligence Artificielle'), findsOneWidget);
      expect(find.text('OpenRouter (Orchestré côté serveur Go)'), findsOneWidget);
      expect(find.text('OpenRouter configuré'), findsOneWidget);
      expect(find.text('meta-llama/llama-3.3-70b-instruct:free'), findsOneWidget);
      // Verify no key prefix or bearer token in widget tree
      expect(find.textContaining('sk-or-'), findsNothing);
      expect(find.textContaining('Bearer'), findsNothing);
    });
  });
}
