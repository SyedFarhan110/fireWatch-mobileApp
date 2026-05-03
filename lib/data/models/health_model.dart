// lib/data/models/health_model.dart

class HealthModel {
  final String status;
  final String message;
  final String timestamp;
  final int activeCameras;
  final GpuInfo gpu;
  final CpuInfo cpu;
  final RamInfo ram;

  const HealthModel({
    required this.status,
    required this.message,
    required this.timestamp,
    required this.activeCameras,
    required this.gpu,
    required this.cpu,
    required this.ram,
  });

  bool get isOk => status == 'ok';

  factory HealthModel.fromJson(Map<String, dynamic> json) => HealthModel(
        status: json['status'] ?? 'error',
        message: json['message'] ?? '',
        timestamp: json['timestamp'] ?? '',
        activeCameras: json['active_cameras'] ?? 0,
        gpu: GpuInfo.fromJson(json['gpu'] ?? {}),
        cpu: CpuInfo.fromJson(json['cpu'] ?? {}),
        ram: RamInfo.fromJson(json['ram'] ?? {}),
      );
}

class GpuInfo {
  final bool available;
  final String? name;
  final int? usedMb;
  final int? totalMb;

  const GpuInfo({required this.available, this.name, this.usedMb, this.totalMb});

  factory GpuInfo.fromJson(Map<String, dynamic> json) => GpuInfo(
        available: json['available'] ?? false,
        name: json['name'],
        usedMb: json['memory']?['used_mb'],
        totalMb: json['memory']?['total_mb'],
      );
}

class CpuInfo {
  final double usagePercent;
  final int cores;

  const CpuInfo({required this.usagePercent, required this.cores});

  factory CpuInfo.fromJson(Map<String, dynamic> json) => CpuInfo(
        usagePercent: (json['usage_percent'] ?? 0).toDouble(),
        cores: json['cores'] ?? 0,
      );
}

class RamInfo {
  final int totalMb;
  final int usedMb;
  final double usagePercent;

  const RamInfo({required this.totalMb, required this.usedMb, required this.usagePercent});

  factory RamInfo.fromJson(Map<String, dynamic> json) => RamInfo(
        totalMb: json['total_mb'] ?? 0,
        usedMb: json['used_mb'] ?? 0,
        usagePercent: (json['usage_percent'] ?? 0).toDouble(),
      );
}
