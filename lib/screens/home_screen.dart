import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';
import 'package:enola/screens/training_dashboard_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/training_service.dart';

import 'package:drift/drift.dart' as drift_orm;


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(allMapsProvider);

    return Container(
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
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Header(),
                    mapsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(
                            color: EnolaTheme.accent),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text('Error: $e',
                            style:
                                const TextStyle(color: EnolaTheme.wrong)),
                      ),
                      data: (maps) => maps.isEmpty
                          ? _EmptyState(onCreate: () => _openCreate(context))
                          : _MapGrid(
                              maps: maps,
                              onCreate: () => _openCreate(context),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TrainingFab(),
            const SizedBox(width: 12),
            _CreateFab(onTap: () => _openCreate(context)),
          ],
        ),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMapScreen()),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready for a Riddle?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: EnolaTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap a map to explore or play',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: EnolaTheme.textSecond,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0);
  }
}

// ── Responsive Grid ───────────────────────────────────────────────────────────

class _MapGrid extends ConsumerWidget {
  final List<RiddleMap> maps;
  final VoidCallback onCreate;

  const _MapGrid({required this.maps, required this.onCreate});

  int _crossAxisCount(double width) {
    if (width >= 500) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(width);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(40, 4, 40, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 24,
        mainAxisSpacing: 14,
        childAspectRatio: 0.84,
      ),
      itemCount: maps.length,
      itemBuilder: (context, i) {
        return _MapCard(map: maps[i])
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: 350.ms)
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _MapCard extends ConsumerWidget {
  final RiddleMap map;
  const _MapCard({required this.map});

  void _openPlay(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => PlayScreen(mapId: map.id),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _toggleTraining(BuildContext context) async {
    final isActive =
        await TrainingService.instance.isTrainingActive(map.id);

    if (isActive) {
      await TrainingService.instance.stopTraining(map.id);
      return;
    }

    // Need riddles to start training
    final riddles = await (DriftService.instance.db.select(
      DriftService.instance.db.riddles,
    )..where((t) => t.mapId.equals(map.id)))
        .get();

    if (riddles.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add riddles to this map before training.'),
          ),
        );
      }
      return;
    }

    await TrainingService.instance.startTraining(
      mapId: map.id,
      riddles: riddles,
      durationMinutes: 60,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? imageBytes =
        map.imageBytes != null ? Uint8List.fromList(map.imageBytes!) : null;

    final countAsync = ref.watch(riddleCountProvider(map.id));
    final sessionAsync = ref.watch(latestSessionProvider(map.id));

    final count = countAsync.valueOrNull ?? 0;
    final maxStars = count * 3;
    final session = sessionAsync.valueOrNull;

    int achievedStars = 0;
    int completedRiddlesCount = 0;

    if (session != null && session.riddleStarsJson != null) {
      try {
        final list = jsonDecode(session.riddleStarsJson!) as List;
        completedRiddlesCount = list.length;
        achievedStars = list.fold<int>(0, (sum, e) => sum + (e as int));
      } catch (_) {}
    }

    final hasBeenPlayed = session != null;
    final isComplete =
        hasBeenPlayed && count > 0 && completedRiddlesCount >= count;
    final double starRatio = maxStars > 0 ? achievedStars / maxStars : 0;

    return StreamBuilder<TrainingSession?>(
      stream: (DriftService.instance.db.select(
        DriftService.instance.db.trainingSessions,
      )
            ..where((t) => t.mapId.equals(map.id))
            ..where((t) => t.completedAt.isNull())
            ..orderBy([
              (t) => drift_orm.OrderingTerm.desc(t.startedAt),
            ])
            ..limit(1))
          .watchSingleOrNull(),
      builder: (context, trainingSnap) {
        // A session row exists but may be expired — treat expired as off
        final rawSession = trainingSnap.data;
        final isTrainingOn = rawSession != null &&
            DateTime.now().isBefore(rawSession.endsAt);

        return GestureDetector(
          onTap: () => _openPlay(context),
          child: Hero(
            tag: 'map-card-${map.id}',
            flightShuttleBuilder: (_, animation, __, ___, ____) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final imageHeightFactor =
                      (1.0 - animation.value).clamp(0.0, 1.0);

                  return SizedBox.expand(
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: imageHeightFactor,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8)),
                                    child: imageBytes != null
                                        ? Image.memory(imageBytes,
                                            fit: BoxFit.cover,
                                            width: double.infinity)
                                        : Image.asset(
                                            'assets/images/0.jpeg',
                                            fit: BoxFit.cover,
                                            width: double.infinity),
                                  ),
                                ),
                              ),
                            ),
                            _CardInfoBar(
                              title: map.title,
                              achievedStars: achievedStars,
                              maxStars: maxStars,
                              hasBeenPlayed: hasBeenPlayed,
                              isComplete: isComplete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _CardShell(
                  imageBytes: imageBytes,
                  title: map.title,
                  achievedStars: achievedStars,
                  maxStars: maxStars,
                  hasBeenPlayed: hasBeenPlayed,
                  isComplete: isComplete,
                ),

                // ── Centered Ribbon Overlay ──
                if (isComplete)
                  Positioned(
                    left: -4,
                    right: -4,
                    top: 0,
                    bottom: 20,
                    child: _RankRibbonOverlay(starRatio: starRatio),
                  ),

                // ── Top-right ear (Training toggle) ──
                Positioned(
                  top: -8,
                  right: -8,
                  child: _EarButton(
                    icon: isTrainingOn
                        ? Icons.school_rounded
                        : Icons.school_outlined,
                    iconColor: isTrainingOn
                        ? Colors.white
                        : EnolaTheme.textSecond.withValues(alpha: 0.95),
                    backgroundColor:
                        isTrainingOn ? EnolaTheme.secondary : Colors.white,
                    onTap: () => _toggleTraining(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Rank helpers ──────────────────────────────────────────────────────────────

String _rankEmoji(double starRatio) {
  if (starRatio >= 0.9) return '👑';
  if (starRatio >= 0.7) return '🏆';
  if (starRatio >= 0.5) return '⚔';
  return '📜';
}

// ── Floating Ribbon Overlay ───────────────────────────────────────────────────

class _RankRibbonOverlay extends StatelessWidget {
  final double starRatio;
  const _RankRibbonOverlay({required this.starRatio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5), // was 10
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF9CF58).withValues(alpha: 0.9),
              const Color(0xFFF6B700).withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.33, 0.33, 0.33, 0, 180,
            0.33, 0.33, 0.33, 0, 180,
            0.33, 0.33, 0.33, 0, 180,
            0,    0,    0,    1, 0,
          ]),
          child: Text(
            _rankEmoji(starRatio),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 42),
          ),
        ),
      ),
    );
  }
}

