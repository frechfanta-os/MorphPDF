import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morphpdf/core/network/api_client.dart';
import 'package:morphpdf/core/network/api_response.dart';

void main() {
  group('ApiClient Tests', () {
    test('health() parses valid standard response', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/health')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'status': 'ok', 'service': 'morphpdf', 'version': '1.0.0'},
              'error': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(httpClient: mockHttp, baseUrl: 'http://127.0.0.1:8080/api/v1');
      final res = await client.health();

      expect(res.success, isTrue);
      expect(res.data?['status'], 'ok');
      expect(res.data?['service'], 'morphpdf');
      expect(res.error, isNull);
    });

    test('getAiStatus() parses valid response', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/ai/status')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'provider': 'OpenRouter', 'configured': true, 'model': 'meta-llama/llama-3.3-70b-instruct:free'},
              'error': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(httpClient: mockHttp, baseUrl: 'http://127.0.0.1:8080/api/v1');
      final res = await client.getAiStatus();

      expect(res.success, isTrue);
      expect(res.data?['provider'], 'OpenRouter');
      expect(res.data?['configured'], isTrue);
    });

    test('analyzeAi() parses structured result', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/ai/analyze')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'summary': 'Résumé de document',
                'language': 'fr',
                'document_type': 'Contrat',
                'important_information': ['Important'],
              },
              'error': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(httpClient: mockHttp, baseUrl: 'http://127.0.0.1:8080/api/v1');
      final res = await client.analyzeAi('Mon contrat...');

      expect(res.success, isTrue);
      expect(res.data?['document_type'], 'Contrat');
    });

    test('ApiResponse.fromJson handles manual raw map', () {
      final json = {
        'success': true,
        'data': {'count': 42},
        'error': null,
      };

      final parsed = ApiResponse<Map<String, dynamic>>.fromJson(json, (d) => d as Map<String, dynamic>);
      expect(parsed.success, isTrue);
      expect(parsed.data?['count'], 42);
      expect(parsed.error, isNull);
    });
  });
}
