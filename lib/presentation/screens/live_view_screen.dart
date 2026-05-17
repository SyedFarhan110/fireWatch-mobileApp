// lib/presentation/screens/live_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/other_blocs.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../data/datasources/api_datasource.dart';
import '../../../../data/models/camera_model.dart';

class LiveViewScreen extends StatefulWidget {
  final String camId;
  const LiveViewScreen({super.key, required this.camId});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  // MJPEG streams don't work natively in Flutter Image widget.
  // We poll /snapshot every second and swap the image — same visual effect.
  // For true MJPEG, use webview_flutter package and load the /video URL.
  int _snapshotRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    context.read<LiveViewBloc>().add(LiveViewStarted(widget.camId));
    // Refresh snapshot image every second
    _startSnapshotRefresh();
  }

  void _startSnapshotRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _snapshotRefreshKey++);
      return true;
    });
  }

  @override
  void dispose() {
    context.read<LiveViewBloc>().add(LiveViewStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiDataSource>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.camId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Fire Logs',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.fireLogs,
              arguments: widget.camId,
            ),
          ),
        ],
      ),
      body: BlocBuilder<LiveViewBloc, LiveViewState>(
        builder: (context, state) {
          return Column(
            children: [
              // ── Video feed ──
              _VideoFeedSection(
                camId: widget.camId,
                api: api,
                refreshKey: _snapshotRefreshKey,
                isFireDetected: state is LiveViewUpdated && state.result.fireDetected,
              ),

              // ── Stats panel ──
              Expanded(
                child: _StatsPanel(state: state, camId: widget.camId),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoFeedSection extends StatelessWidget {
  final String camId;
  final ApiDataSource api;
  final int refreshKey;
  final bool isFireDetected;

  const _VideoFeedSection({
    required this.camId,
    required this.api,
    required this.refreshKey,
    required this.isFireDetected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Snapshot image (refreshed every second)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            '${api.snapshotUrl(camId)}?t=$refreshKey',
            fit: BoxFit.cover,
            width: double.infinity,
            gaplessPlayback: true, // prevents flicker on refresh
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF111111),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off_rounded, color: AppTheme.textSecondary, size: 40),
                    SizedBox(height: 8),
                    Text('No feed available',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Fire nature overlay badge (Static / Dynamic)
        if (isFireDetected)
          Positioned(
            top: 12,
            right: 12,
            child: BlocBuilder<LiveViewBloc, LiveViewState>(
              builder: (context, state) {
                final nature = state is LiveViewUpdated
                    ? state.result.fireNature
                    : null;
                final isDynamic = nature == 'dynamic_fire';
                final label = nature == 'static_fire'
                    ? 'STATIC FIRE 🕯️'
                    : 'DYNAMIC FIRE 🔥';
                final badgeColor =
                    isDynamic ? AppTheme.danger : Colors.orange;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),

        // LIVE badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppTheme.danger, size: 8),
                SizedBox(width: 5),
                Text('LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final LiveViewState state;
  final String camId;

  const _StatsPanel({required this.state, required this.camId});

  @override
  Widget build(BuildContext context) {
    if (state is LiveViewLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    if (state is LiveViewError) {
      return Center(
        child: Text(
          (state as LiveViewError).message,
          style: const TextStyle(color: AppTheme.danger),
        ),
      );
    }

    if (state is LiveViewUpdated) {
      final result = (state as LiveViewUpdated).result;
      return _ResultPanel(result: result);
    }

    return const SizedBox.shrink();
  }
}

class _ResultPanel extends StatelessWidget {
  final CameraResult result;
  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final intensity = result.intensity;
    final direction = result.direction;

    return Container(
      color: AppTheme.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frame info
            Row(
              children: [
                Text(
                  'Frame #${result.frame}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${result.detectionCount} detection${result.detectionCount != 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status verdict
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: result.fireDetected
                    ? AppTheme.danger.withOpacity(0.12)
                    : AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: result.fireDetected
                      ? AppTheme.danger.withOpacity(0.3)
                      : AppTheme.success.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.fireDetected
                        ? Icons.local_fire_department_rounded
                        : Icons.check_circle_rounded,
                    color: result.fireDetected ? AppTheme.danger : AppTheme.success,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    result.fireSummary.verdict,
                    style: TextStyle(
                      color: result.fireDetected ? AppTheme.danger : AppTheme.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Intensity',
                    value: intensity.level,
                    sub: '${intensity.coveragePct}% frame',
                    color: _intensityColor(intensity.level),
                    icon: Icons.bar_chart_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Trend',
                    value: result.trend.length > 14
                        ? result.trend.substring(0, 14)
                        : result.trend,
                    sub: 'Over last frames',
                    color: AppTheme.warning,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Fire Nature card (Static / Dynamic)
            _FireNatureCard(
              nature: result.fireNature,
              natureLabel: result.fireNatureLabel,
              fireDetected: result.fireDetected,
            ),

            const SizedBox(height: 10),

            // Direction card
            _DirectionCard(direction: direction),
          ],
        ),
      ),
    );
  }

  Color _intensityColor(String level) {
    switch (level) {
      case 'LOW':
        return AppTheme.warning;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
      case 'CRITICAL':
        return AppTheme.danger;
      default:
        return AppTheme.success;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FireNatureCard extends StatelessWidget {
  final String? nature;
  final String natureLabel;
  final bool fireDetected;

  const _FireNatureCard({
    required this.nature,
    required this.natureLabel,
    required this.fireDetected,
  });

  @override
  Widget build(BuildContext context) {
    if (!fireDetected) return const SizedBox.shrink();

    final isDynamic = nature == 'dynamic_fire';
    final color = isDynamic ? AppTheme.danger : Colors.orange;
    final icon = isDynamic
        ? Icons.local_fire_department_rounded
        : Icons.whatshot_outlined;
    final subLabel = isDynamic
        ? 'Spreading or growing — hazardous'
        : 'Contained, stable flame — not hazardous';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fire Nature',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  natureLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final DirectionData direction;
  const _DirectionCard({required this.direction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          // Direction compass indicator
          _CompassIndicator(horizontal: direction.horizontal, vertical: direction.vertical),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Direction',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(direction.direction,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Zone: ${direction.zone}  •  ${direction.movementPx.toStringAsFixed(1)}px',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassIndicator extends StatelessWidget {
  final String horizontal;
  final String vertical;

  const _CompassIndicator({required this.horizontal, required this.vertical});

  @override
  Widget build(BuildContext context) {
    // Map direction to angle offset for dot
    double dx = 0;
    double dy = 0;
    if (horizontal == 'right') dx = 1;
    if (horizontal == 'left') dx = -1;
    if (vertical == 'up') dy = -1;
    if (vertical == 'down') dy = 1;

    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _CompassPainter(dx: dx, dy: dy),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double dx;
  final double dy;

  _CompassPainter({required this.dx, required this.dy});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Outer circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Center dot
    canvas.drawCircle(center, 2, Paint()..color = AppTheme.textSecondary);

    // Direction dot
    if (dx != 0 || dy != 0) {
      final dotOffset = Offset(
        center.dx + dx * (radius - 8),
        center.dy + dy * (radius - 8),
      );
      canvas.drawCircle(dotOffset, 6, Paint()..color = AppTheme.danger);

      // Line from center to dot
      canvas.drawLine(
        center,
        dotOffset,
        Paint()
          ..color = AppTheme.danger.withOpacity(0.5)
          ..strokeWidth = 1.5,
      );
    } else {
      // Stable — center dot highlighted
      canvas.drawCircle(center, 5, Paint()..color = AppTheme.success);
    }
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.dx != dx || old.dy != dy;
}
