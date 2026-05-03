// lib/data/datasources/api_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/models/health_model.dart';
import '../../data/models/camera_model.dart';
import '../../../../core/constants/app_constants.dart';
import 'server_config_service.dart';

class ApiDataSource {
  late final Dio _dio;

  ApiDataSource() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => null, // silence in prod; replace with logger
    ));
  }

  // ── Health ──────────────────────────────────────────────
  Future<HealthModel> checkHealth() async {
    final response = await _dio.get(
      ServerConfigService.buildUrl(AppConstants.healthEndpoint),
    );
    return HealthModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Cameras ─────────────────────────────────────────────
  Future<List<CameraModel>> listCameras() async {
    final response = await _dio.get(
      ServerConfigService.buildUrl(AppConstants.camerasEndpoint),
    );
    final data = response.data as Map<String, dynamic>;
    return (data['cameras'] as List<dynamic>)
        .map((e) => CameraModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> uploadVideo({
    required String camId,
    required String filePath,
    required int frameSkip,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      ServerConfigService.buildUrl(AppConstants.uploadEndpoint),
      queryParameters: {'cam_id': camId, 'frame_skip': frameSkip},
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 5), // uploads can be slow
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startStream({
    required String camId,
    required String url,
    required int frameSkip,
  }) async {
    final response = await _dio.post(
      ServerConfigService.buildUrl(AppConstants.startStreamEndpoint),
      queryParameters: {'cam_id': camId, 'url': url, 'frame_skip': frameSkip},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<CameraResult> getCameraResult(String camId) async {
    final response = await _dio.get(
      ServerConfigService.buildUrl(AppConstants.cameraResultEndpoint(camId)),
    );
    return CameraResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HistoryModel> getCameraHistory(String camId, {int limit = 100}) async {
    final response = await _dio.get(
      ServerConfigService.buildUrl(AppConstants.cameraHistoryEndpoint(camId)),
      queryParameters: {'limit': limit},
    );
    return HistoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCamera(String camId) async {
    await _dio.delete(
      ServerConfigService.buildUrl(AppConstants.deleteCameraEndpoint(camId)),
    );
  }

  // Snapshot URL for WebView/Image widget (returns full URL string)
  String snapshotUrl(String camId) =>
      ServerConfigService.buildUrl(AppConstants.cameraSnapshotEndpoint(camId));

  // MJPEG video URL for display
  String videoUrl(String camId, {int fps = 10}) =>
      '${ServerConfigService.buildUrl(AppConstants.cameraVideoEndpoint(camId))}?fps=$fps';
}
