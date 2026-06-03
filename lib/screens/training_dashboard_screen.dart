import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:enola/database/database.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/main.dart' show openTrainingRiddle;

class TrainingDashboardScreen extends StatefulWidget {
  const TrainingDashboardScreen({super.key});

  @override
  State<TrainingDashboardScreen> createState() =>
      _TrainingDashboardScreenState();
}

class _TrainingDashboardScreenState extends State<TrainingDashboardScreen> {
  // Incremented every time the riddles stream fires, forcing FutureBuilders
  // to re-run and pick up fresh streak + mastery data.
  int _summaryEpoch = 0;

  Future<int> _fetchStreak() => DriftService.instance.getTrainingStreak();

  Future<Map<String, MasteryProgress>> _fetchMastery() async {
    final raw = await DriftService.instance.getMasteryPerMap();
    return raw.map(
      (k, v) => MapEntry(k, MasteryProgress(mastered: v.mastered, total: v.total)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EnolaTheme.background,
      appBar: AppBar(
        title: const Text('Training'),
        backgroundColor: EnolaTheme.background,
        foregroundColor: EnolaTheme.textPrimary,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<TrainingRiddleItem>>(
            stream: DriftService.instance.watchAllTrainingRiddles(),
            builder: (context, snapshot) {
              // Every time the riddles stream fires, bump the epoch so the
              // summary FutureBuilders re-execute with fresh data.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _summaryEpoch++);
              });

              final allItems = snapshot.data ?? [];

              final failed = allItems
                  .where((i) => i.status == TrainingRiddleStatus.failedNotified)
                  .toList();
              final pending = allItems
                  .where((i) => i.status == TrainingRiddleStatus.pendingNotified)
                  .toList();
              final upcoming = allItems
                  .where((i) => i.status == TrainingRiddleStatus.notYetNotified)
                  .toList();

              final activeCount = failed.length + pending.length;

              return RefreshIndicator(
                onRefresh: () async => setState(() => _summaryEpoch++),
                child: CustomScrollView(
                  slivers: [
                    // ── Summary header ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: FutureBuilder<int>(
                        // key forces a rebuild when epoch changes
                        key: ValueKey('streak_$_summaryEpoch'),
                        future: _fetchStreak(),
                        builder: (context, streakSnap) {
                          final streak = streakSnap.data ?? 0;
                          return FutureBuilder<Map<String, MasteryProgress>>(
                            key: ValueKey('mastery_$_summaryEpoch'),
                            future: _fetchMastery(),
                            builder: (context, masterySnap) {
                              final mastery = masterySnap.data ?? {};
                              return _SummaryHeader(
                                streak: streak,
                                mastery: mastery,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // ── Empty state ─────────────────────────────────────
                    if (allItems.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyPendingState(),
                      )
                    else ...[

                      // ── "Waiting for you" section ───────────────────
                      if (failed.isNotEmpty || pending.isNotEmpty) ...[
                        _sectionHeader('Waiting for you', activeCount),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = [...failed, ...pending][index];
                              return _RiddleCard(
                                item: item,
                                index: index,
                                onTap: () => openTrainingRiddle(
                                  item.mapId,
                                  item.riddle.id,
                                ),
                              );
                            },
                            childCount: failed.length + pending.length,
                          ),
                        ),
                      ],

                      // ── "Coming up" section ─────────────────────────
                      if (upcoming.isNotEmpty) ...[
                        _sectionHeader('Coming up', null),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = upcoming[index];
                              return _RiddleCard(
                                item: item,
                                index: index,
                                onTap: null,
                              );
                            },
                            childCount: upcoming.length,
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ],
                ),
              );
            },
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

// ── Summary header ────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final int streak;
  final Map<String, MasteryProgress> mastery;

  const _SummaryHeader({required this.streak, required this.mastery});

  @override
  Widget build(BuildContext context) {
    final totalMastered =
        mastery.values.fold(0, (sum, m) => sum + m.mastered);
    final totalRiddles = mastery.values.fold(0, (sum, m) => sum + m.total);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EnolaTheme.accent, EnolaTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: EnolaTheme.accent.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.local_fire_department_rounded,
              value: '$streak',
              label: 'Streak',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(60)),
          Expanded(
            child: _StatCell(
              icon: Icons.check_circle_outline_rounded,
              value: totalRiddles > 0 ? '$totalMastered / $totalRiddles' : '—',
              label: 'Mastered',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(60)),
          Expanded(
            child: _StatCell(
              icon: Icons.map_outlined,
              value: '${mastery.length}',
              label: 'Active maps',
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97));
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Unified riddle card ───────────────────────────────────────────────────────

class _RiddleCard extends StatelessWidget {
  final TrainingRiddleItem item;
  final int index;
  final VoidCallback? onTap;

  const _RiddleCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = item.status == TrainingRiddleStatus.notYetNotified;
    final isFailed = item.status == TrainingRiddleStatus.failedNotified;

    final Color iconBg;
    final Color iconColor;
    final Color? borderAccent;
    final Widget? badge;
    final String subtitle;

    if (isFailed) {
      iconBg = EnolaTheme.wrong.withAlpha(20);
      iconColor = EnolaTheme.wrong;
      borderAccent = EnolaTheme.wrong.withAlpha(80);
      badge = _StatusBadge(label: 'Try again', color: EnolaTheme.wrong);
      final elapsed = DateTime.now().difference(item.notifiedAt!);
      final elapsedLabel = elapsed.inMinutes < 60
          ? '${elapsed.inMinutes}m ago'
          : '${elapsed.inHours}h ago';
      subtitle = 'Notified $elapsedLabel';
    } else if (item.status == TrainingRiddleStatus.pendingNotified) {
      iconBg = EnolaTheme.accent.withAlpha(20);
      iconColor = EnolaTheme.accent;
      borderAccent = null;
      badge = null;
      final elapsed = DateTime.now().difference(item.notifiedAt!);
      final elapsedLabel = elapsed.inMinutes < 60
          ? '${elapsed.inMinutes}m ago'
          : '${elapsed.inHours}h ago';
      subtitle = 'Notified $elapsedLabel';
    } else {
      iconBg = EnolaTheme.border;
      iconColor = EnolaTheme.textSecond;
      borderAccent = null;
      badge = null;
      subtitle = 'Coming up next';
    }

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderAccent ?? EnolaTheme.border,
              width: borderAccent != null ? 1.5 : 1.0,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFailed
                      ? Icons.refresh_rounded
                      : isDisabled
                          ? Icons.lock_outline_rounded
                          : Icons.psychology_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.riddle.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? EnolaTheme.textSecond
                                  : EnolaTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge,
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: EnolaTheme.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isDisabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: EnolaTheme.textSecond,
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 60))
        .slideX(begin: 0.05, end: 0);
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPendingState extends StatelessWidget {
  const _EmptyPendingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: EnolaTheme.correct.withAlpha(180),
            ),
            const SizedBox(height: 16),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EnolaTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No riddles waiting. Check back when the next notification arrives.',
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
