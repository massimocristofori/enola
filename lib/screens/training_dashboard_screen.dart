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
  late Future<int> _streakFuture;
  late Future<Map<String, MasteryProgress>> _masteryFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _streakFuture = DriftService.instance.getTrainingStreak();
    _masteryFuture = _getMastery();
  }

  Future<Map<String, MasteryProgress>> _getMastery() async {
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
      body: StreamBuilder<List<PendingTrainingRiddle>>(
        stream: DriftService.instance.watchPendingNotifiedRiddles(),
        builder: (context, snapshot) {
          final pending = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refresh()),
            child: CustomScrollView(
              slivers: [
                // ── Streak + mastery summary ──────────────────────────────
                SliverToBoxAdapter(
                  child: FutureBuilder<int>(
                    future: _streakFuture,
                    builder: (context, streakSnap) {
                      final streak = streakSnap.data ?? 0;
                      return FutureBuilder<Map<String, MasteryProgress>>(
                        future: _masteryFuture,
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

                // ── Pending queue header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Row(
                      children: [
                        Text(
                          'Waiting for you',
                          style: EnolaTheme.sectionHeader,
                        ),
                        const SizedBox(width: 8),
                        if (pending.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: EnolaTheme.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${pending.length}',
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
                ),

                // ── Empty state ───────────────────────────────────────────
                if (pending.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPendingState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = pending[index];
                        return _PendingRiddleCard(
                          item: item,
                          onTap: () => openTrainingRiddle(
                            item.notified.mapId,
                            item.riddle.id,
                            // fromNotification defaults to false
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: index * 60))
                            .slideX(begin: 0.05, end: 0);
                      },
                      childCount: pending.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
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
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withAlpha(60),
          ),
          Expanded(
            child: _StatCell(
              icon: Icons.check_circle_outline_rounded,
              value: totalRiddles > 0
                  ? '$totalMastered / $totalRiddles'
                  : '—',
              label: 'Mastered',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withAlpha(60),
          ),
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

// ── Pending riddle card ───────────────────────────────────────────────────────

class _PendingRiddleCard extends StatelessWidget {
  final PendingTrainingRiddle item;
  final VoidCallback onTap;

  const _PendingRiddleCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final riddle = item.riddle;
    final notifiedAt = item.notified.notifiedAt;
    final elapsed = DateTime.now().difference(notifiedAt);
    final elapsedLabel = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m ago'
        : '${elapsed.inHours}h ago';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EnolaTheme.border),
          boxShadow: [
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
                color: EnolaTheme.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: EnolaTheme.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riddle.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EnolaTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notified $elapsedLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: EnolaTheme.textSecond,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: EnolaTheme.textSecond,
            ),
          ],
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
