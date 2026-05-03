// lib/data/datasources/server_config_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

class ServerConfigService {
  static String _baseUrl = '';

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String ip, String port) {
    _baseUrl = 'http://$ip:$port';
  }

  static Future<void> saveToPrefs(String ip, String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyServerIp, ip);
    await prefs.setString(AppConstants.keyServerPort, port);
  }

  static Future<({String ip, String port})?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(AppConstants.keyServerIp);
    final port = prefs.getString(AppConstants.keyServerPort);
    if (ip != null && ip.isNotEmpty) {
      return (ip: ip, port: port ?? AppConstants.defaultPort);
    }
    return null;
  }

  static String buildUrl(String path) => '$_baseUrl$path';
}
