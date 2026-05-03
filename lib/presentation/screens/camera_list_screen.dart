// lib/presentation/screens/camera_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../blocs/camera_list_bloc.dart';
import '../../data/models/camera_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/api_datasource.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({super.key});

  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<CameraListBloc>();
    bloc.add(CameraListStarted());
    bloc.add(CameraListPollingStarted());
  }

  @override
  void dispose() {
    context.read<CameraListBloc>().add(CameraListPollingStoped());
    super.dispose();
  }

  void _confirmRegisterAgain(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Register Camera Again?'),
        content: const Text(
          'This will stop all running camera jobs and take you to the registration screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // Stop all jobs then navigate
              context.read<CameraListBloc>()
                ..add(CameraListPollingStoped())
                ..add(CameraDeleteAllRequested());
              Navigator.pushReplacementNamed(context, AppRouter.registerCamera);
            },
            child: const Text(
              'Stop All & Register',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cameras'),
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Change server',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRouter.serverConfig),
        ),
        actions: [
          // Register camera again — stops all jobs, goes to register screen
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Register Camera Again',
            onPressed: () => _confirmRegisterAgain(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<CameraListBloc>().add(
              CameraListRefreshRequested(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.registerCamera),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Camera'),
      ),
      body: BlocBuilder<CameraListBloc, CameraListState>(
        builder: (context, state) {
          if (state is CameraListLoading) {
            return _ShimmerList();
          }
          if (state is CameraListError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<CameraListBloc>().add(CameraListStarted()),
            );
          }
          if (state is CameraListLoaded) {
            if (state.cameras.isEmpty) {
              return _EmptyView(
                onAdd: () =>
                    Navigator.pushNamed(context, AppRouter.registerCamera),
              );
            }
            return _CameraGrid(cameras: state.cameras);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CameraGrid extends StatelessWidget {
  final List<CameraModel> cameras;
  const _CameraGrid({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: () async {
        context.read<CameraListBloc>().add(CameraListRefreshRequested());
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: cameras.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _CameraCard(camera: cameras[index]),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final CameraModel camera;
  const _CameraCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiDataSource>();
    final isFireDetected = camera.fireDetected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Status indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: camera.running
                        ? (isFireDetected ? AppTheme.danger : AppTheme.success)
                        : AppTheme.textSecondary,
                    boxShadow: camera.running
                        ? [
                            BoxShadow(
                              color:
                                  (isFireDetected
                                          ? AppTheme.danger
                                          : AppTheme.success)
                                      .withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    camera.camId,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Source type badge
                _Badge(
                  label: camera.sourceType == 'video' ? 'VIDEO' : 'LIVE',
                  color: camera.sourceType == 'video'
                      ? AppTheme.accent
                      : AppTheme.warning,
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: () => _confirmDelete(context, camera.camId),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Snapshot preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                api.snapshotUrl(camera.camId),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                headers: const {},
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppTheme.surface,
                  child: const Center(
                    child: Icon(
                      Icons.videocam_off_rounded,
                      color: AppTheme.textSecondary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  label: isFireDetected ? 'Fire' : 'Clear',
                  color: isFireDetected ? AppTheme.danger : AppTheme.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.trending_up_rounded,
                  label: camera.latestTrend.length > 12
                      ? camera.latestTrend.substring(0, 12)
                      : camera.latestTrend,
                  color: AppTheme.warning,
                ),
                const Spacer(),
                Text(
                  '${camera.framesProcessed} frames',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.fireLogs,
                      arguments: camera.camId,
                    ),
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                    label: const Text('See Logs'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRouter.liveView,
                      arguments: camera.camId,
                    ),
                    icon: const Icon(Icons.play_circle_rounded, size: 16),
                    label: const Text('Visualize'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: isFireDetected
                          ? AppTheme.danger
                          : AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String camId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Remove Camera'),
        content: Text('Remove "$camId" from monitoring?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CameraListBloc>().add(CameraDeleteRequested(camId));
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.surface,
        highlightColor: AppTheme.card,
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No cameras registered',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a camera to start monitoring',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Camera'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
