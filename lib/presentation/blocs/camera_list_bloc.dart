// lib/presentation/blocs/camera_list_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/api_datasource.dart';
import '../../data/models/camera_model.dart';
import '../../core/constants/app_constants.dart';

// ── Events ──
abstract class CameraListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CameraListStarted extends CameraListEvent {}

class CameraListRefreshRequested extends CameraListEvent {}

class CameraListPollingStarted extends CameraListEvent {}

class CameraListPollingStoped extends CameraListEvent {}

class CameraDeleteRequested extends CameraListEvent {
  final String camId;
  CameraDeleteRequested(this.camId);
  @override
  List<Object?> get props => [camId];
}

class CameraDeleteAllRequested extends CameraListEvent {}

// ── States ──
abstract class CameraListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CameraListInitial extends CameraListState {}

class CameraListLoading extends CameraListState {}

class CameraListLoaded extends CameraListState {
  final List<CameraModel> cameras;
  CameraListLoaded(this.cameras);
  @override
  List<Object?> get props => [cameras];
}

class CameraListError extends CameraListState {
  final String message;
  CameraListError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──
class CameraListBloc extends Bloc<CameraListEvent, CameraListState> {
  final ApiDataSource _api;
  Timer? _pollingTimer;

  CameraListBloc({required ApiDataSource api})
    : _api = api,
      super(CameraListInitial()) {
    on<CameraListStarted>(_onStarted);
    on<CameraListRefreshRequested>(_onRefresh);
    on<CameraListPollingStarted>(_onPollingStarted);
    on<CameraListPollingStoped>(_onPollingStoped);
    on<CameraDeleteRequested>(_onDeleteCamera);
    on<CameraDeleteAllRequested>(_onDeleteAll);
  }

  Future<void> _onStarted(
    CameraListStarted event,
    Emitter<CameraListState> emit,
  ) async {
    emit(CameraListLoading());
    await _fetchCameras(emit);
  }

  Future<void> _onRefresh(
    CameraListRefreshRequested event,
    Emitter<CameraListState> emit,
  ) async {
    await _fetchCameras(emit);
  }

  void _onPollingStarted(
    CameraListPollingStarted event,
    Emitter<CameraListState> emit,
  ) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(AppConstants.cameraListPollInterval, (_) {
      add(CameraListRefreshRequested());
    });
  }

  void _onPollingStoped(
    CameraListPollingStoped event,
    Emitter<CameraListState> emit,
  ) {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _onDeleteCamera(
    CameraDeleteRequested event,
    Emitter<CameraListState> emit,
  ) async {
    try {
      await _api.deleteCamera(event.camId);
      add(CameraListRefreshRequested());
    } on Exception {
      add(CameraListRefreshRequested());
    }
  }

  Future<void> _onDeleteAll(
    CameraDeleteAllRequested event,
    Emitter<CameraListState> emit,
  ) async {
    // Get current list and delete every camera
    final currentState = state;
    if (currentState is CameraListLoaded) {
      for (final camera in currentState.cameras) {
        try {
          await _api.deleteCamera(camera.camId);
        } on Exception {
          // continue deleting others even if one fails
        }
      }
    }
    emit(CameraListLoaded(const [])); // immediately clear UI
  }

  Future<void> _fetchCameras(Emitter<CameraListState> emit) async {
    try {
      final cameras = await _api.listCameras();
      emit(CameraListLoaded(cameras));
    } on Exception catch (e) {
      emit(CameraListError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
