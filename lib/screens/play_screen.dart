import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/widgets/treasure_map_path.dart';
import 'package:enola/screens/riddle_screen.dart';
import 'package:enola/screens/result_screen.dart';
import 'package:enola/services/drift_service.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String mapId;
  const PlayScreen({super.key, required this.mapId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  bool _initialising = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    final db = DriftService.instance.db;
    final riddles = await db.getRiddlesForMap(widget.mapId);

    // Find or create the single session for this map.
    final existing = await (db.select(db.playSessions)
          ..where((t) => t.mapId.equals(widget.mapId))
          ..orderBy([(t) => drift.OrderingTerm(
                expression: t.startedAt,
                mode: drift.OrderingMode.desc,
              )])
          ..limit(1))
        .get();

    final int sessionId;
    final int lastCompleted;
    final int correctAnswers;

    if (existing.isNotEmpty && existing.first.completedAt == null) {
      // Resume
      sessionId = existing.first.id;
      lastCompleted = existing.first.lastCompletedIndex;
      correctAnswers = existing.first.correctAnswers;
    } else {
      // New session
      sessionId = await DriftService.instance.startSession(
        widget.mapId,
        riddles.length,
      );
      lastCompleted = -1;
      correctAnswers = 0;
    }

    ref.read(playStateProvider.notifier).init(sessionId, lastCompleted, correctAnswers);
    if (mounted) setState(() => _initialising = false);
  }

  Future<void> _onNodeTap(List<Riddle> riddles, int riddleIndex) async {
    final playState = ref.read(playStateProvider);
    if (playState == null) return;

    final riddle = riddles[riddleIndex];
    final wasCorrect = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RiddleScreen(riddle: riddle, riddleIndex: riddleIndex),
      ),
    );

    if (wasCorrect == null || !mounted) return;

    await ref
        .read(playStateProvider.notifier)
        .completeRiddle(riddleIndex, wasCorrect);

    // Invalidate so detail screen reflects new progress on back.
    ref.invalidate(latestSessionProvider(widget.mapId));

    // If this was the last riddle, finish and go to results.
    if (riddleIndex == riddles.length - 1) {
      await ref.read(playStateProvider.notifier).finish();
      if (mounted) {
        final state = ref.read(playStateProvider);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              mapId: widget.mapId,
              correct: (state?.correctAnswers ?? 0) + (wasCorrect ? 1 : 0),
              total: riddles.length,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapProvider(widget.mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(widget.mapId));
    final playState = ref.watch(playStateProvider);

    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: _initialising || playState == null
              ? const Center(
                  child: CircularProgressIndicator(color: EnolaTheme.accent))
              : mapAsync.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: EnolaTheme.accent)),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (map) => riddlesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: EnolaTheme.accent)),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (riddles) => Column(
                      children: [
                        // ── Header ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      map?.title ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: EnolaTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${playState.lastCompletedIndex + 1} / ${riddles.length} completed',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: EnolaTheme.textSecond,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Score badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: EnolaTheme.accentSoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: EnolaTheme.accent, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${playState.correctAnswers}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: EnolaTheme.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Tap-to-play hint ──
                        if (playState.lastCompletedIndex < riddles.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Tap the glowing node to answer the next riddle',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: EnolaTheme.textSecond.withAlpha(180),
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                          ),

                        // ── Map ──
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                            child: TreasureMapPath(
                              riddles: riddles,
                              mapId: widget.mapId,
                              lastCompletedIndex: playState.lastCompletedIndex,
                              onCurrentNodeTap: playState.lastCompletedIndex <
                                      riddles.length - 1
                                  ? () => _onNodeTap(
                                        riddles,
                                        playState.lastCompletedIndex + 1,
                                      )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ignore: unused_import — needed for orderBy inside initState
import 'package:drift/drift.dart' as drift;
