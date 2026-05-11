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

// ignore: unused_import — needed for orderBy inside initState
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
  try {
    final db = DriftService.instance.db;
    final riddles = await db.getRiddlesForMap(widget.mapId);

    // 1. Fetch latest session
    final existing = await (db.select(db.playSessions)
          ..where((t) => t.mapId.equals(widget.mapId))
          ..orderBy([(t) => drift.OrderingTerm(
                expression: t.startedAt,
                mode: drift.OrderingMode.desc,
              )])
          ..limit(1))
        .get();

    int sessionId;
    int lastCompleted = -1;
    int correctAnswers = 0;
    List<int> riddleStars = [];

    if (existing.isNotEmpty && existing.first.completedAt == null) {
      final session = existing.first;
      sessionId = session.id;
      lastCompleted = session.lastCompletedIndex;
      correctAnswers = session.correctAnswers;
      
      // Safety check for JSON decoding
      try {
        if (session.riddleStarsJson != null) {
          final decoded = jsonDecode(session.riddleStarsJson!);
          riddleStars = List<int>.from(decoded);
        }
      } catch (e) {
        debugPrint("JSON Decode error: $e");
        riddleStars = [];
      }
    } else {
      sessionId = await DriftService.instance.startSession(
        widget.mapId,
        riddles.length,
      );
    }

    // 2. Initialize the provider
    ref.read(playStateProvider.notifier).init(
          sessionId, lastCompleted, correctAnswers, riddleStars);

  } catch (e, stack) {
    debugPrint("Failed to init session: $e");
    debugPrint(stack.toString());
    // Optionally: show an error message to the user here
  } finally {
    // 3. ALWAYS kill the loader
    if (mounted) {
      setState(() => _initialising = false);
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
                              // ── Compact star counter ──
                              _SessionStarBadge(playState: playState),
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

// ── Session star badge shown in PlayScreen header ─────────────────────────────

class _SessionStarBadge extends StatelessWidget {
  final PlayState playState;

  const _SessionStarBadge({required this.playState});

  @override
  Widget build(BuildContext context) {
    final total = playState.totalStars;
    final earned = playState.riddleStars.length; // riddles completed so far

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
