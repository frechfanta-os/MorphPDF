class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException [$code]: $message (status: $statusCode)';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Erreur réseau ou serveur inaccessible'})
      : super(code: 'NETWORK_ERROR');
}

class TimeoutException extends ApiException {
  const TimeoutException({super.message = 'Délai d’attente dépassé'})
      : super(code: 'TIMEOUT');
}
