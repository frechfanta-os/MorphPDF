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

    test('analyzeDocument() parses stubbed response correctly', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'data': null,
            'error': {
              'code': 'NOT_IMPLEMENTED',
              'message': 'Endpoint /api/v1/documents/analyze is not implemented yet in this phase',
            },
          }),
          501,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(httpClient: mockHttp, baseUrl: 'http://127.0.0.1:8080/api/v1');
      final res = await client.analyzeDocument('doc-1');

      expect(res.success, isFalse);
      expect(res.data, isNull);
      expect(res.error?.code, 'NOT_IMPLEMENTED');
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
