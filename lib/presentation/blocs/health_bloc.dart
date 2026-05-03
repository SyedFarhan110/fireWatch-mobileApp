// lib/presentation/blocs/health/health_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/api_datasource.dart';
import '../../data/datasources/server_config_service.dart';
import '../../data/models/health_model.dart';
import '../../core/constants/app_constants.dart';

// ── Events ──
abstract class HealthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HealthCheckRequested extends HealthEvent {
  final String ip;
  final String port;

  HealthCheckRequested({required this.ip, required this.port});

  @override
  List<Object?> get props => [ip, port];
}

// ── States ──
abstract class HealthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthSuccess extends HealthState {
  final HealthModel health;
  final bool hasCameras; // true → skip to camera list, false → go to register

  HealthSuccess(this.health, {required this.hasCameras});

  @override
  List<Object?> get props => [health, hasCameras];
}

class HealthFailure extends HealthState {
  final String message;

  HealthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final ApiDataSource _api;

  HealthBloc({required ApiDataSource api})
    : _api = api,
      super(HealthInitial()) {
    on<HealthCheckRequested>(_onHealthCheckRequested);
  }

  Future<void> _onHealthCheckRequested(
    HealthCheckRequested event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthLoading());
    try {
      ServerConfigService.setBaseUrl(event.ip, event.port);
      final health = await _api.checkHealth();
      if (health.isOk) {
        await ServerConfigService.saveToPrefs(event.ip, event.port);
        // health.activeCameras comes from len(streams) on the server
        emit(HealthSuccess(health, hasCameras: health.activeCameras > 0));
      } else {
        emit(HealthFailure('Server returned unhealthy status'));
      }
    } on Exception catch (e) {
      emit(HealthFailure(_parseError(e)));
    }
  }

  String _parseError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection refused') || msg.contains('socket')) {
      return 'Cannot reach server. Check IP and port.';
    } else if (msg.contains('timeout')) {
      return 'Connection timed out. Is the Jetson on?';
    }
    return 'Failed to connect: ${e.toString()}';
  }
}
