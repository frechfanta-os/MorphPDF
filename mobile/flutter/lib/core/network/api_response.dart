import 'api_exception.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiException? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? fromJsonData,
  ) {
    final success = json['success'] as bool? ?? false;
    final dynamic rawData = json['data'];
    final dynamic rawError = json['error'];

    ApiException? error;
    if (rawError != null && rawError is Map<String, dynamic>) {
      error = ApiException(
        code: rawError['code'] as String? ?? 'UNKNOWN_ERROR',
        message: rawError['message'] as String? ?? 'Une erreur est survenue',
      );
    }

    T? parsedData;
    if (success && rawData != null && fromJsonData != null) {
      parsedData = fromJsonData(rawData);
    } else if (success && rawData != null && rawData is T) {
      parsedData = rawData;
    }

    return ApiResponse(
      success: success,
      data: parsedData,
      error: error,
    );
  }
}
