// lib/presentation/blocs/register_camera_bloc.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fire_detailer/core/constants/app_constants.dart';
import 'package:fire_detailer/data/models/camera_model.dart';
import '../../../../data/datasources/api_datasource.dart';

// ── Events ──
abstract class RegisterCameraEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterWithVideoRequested extends RegisterCameraEvent {
  final String camId;
  final String filePath;
  final int frameSkip;

  RegisterWithVideoRequested({
    required this.camId,
    required this.filePath,
    required this.frameSkip,
  });

  @override
  List<Object?> get props => [camId, filePath, frameSkip];
}

class RegisterWithStreamRequested extends RegisterCameraEvent {
  final String camId;
  final String url;
  final int frameSkip;

  RegisterWithStreamRequested({
    required this.camId,
    required this.url,
    required this.frameSkip,
  });

  @override
  List<Object?> get props => [camId, url, frameSkip];
}

class RegisterFormReset extends RegisterCameraEvent {}

// ── States ──
abstract class RegisterCameraState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterCameraInitial extends RegisterCameraState {}
class RegisterCameraLoading extends RegisterCameraState {}

class RegisterCameraSuccess extends RegisterCameraState {
  final String camId;
  final String message;

  RegisterCameraSuccess({required this.camId, required this.message});

  @override
  List<Object?> get props => [camId, message];
}

class RegisterCameraFailure extends RegisterCameraState {
  final String message;
  RegisterCameraFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class RegisterCameraBloc extends Bloc<RegisterCameraEvent, RegisterCameraState> {
  final ApiDataSource _api;

  RegisterCameraBloc({required ApiDataSource api})
      : _api = api,
        super(RegisterCameraInitial()) {
    on<RegisterWithVideoRequested>(_onVideoUpload);
    on<RegisterWithStreamRequested>(_onStreamStart);
    on<RegisterFormReset>(_onReset);
  }

  Future<void> _onVideoUpload(
    RegisterWithVideoRequested event,
    Emitter<RegisterCameraState> emit,
  ) async {
    emit(RegisterCameraLoading());
    try {
      final result = await _api.uploadVideo(
        camId: event.camId,
        filePath: event.filePath,
        frameSkip: event.frameSkip,
      );
      emit(RegisterCameraSuccess(
        camId: event.camId,
        message: result['message'] ?? 'Camera registered successfully',
      ));
    } on Exception catch (e) {
      emit(RegisterCameraFailure(_parseError(e)));
    }
  }

  Future<void> _onStreamStart(
    RegisterWithStreamRequested event,
    Emitter<RegisterCameraState> emit,
  ) async {
    emit(RegisterCameraLoading());
    try {
      final result = await _api.startStream(
        camId: event.camId,
        url: event.url,
        frameSkip: event.frameSkip,
      );
      emit(RegisterCameraSuccess(
        camId: event.camId,
        message: result['message'] ?? 'Stream started successfully',
      ));
    } on Exception catch (e) {
      emit(RegisterCameraFailure(_parseError(e)));
    }
  }

  void _onReset(RegisterFormReset event, Emitter<RegisterCameraState> emit) {
    emit(RegisterCameraInitial());
  }

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('400')) return 'Invalid file type or missing fields.';
    if (msg.contains('500')) return 'Server failed to start stream. Check logs.';
    return 'Registration failed: $msg';
  }
}

// ═══════════════════════════════════════════════════════════
// lib/presentation/blocs/live_view_bloc.dart
// ═══════════════════════════════════════════════════════════

// ── Events ──
abstract class LiveViewEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LiveViewStarted extends LiveViewEvent {
  final String camId;
  LiveViewStarted(this.camId);
  @override
  List<Object?> get props => [camId];
}

class LiveViewPollingTick extends LiveViewEvent {}
class LiveViewStopped extends LiveViewEvent {}

// ── States ──
abstract class LiveViewState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LiveViewInitial extends LiveViewState {}
class LiveViewLoading extends LiveViewState {}

class LiveViewUpdated extends LiveViewState {
  final CameraResult result;
  LiveViewUpdated(this.result);
  @override
  List<Object?> get props => [result];
}

class LiveViewError extends LiveViewState {
  final String message;
  LiveViewError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class LiveViewBloc extends Bloc<LiveViewEvent, LiveViewState> {
  final ApiDataSource _api;
  Timer? _timer;
  String? _camId;

  LiveViewBloc({required ApiDataSource api})
      : _api = api,
        super(LiveViewInitial()) {
    on<LiveViewStarted>(_onStarted);
    on<LiveViewPollingTick>(_onTick);
    on<LiveViewStopped>(_onStopped);
  }

  Future<void> _onStarted(LiveViewStarted event, Emitter<LiveViewState> emit) async {
    _camId = event.camId;
    emit(LiveViewLoading());
    await _fetchResult(emit);
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.liveResultPollInterval, (_) {
      add(LiveViewPollingTick());
    });
  }

  Future<void> _onTick(LiveViewPollingTick event, Emitter<LiveViewState> emit) async {
    if (_camId != null) await _fetchResult(emit);
  }

  void _onStopped(LiveViewStopped event, Emitter<LiveViewState> emit) {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchResult(Emitter<LiveViewState> emit) async {
    try {
      final result = await _api.getCameraResult(_camId!);
      emit(LiveViewUpdated(result));
    } on Exception catch (e) {
      emit(LiveViewError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

// ═══════════════════════════════════════════════════════════
// lib/presentation/blocs/fire_logs_bloc.dart
// ═══════════════════════════════════════════════════════════

// ── Events ──
abstract class FireLogsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FireLogsRequested extends FireLogsEvent {
  final String camId;
  final int limit;
  FireLogsRequested({required this.camId, this.limit = 100});
  @override
  List<Object?> get props => [camId, limit];
}

class FireLogsRefreshed extends FireLogsEvent {}

// ── States ──
abstract class FireLogsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FireLogsInitial extends FireLogsState {}
class FireLogsLoading extends FireLogsState {}

class FireLogsLoaded extends FireLogsState {
  final HistoryModel history;
  FireLogsLoaded(this.history);
  @override
  List<Object?> get props => [history];
}

class FireLogsError extends FireLogsState {
  final String message;
  FireLogsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class FireLogsBloc extends Bloc<FireLogsEvent, FireLogsState> {
  final ApiDataSource _api;
  String? _camId;
  int _limit = 100;

  FireLogsBloc({required ApiDataSource api})
      : _api = api,
        super(FireLogsInitial()) {
    on<FireLogsRequested>(_onRequested);
    on<FireLogsRefreshed>(_onRefreshed);
  }

  Future<void> _onRequested(FireLogsRequested event, Emitter<FireLogsState> emit) async {
    _camId = event.camId;
    _limit = event.limit;
    emit(FireLogsLoading());
    await _fetchLogs(emit);
  }

  Future<void> _onRefreshed(FireLogsRefreshed event, Emitter<FireLogsState> emit) async {
    if (_camId != null) await _fetchLogs(emit);
  }

  Future<void> _fetchLogs(Emitter<FireLogsState> emit) async {
    try {
      final history = await _api.getCameraHistory(_camId!, limit: _limit);
      emit(FireLogsLoaded(history));
    } on Exception catch (e) {
      emit(FireLogsError(e.toString()));
    }
  }
}
