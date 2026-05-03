// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // SharedPreferences keys
  static const String keyServerIp = 'server_ip';
  static const String keyServerPort = 'server_port';

  // Default values
  static const String defaultPort = '8005';

  // API paths — appended after http://{ip}:{port}
  static const String healthEndpoint = '/cameras/health';
  static const String camerasEndpoint = '/cameras/';
  static const String uploadEndpoint = '/cameras/upload';
  static const String startStreamEndpoint = '/cameras/start-stream';

  static String cameraStatusEndpoint(String camId) => '/cameras/$camId/status';
  static String cameraResultEndpoint(String camId) => '/cameras/$camId/result';
  static String cameraVideoEndpoint(String camId) => '/cameras/$camId/video';
  static String cameraSnapshotEndpoint(String camId) => '/cameras/$camId/snapshot';
  static String cameraHistoryEndpoint(String camId) => '/cameras/$camId/history';
  static String deleteCameraEndpoint(String camId) => '/cameras/$camId';

  // Polling intervals
  static const Duration cameraListPollInterval = Duration(seconds: 5);
  static const Duration liveResultPollInterval = Duration(seconds: 1);

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
