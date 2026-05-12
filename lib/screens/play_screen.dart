import 'dart:convert';
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

import 'package:drift/drift.dart' as drift;

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
    ref.read(playStateProvider.notifier).reset();

    try {
      await DriftService.instance.ensureReady();

      final db = DriftService.instance.db;
      final riddles = await db.getRiddlesForMap(widget.mapId);

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
      final List<int> riddleStars;

      if (existing.isNotEmpty && existing.first.completedAt == null) {
        sessionId = existing.first.id;
        lastCompleted = existing.first.lastCompletedIndex;
        correctAnswers = existing.first.correctAnswers;
        final raw = existing.first.riddleStarsJson;
        List<int> tempStars = [];
        try {
          if (raw != null) {
            tempStars = (jsonDecode(raw) as List).cast<int>();
          }
        } catch (e) {
          debugPrint("JSON Decode error: $e");
        }
        riddleStars = tempStars;
      } else {
        sessionId = await DriftService.instance.startSession(
          widget.mapId,
          riddles.length,
        );
        lastCompleted = -1;
        correctAnswers = 0;
        riddleStars = [];
      }

      ref.read(playStateProvider.notifier).init(
            sessionId, lastCompleted, correctAnswers, riddleStars);

    } catch (e, stackTrace) {
      debugPrint("Session Init Error: $e");
      debugPrint("$stackTrace");
    } finally {
      if (mounted) {
        setState(() => _initialising = false);
      }
    }
  }

  Future<void> _onNodeTap(List<Riddle> riddles, int riddleIndex) async {
    final playState = ref.read(playStateProvider);
    if (playState == null) return;

    final riddle = riddles[riddleIndex];
    final errorCount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RiddleScreen(riddle: riddle, riddleIndex: riddleIndex),
      ),
    );

    if (errorCount == null || !mounted) return;

    await ref
        .read(playStateProvider.notifier)
        .completeRiddle(riddleIndex, errorCount);

    ref.invalidate(latestSessionProvider(widget.mapId));

    if (riddleIndex == riddles.length - 1) {
      final totalStars = ref.read(playStateProvider)?.totalStars ?? 0;
      final maxStars = riddles.length * 3;
      await ref.read(playStateProvider.notifier).finish();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              mapId: widget.mapId,
              correct: riddles.length,
              total: riddles.length,
              totalStars: totalStars,
              maxStars: maxStars,
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

    final bool showingLoader = _initialising || playState == null;

    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: showingLoader
              ? const Center(
                  child: CircularProgressIndicator(color: EnolaTheme.accent))
              : mapAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: EnolaTheme.accent)),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (map) => riddlesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: EnolaTheme.accent)),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (riddles) => Column(
                      children: [
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
                              _SessionStarBadge(playState: playState),
                            ],
                          ),
                        ),

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

                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(24, 16, 24, 40),
                            child: TreasureMapPath(
                              riddles: riddles,
                              mapId: widget.mapId,
                              lastCompletedIndex:
                                  playState.lastCompletedIndex,
                              onCurrentNodeTap:
                                  playState.lastCompletedIndex <
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

class _SessionStarBadge extends StatelessWidget {
  final PlayState playState;

  const _SessionStarBadge({required this.playState});

  @override
  Widget build(BuildContext context) {
    final total = playState.totalStars;
    final earned = playState.riddleStars.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: EnolaTheme.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: EnolaTheme.accent, size: 16),
          const SizedBox(width: 4),
          Text(
            earned == 0 ? '—' : '$total',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: EnolaTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}
