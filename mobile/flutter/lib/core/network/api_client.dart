import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../app/config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  final http.Client _httpClient;
  final String _baseUrl;
  final Duration _timeout;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Duration? timeout,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.current.apiBaseUrl,
        _timeout = timeout ?? AppConfig.current.connectTimeout;

  String get baseUrl => _baseUrl;

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await _httpClient.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'HTTP_ERROR', message: e.toString());
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'HTTP_ERROR', message: e.toString());
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      throw ApiException(
        code: 'INVALID_JSON',
        message: 'Invalid response from server (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  // --- API Contracts ---

  /// GET /health
  Future<ApiResponse<Map<String, dynamic>>> health() async {
    final json = await _get('/health');
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /documents/analyze
  Future<ApiResponse<Map<String, dynamic>>> analyzeDocument(String documentId) async {
    final json = await _post('/documents/analyze', body: {'documentId': documentId});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ocr/extract
  Future<ApiResponse<Map<String, dynamic>>> extractOcr(String filePath, {String lang = 'en'}) async {
    final json = await _post('/ocr/extract', body: {'filePath': filePath, 'language': lang});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// GET /ai/status
  Future<ApiResponse<Map<String, dynamic>>> getAiStatus() async {
    final json = await _get('/ai/status');
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ai/chat
  Future<ApiResponse<Map<String, dynamic>>> chatAi(String message, {List<Map<String, String>>? history}) async {
    final json = await _post('/ai/chat', body: {'message': message, 'history': history ?? []});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ai/analyze
  Future<ApiResponse<Map<String, dynamic>>> analyzeAi(String text, {String? instructions}) async {
    final json = await _post('/ai/analyze', body: {'text': text, 'instructions': instructions});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ai/correct
  Future<ApiResponse<Map<String, dynamic>>> correctText(String text, {String? context}) async {
    final json = await _post('/ai/correct', body: {'text': text, 'context': context});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ai/summarize
  Future<ApiResponse<Map<String, dynamic>>> summarize(String text, {int maxLength = 500}) async {
    final json = await _post('/ai/summarize', body: {'text': text, 'maxLength': maxLength});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ai/extract
  Future<ApiResponse<Map<String, dynamic>>> extractAi(String text, {String? schema}) async {
    final json = await _post('/ai/extract', body: {'text': text, 'schema': schema});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /ai/translate
  Future<ApiResponse<Map<String, dynamic>>> translateAi(String text, {required String targetLanguage}) async {
    final json = await _post('/ai/translate', body: {'text': text, 'target_language': targetLanguage});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /pdf/clean
  Future<ApiResponse<Map<String, dynamic>>> cleanPdf(String documentId) async {
    final json = await _post('/pdf/clean', body: {'documentId': documentId});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /pdf/merge
  Future<ApiResponse<Map<String, dynamic>>> mergePdf(List<String> documentIds) async {
    final json = await _post('/pdf/merge', body: {'documentIds': documentIds});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /pdf/split
  Future<ApiResponse<Map<String, dynamic>>> splitPdf(String documentId, List<int> pages) async {
    final json = await _post('/pdf/split', body: {'documentId': documentId, 'pages': pages});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /conversion/pdf-to-word
  Future<ApiResponse<Map<String, dynamic>>> convertPdfToWord(String documentId) async {
    final json = await _post('/conversion/pdf-to-word', body: {'documentId': documentId});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  /// POST /export
  Future<ApiResponse<Map<String, dynamic>>> exportDocument(String documentId, String format) async {
    final json = await _post('/export', body: {'documentId': documentId, 'format': format});
    return ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);
  }

  void close() {
    _httpClient.close();
  }
}
