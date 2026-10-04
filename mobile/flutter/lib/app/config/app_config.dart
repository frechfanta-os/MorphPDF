enum Environment { development, testing, production }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  static AppConfig current = development;

  static const AppConfig development = AppConfig(
    environment: Environment.development,
    // Android emulator: 10.0.2.2, on-device loopback or LAN configurable
    apiBaseUrl: 'http://127.0.0.1:8080/api/v1',
  );

  static const AppConfig testing = AppConfig(
    environment: Environment.testing,
    apiBaseUrl: 'http://127.0.0.1:8080/api/v1',
  );

  static const AppConfig production = AppConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.morphpdf.ghdinteractivestudio.com/api/v1',
  );
}
