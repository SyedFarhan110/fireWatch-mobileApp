// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import '../../../../presentation/screens/server_config_screen.dart';
import '../../../../presentation/screens/register_camera_screen.dart';
import '../../../../presentation/screens/camera_list_screen.dart';
import '../../../../presentation/screens/live_view_screen.dart';
import '../../../../presentation/screens/fire_logs_screen.dart';

class AppRouter {
  AppRouter._();

  static const String serverConfig = '/';
  static const String registerCamera = '/register-camera';
  static const String cameraList = '/camera-list';
  static const String liveView = '/live-view';
  static const String fireLogs = '/fire-logs';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case serverConfig:
        return _buildRoute(const ServerConfigScreen(), settings);

      case registerCamera:
        return _buildRoute(const RegisterCameraScreen(), settings);

      case cameraList:
        return _buildRoute(const CameraListScreen(), settings);

      case liveView:
        final camId = settings.arguments as String;
        return _buildRoute(LiveViewScreen(camId: camId), settings);

      case fireLogs:
        final camId = settings.arguments as String;
        return _buildRoute(FireLogsScreen(camId: camId), settings);

      default:
        return _buildRoute(const ServerConfigScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