// ── Custom Progress Bar ───────────────────────────────────────────────────────

class _StarProgressBar extends StatelessWidget {
  final double progress;

  const _StarProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double starSize = 26.0;
        const double barHeight = 8.0;

        final double leftOffset = width * progress.clamp(0.0, 1.0);

        return SizedBox(
          height: starSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // Background track
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Fill track
              if (progress > 0)
                Container(
                  height: barHeight,
                  width: leftOffset,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              // Thumb
              Positioned(
                left: leftOffset,
                child: Container(
                  transform: Matrix4.translationValues(
                      -starSize / 2, -2.0, 0),
                  child: const Icon(
                    Icons.star_rounded,
                    size: starSize,
                    color: Color(0xFFF1C40F),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Card Shell ────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Uint8List? imageBytes;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardShell({
    required this.imageBytes,
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Image.asset('assets/images/0.jpeg',
                      fit: BoxFit.cover),
            ),
          ),
          _CardInfoBar(
            title: title,
            achievedStars: achievedStars,
            maxStars: maxStars,
            hasBeenPlayed: hasBeenPlayed,
            isComplete: isComplete,
          ),
        ],
      ),
    );
  }
}

// ── Card Info Bar ─────────────────────────────────────────────────────────────

class _CardInfoBar extends StatelessWidget {
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardInfoBar({
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title rectangle ──
          Container(
            height: 38,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: EnolaTheme.textPrimary,
                height: 1.3,
                letterSpacing: 0.1,
              ),
            ),
          ),
          // ── Progress bar row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                Text(
                  '$achievedStars',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StarProgressBar(
                    progress: maxStars > 0 && hasBeenPlayed
                        ? achievedStars / maxStars
                        : 0.0,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$maxStars',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ear Button ────────────────────────────────────────────────────────────────

class _EarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color backgroundColor;

  const _EarButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26, color: iconColor),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Text(
              'No quest maps yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: EnolaTheme.accent,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first map of riddles\nand begin the adventure.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Quest Map'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms).scale(
            begin: const Offset(0.9, 0.9),
          ),
    );
  }
}

// ── FABs ──────────────────────────────────────────────────────────────────────

class _CreateFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'create_fab',
      onPressed: onTap,
      backgroundColor: EnolaTheme.accent,
      foregroundColor: EnolaTheme.background,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Map',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Training FAB — only visible when a training session is active ─────────────

class _TrainingFab extends StatefulWidget {
  const _TrainingFab();

  @override
  State<_TrainingFab> createState() => _TrainingFabState();
}

class _TrainingFabState extends State<_TrainingFab> {
  late Stream<List<TrainingRiddleItem>> _riddlesStream;

  @override
  void initState() {
    super.initState();
    _riddlesStream = DriftService.instance.watchAllTrainingRiddles();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrainingRiddleItem>>(
      stream: _riddlesStream,
      builder: (context, snapshot) {
        return StreamBuilder<List<TrainingSession>>(
          stream: DriftService.instance.watchActiveTrainingSessions(),
          builder: (context, sessionSnap) {
            final hasActiveSessions =
                (sessionSnap.data ?? []).isNotEmpty;

            final totalCount = snapshot.data?.length ?? 0;

            if (!hasActiveSessions) return const SizedBox.shrink();

            return FloatingActionButton.extended(
              heroTag: 'training_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingDashboardScreen(),
                ),
              ),
              backgroundColor: EnolaTheme.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.psychology_rounded),
              label: Row(
                children: [
                  const Text(
                    'Training',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0);
          },
        );
      },
    );
  }
}
