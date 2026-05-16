import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
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
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    try {
      try {
        ref.read(playStateProvider.notifier).reset();
      } catch (e) {
        debugPrint("STEP 0 reset failed (ignored): $e");
      }

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
      debugPrint("CAUGHT ERROR: $e");
      debugPrint("$stackTrace");
      if (mounted) {
        setState(() {
          _initError = 'CAUGHT: $e\n\n$stackTrace';
          _initialising = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() => _initialising = false);
    }
  }

  Future<void> _onNodeTap(List<Riddle> riddles, int riddleIndex) async {
    final playState = ref.read(playStateProvider);
    if (playState == null) return;

    final riddle = riddles[riddleIndex];
    final errorCount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => RiddleScreen(riddle: riddle, riddleIndex: riddleIndex),
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

    if (_initError != null) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _initError!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ),
        ),
      );
    }

    final map = mapAsync.valueOrNull;
    final riddles = riddlesAsync.valueOrNull;
    final title = map?.title ?? '';
    final maxStars = (riddles?.length ?? 0) * 3;
    final achievedStars = playState?.totalStars ?? 0;
    final hasBeenPlayed = (playState?.lastCompletedIndex ?? -1) >= 0;

    final bool showingLoader = _initialising || playState == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      // ---
      // iOS-style pill FAB at the bottom center.
      // floatingActionButtonLocation centers it horizontally.
      // ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _BackFab(onTap: () => Navigator.pop(context)),
      body: SafeArea(
        child: Column(
          children: [
            // Header — always in tree from frame 1 for the Hero to work.
            _PlayHeader(
              mapId: widget.mapId,
              title: title,
              achievedStars: achievedStars,
              maxStars: maxStars,
              hasBeenPlayed: hasBeenPlayed,
            ),

            Expanded(
              child: showingLoader
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: EnolaTheme.accent))
                  : mapAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: EnolaTheme.accent)),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (map) => riddlesAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: EnolaTheme.accent)),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (riddles) {
                          return Column(
                            children: [
                              if (playState.lastCompletedIndex <
                                  riddles.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 4),
                                  child: Text(
                                    'Tap the glowing node to answer the next riddle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color:
                                          EnolaTheme.textSecond.withAlpha(180),
                                    ),
                                  ).animate().fadeIn(delay: 400.ms),
                                ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                      24, 16, 24, 100),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 400),
                                      child: TreasureMapPath(
                                        riddles: riddles,
                                        mapId: widget.mapId,
                                        lastCompletedIndex:
                                            playState.lastCompletedIndex,
                                        riddleStars: playState.riddleStars,
                                        imageBytes: map?.imageBytes,
                                        onCurrentNodeTap: playState
                                                    .lastCompletedIndex <
                                                riddles.length - 1
                                            ? () => _onNodeTap(
                                                  riddles,
                                                  playState.lastCompletedIndex +
                                                      1,
                                                )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Play Header ───────────────────────────────────────────────────────────────
// No close button — identical in content to the card's bottom info bar.

class _PlayHeader extends StatelessWidget {
  final String mapId;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;

  const _PlayHeader({
    required this.mapId,
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
  });

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Hero(
      tag: 'map-card-$mapId',
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: EnolaTheme.textPrimary,
                    height: 1.3,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 17, color: Color(0xFFf59e0b)),
                    const SizedBox(width: 4),
                    Text(
                      hasBeenPlayed ? '$achievedStars / $maxStars' : '$maxStars',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxStars > 0 && hasBeenPlayed
                        ? achievedStars / maxStars
                        : 0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFf59e0b)),
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
}  // ← closes _PlayHeader class


// ── Back FAB ──────────────────────────────────────────────────────────────────
// ---
// iOS 26-style pill button: rounded, white, subtle shadow, chevron + label.
// Sits at the bottom center via floatingActionButtonLocation.
// ---

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
            Icon(Icons.chevron_left_rounded, size: 22,
                color: EnolaTheme.textPrimary),
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
