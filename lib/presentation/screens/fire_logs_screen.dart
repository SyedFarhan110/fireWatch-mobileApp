// lib/presentation/screens/fire_logs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/other_blocs.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/camera_model.dart';

class FireLogsScreen extends StatefulWidget {
  final String camId;
  const FireLogsScreen({super.key, required this.camId});

  @override
  State<FireLogsScreen> createState() => _FireLogsScreenState();
}

class _FireLogsScreenState extends State<FireLogsScreen> {
  int _limit = 100;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() {
    context.read<FireLogsBloc>().add(
          FireLogsRequested(camId: widget.camId, limit: _limit),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs — ${widget.camId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<FireLogsBloc>().add(FireLogsRefreshed()),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Limit',
            color: AppTheme.card,
            onSelected: (val) {
              setState(() => _limit = val);
              context.read<FireLogsBloc>().add(
                    FireLogsRequested(camId: widget.camId, limit: val),
                  );
            },
            itemBuilder: (_) => [50, 100, 200, 500]
                .map((v) => PopupMenuItem(
                      value: v,
                      child: Text('Last $v frames',
                          style: const TextStyle(color: AppTheme.textPrimary)),
                    ))
                .toList(),
          ),
        ],
      ),
      body: BlocBuilder<FireLogsBloc, FireLogsState>(
        builder: (context, state) {
          if (state is FireLogsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          if (state is FireLogsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.danger, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchLogs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is FireLogsLoaded) {
            return _LogsView(history: state.history);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LogsView extends StatelessWidget {
  final HistoryModel history;
  const _LogsView({required this.history});

  @override
  Widget build(BuildContext context) {
    final summary = history.fireSummary;
    final results = history.results.reversed.toList(); // newest first

    return CustomScrollView(
      slivers: [
        // ── Summary card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Overall verdict
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: summary.fireDetectedEver
                        ? AppTheme.danger.withOpacity(0.1)
                        : AppTheme.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: summary.fireDetectedEver
                          ? AppTheme.danger.withOpacity(0.3)
                          : AppTheme.success.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        summary.fireDetectedEver
                            ? Icons.local_fire_department_rounded
                            : Icons.shield_rounded,
                        color: summary.fireDetectedEver ? AppTheme.danger : AppTheme.success,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.verdict,
                              style: TextStyle(
                                color: summary.fireDetectedEver
                                    ? AppTheme.danger
                                    : AppTheme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total frames processed: ${history.totalFramesProcessed}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _SummaryTile(
                      label: 'Fire Frames',
                      value: '${summary.fireFrameCount}',
                      color: AppTheme.danger,
                    ),
                    _SummaryTile(
                      label: 'Coverage',
                      value: '${summary.firePercentage}%',
                      color: AppTheme.warning,
                    ),
                    _SummaryTile(
                      label: 'First Fire',
                      value: summary.firstFireFrame != null
                          ? '#${summary.firstFireFrame}'
                          : 'N/A',
                      color: AppTheme.accent,
                    ),
                    _SummaryTile(
                      label: 'Last Fire',
                      value: summary.lastFireFrame != null
                          ? '#${summary.lastFireFrame}'
                          : 'N/A',
                      color: AppTheme.accent,
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      'Frame Log (${results.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const Text(
                      'newest first',
                      style:
                          TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Per-frame log list ──
        SliverList.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) => _LogRow(result: results[index]),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final CameraResult result;
  const _LogRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final fire = result.fireDetected;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: fire
              ? AppTheme.danger.withOpacity(0.12)
              : AppTheme.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          fire ? Icons.local_fire_department_rounded : Icons.check_rounded,
          color: fire ? AppTheme.danger : AppTheme.success,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          Text(
            'Frame #${result.frame}',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          if (fire)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.intensity.level,
                style: const TextStyle(
                    color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${result.trend}  •  ${result.direction.direction}  •  ${result.intensity.coveragePct}% coverage',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ),
      trailing: Text(
        '${result.detectionCount} det.',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
