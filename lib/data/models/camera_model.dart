// lib/data/models/camera_model.dart

class CameraModel {
  final String camId;
  final String sourceType;
  final bool running;
  final int framesProcessed;
  final bool fireDetected;
  final String statusLabel;
  final double latestIntensity;
  final String latestTrend;
  final String snapshotUrl;
  final String videoUrl;

  const CameraModel({
    required this.camId,
    required this.sourceType,
    required this.running,
    required this.framesProcessed,
    required this.fireDetected,
    required this.statusLabel,
    required this.latestIntensity,
    required this.latestTrend,
    required this.snapshotUrl,
    required this.videoUrl,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) => CameraModel(
    camId: json['cam_id'] ?? '',
    sourceType: json['source_type'] ?? 'unknown',
    running: json['running'] ?? false,
    framesProcessed: json['frames_processed'] ?? 0,
    fireDetected: json['fire_detected'] ?? false,
    statusLabel: json['status_label'] ?? 'Unknown',
    latestIntensity: _parseIntensity(json['latest_intensity']),
    latestTrend: json['latest_trend'] ?? 'N/A',
    snapshotUrl: json['snapshot_url'] ?? '',
    videoUrl: json['video_url'] ?? '',
  );

  /// Handles both cases:
  /// - Server returns intensity as a plain number (old)
  /// - Server returns intensity as a dict {"raw_area":..., "level":...} (new)
  static double _parseIntensity(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map) {
      final rawArea = value['raw_area'];
      if (rawArea is num) return rawArea.toDouble();
      final coverage = value['coverage_pct'];
      if (coverage is num) return coverage.toDouble();
    }
    return 0.0;
  }
}

class CameraResult {
  final int frame;
  final String camId;
  final bool fireDetected;
  final String? fireNature;       // "static_fire" | "dynamic_fire" | null
  final String fireNatureLabel;   // Human-readable e.g. "Static Fire 🕯️ (Non-Hazardous)"
  final IntensityData intensity;
  final String trend;
  final DirectionData direction;
  final int detectionCount;
  final FireSummary fireSummary;

  const CameraResult({
    required this.frame,
    required this.camId,
    required this.fireDetected,
    this.fireNature,
    required this.fireNatureLabel,
    required this.intensity,
    required this.trend,
    required this.direction,
    required this.detectionCount,
    required this.fireSummary,
  });

  factory CameraResult.fromJson(Map<String, dynamic> json) => CameraResult(
    frame: json['frame'] ?? 0,
    camId: json['cam_id'] ?? '',
    fireDetected: json['fire_detected'] ?? false,
    fireNature: json['fire_nature'] as String?,
    fireNatureLabel: json['fire_nature_label'] ?? 'No Fire ✅',
    intensity: IntensityData.fromJson(json['intensity'] ?? {}),
    trend: json['trend'] ?? 'N/A',
    direction: DirectionData.fromJson(json['direction'] ?? {}),
    detectionCount: json['detection_count'] ?? 0,
    fireSummary: FireSummary.fromJson(json['fire_summary'] ?? {}),
  );
}

class IntensityData {
  final double rawArea;
  final double coveragePct;
  final String level;
  final int levelScore;
  final int validBoxCount;

  const IntensityData({
    required this.rawArea,
    required this.coveragePct,
    required this.level,
    required this.levelScore,
    required this.validBoxCount,
  });

  factory IntensityData.fromJson(Map<String, dynamic> json) => IntensityData(
    rawArea: (json['raw_area'] ?? 0.0).toDouble(),
    coveragePct: (json['coverage_pct'] ?? 0.0).toDouble(),
    level: json['level'] ?? 'NONE',
    levelScore: json['level_score'] ?? 0,
    validBoxCount: json['valid_box_count'] ?? 0,
  );
}

class DirectionData {
  final String horizontal;
  final String vertical;
  final String direction;
  final double movementPx;
  final String zone;

  const DirectionData({
    required this.horizontal,
    required this.vertical,
    required this.direction,
    required this.movementPx,
    required this.zone,
  });

  factory DirectionData.fromJson(Map<String, dynamic> json) => DirectionData(
    horizontal: json['horizontal'] ?? 'unknown',
    vertical: json['vertical'] ?? 'unknown',
    direction: json['direction'] ?? 'N/A',
    movementPx: (json['movement_px'] ?? 0.0).toDouble(),
    zone: json['zone'] ?? 'unknown',
  );
}

class FireSummary {
  final bool fireDetected;
  final String? fireNature;       // "static_fire" | "dynamic_fire" | null
  final String fireNatureLabel;   // e.g. "Static Fire 🕯️ (Non-Hazardous)"
  final String verdict;
  final dynamic intensity;
  final String trend;

  const FireSummary({
    required this.fireDetected,
    this.fireNature,
    required this.fireNatureLabel,
    required this.verdict,
    required this.intensity,
    required this.trend,
  });

  factory FireSummary.fromJson(Map<String, dynamic> json) => FireSummary(
    fireDetected: json['fire_detected'] ?? false,
    fireNature: json['fire_nature'] as String?,
    fireNatureLabel: json['fire_nature_label'] ?? 'No Fire ✅',
    verdict: json['verdict'] ?? 'N/A',
    intensity: json['intensity'],
    trend: json['trend'] ?? 'N/A',
  );
}

class HistoryModel {
  final String camId;
  final int totalFramesProcessed;
  final FireHistorySummary fireSummary;
  final List<CameraResult> results;

  const HistoryModel({
    required this.camId,
    required this.totalFramesProcessed,
    required this.fireSummary,
    required this.results,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) => HistoryModel(
    camId: json['cam_id'] ?? '',
    totalFramesProcessed: json['total_frames_processed'] ?? 0,
    fireSummary: FireHistorySummary.fromJson(json['fire_summary'] ?? {}),
    results: (json['results'] as List<dynamic>? ?? [])
        .map((e) => CameraResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class FireHistorySummary {
  final bool fireDetectedEver;
  final String verdict;
  final int fireFrameCount;
  final int totalFramesChecked;
  final double firePercentage;
  final int? firstFireFrame;
  final int? lastFireFrame;

  const FireHistorySummary({
    required this.fireDetectedEver,
    required this.verdict,
    required this.fireFrameCount,
    required this.totalFramesChecked,
    required this.firePercentage,
    this.firstFireFrame,
    this.lastFireFrame,
  });

  factory FireHistorySummary.fromJson(Map<String, dynamic> json) =>
      FireHistorySummary(
        fireDetectedEver: json['fire_detected_ever'] ?? false,
        verdict: json['verdict'] ?? 'N/A',
        fireFrameCount: json['fire_frame_count'] ?? 0,
        totalFramesChecked: json['total_frames_checked'] ?? 0,
        firePercentage: (json['fire_percentage'] ?? 0.0).toDouble(),
        firstFireFrame: json['first_fire_frame'],
        lastFireFrame: json['last_fire_frame'],
      );
}
