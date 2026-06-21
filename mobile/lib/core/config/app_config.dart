/// Configuración por ambiente vía --dart-define.
///
/// Ejemplo desarrollo (emulador Android):
/// flutter run --dart-define=ENV=dev \
///   --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.appName,
  });

  final String env;
  final String apiBaseUrl;
  final String appName;

  bool get isDev => env == 'dev';
  bool get isProd => env == 'prod';

  static AppConfig fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    );
    const appName =
        String.fromEnvironment('APP_NAME', defaultValue: 'VoluntApp');

    return AppConfig(env: env, apiBaseUrl: apiBaseUrl, appName: appName);
  }
}
