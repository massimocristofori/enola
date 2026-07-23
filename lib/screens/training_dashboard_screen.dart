import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:enola/services/drift_service.dart';
import 'package:enola/theme/enola_theme.dart';

class TrainingDashboardScreen extends StatelessWidget {
  const TrainingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECEFF4), Colors.white],
            stops: [0.0, 0.65],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _BackFab(
            onTap: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: StreamBuilder<List<TrainingProgress>>(
                  stream: DriftService.instance.watchTrainingProgress(),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? [];

                    final inProgress =
                        all.where((p) => !p.isFinished).toList()
                          ..sort((a, b) =>
                              b.startedAt.compareTo(a.startedAt));
                    final finished = all.where((p) => p.isFinished).toList()
                      ..sort((a, b) => b.completedAt!
                          .compareTo(a.completedAt!));

                    return CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: _DashboardHeader()),
                        if (all.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(),
                          )
                        else ...[
                          if (inProgress.isNotEmpty) ...[
                            _sectionHeader('In progress', inProgress.length),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _ProgressCard(
                                  progress: inProgress[index],
                                  index: index,
                                ),
                                childCount: inProgress.length,
                              ),
                            ),
                          ],
                          if (finished.isNotEmpty) ...[
                            _sectionHeader('Completed', null),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _ProgressCard(
                                  progress: finished[index],
                                  index: index,
                                ),
                                childCount: finished.length,
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 100)),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String label, int? count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Row(
          children: [
            Text(label, style: EnolaTheme.sectionHeader),
            const SizedBox(width: 8),
            if (count != null && count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EnolaTheme.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: EnolaTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Keep the momentum going!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EnolaTheme.textSecond,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0);
  }
}

// ── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final TrainingProgress progress;
  final int index;

  const _ProgressCard({required this.progress, required this.index});

  Color get _barColor {
    if (progress.percentage >= 1.0) return EnolaTheme.correct;
    return Color.lerp(
      EnolaTheme.wrong,
      EnolaTheme.correct,
      progress.percentage.clamp(0.0, 1.0),
    )!;
  }

  String get _message {
    final pct = (progress.percentage * 100).round();

    if (progress.isFinished) {
      if (progress.percentage >= 1.0) {
        return '🎉 Training complete! Every riddle mastered.';
      }
      return 'Training ended at $pct% — start a new one anytime.';
    }

    if (pct >= 90) return "You're at $pct%! One last push to the finish 🔥";
    if (pct >= 60) {
      return "You're at $pct% of your training! Keep the momentum going!";
    }
    if (pct >= 30) return "You're at $pct% — solid progress, keep it up!";
    return "You're at $pct%. Just getting started, you've got this!";
  }

  @override
  Widget build(BuildContext context) {
    final pct = progress.percentage;
    final isFinished = progress.isFinished;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EnolaTheme.border),
        boxShadow: isFinished
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _barColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFinished
                      ? (pct >= 1.0
                          ? Icons.emoji_events_rounded
                          : Icons.flag_rounded)
                      : Icons.psychology_rounded,
                  color: _barColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress.mapTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EnolaTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AnimatedBar(percentage: pct, color: _barColor),
          const SizedBox(height: 10),
          Text(
            _message,
            style: const TextStyle(
              fontSize: 13,
              color: EnolaTheme.textSecond,
              height: 1.4,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 60))
        .slideY(begin: 0.05, end: 0);
  }
}

class _AnimatedBar extends StatelessWidget {
  final double percentage;
  final Color color;

  const _AnimatedBar({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: EnolaTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  width: constraints.maxWidth * value,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: EnolaTheme.accent.withAlpha(180),
            ),
            const SizedBox(height: 16),
            const Text(
              'No trainings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EnolaTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a training from one of your maps to see your progress here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: EnolaTheme.textSecond,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }
}

// ── Back FAB ──────────────────────────────────────────────────────────────────

class _BackFab extends StatelessWidget {
  final VoidCallback onTap;
  const _BackFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chevron_left_rounded,
                size: 22, color: EnolaTheme.textPrimary),
            SizedBox(width: 4),
            Text(
              'My Maps',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: EnolaTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
