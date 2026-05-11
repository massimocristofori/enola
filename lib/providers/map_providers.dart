import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../services/drift_service.dart';

// Provides all maps for the HomeScreen
final allMapsProvider = FutureProvider<List<RiddleMap>>((ref) async {
  final db = DriftService.instance.db;
  return db.getAllMaps();
});

// Provides a single map by its ID
final mapProvider = FutureProvider.family<RiddleMap?, String>((ref, id) async {
  final db = DriftService.instance.db;
  final maps = await db.getAllMaps();
  try {
    return maps.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

// Provides all riddles for a specific map
final riddlesForMapProvider = FutureProvider.family<List<Riddle>, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  return db.getRiddlesForMap(mapId);
});

// Provides the count of riddles for the HomeScreen tiles
final riddleCountProvider = FutureProvider.family<int, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final list = await db.getRiddlesForMap(mapId);
  return list.length;
});

// Provides the most recent play session for the Map Detail Screen
final latestSessionProvider = FutureProvider.family<PlaySession?, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final sessions = await (db.select(db.playSessions)
        ..where((t) => t.mapId.equals(mapId))
        ..orderBy([(t) => drift.OrderingTerm(
              expression: t.startedAt,
              mode: drift.OrderingMode.desc,
            )])
        ..limit(1))
      .get();
  return sessions.isNotEmpty ? sessions.first : null;
});

// Provides the 5 most recent overall sessions for the Activity Feed
final recentSessionsProvider = FutureProvider<List<PlaySession>>((ref) async {
  final db = DriftService.instance.db;
  return (db.select(db.playSessions)
    ..orderBy([(t) => drift.OrderingTerm(
          expression: t.startedAt,
          mode: drift.OrderingMode.desc,
        )])
    ..limit(5))
      .get();
});

// ── Helpers ───────────────────────────────────────────────────────────────────

int starsForErrors(int errors) {
  if (errors == 0) return 3;
  if (errors == 1) return 2;
  if (errors == 2) return 1;
  return 0;
}

// ── Live play state ───────────────────────────────────────────────────────────
// Holds the in-memory progress for the currently active play session.
// lastCompletedIndex mirrors PlaySession.lastCompletedIndex:
//   -1  = not started
//    n  = riddle at index n has been answered

class PlayState {
  final int sessionId;
  final int lastCompletedIndex;
  final int correctAnswers;
  final List<int> riddleStars; // one entry per completed riddle, value 0–3

  const PlayState({
    required this.sessionId,
    required this.lastCompletedIndex,
    required this.correctAnswers,
    required this.riddleStars,
  });

  int get totalStars => riddleStars.fold(0, (sum, s) => sum + s);

  PlayState copyWith({
    int? lastCompletedIndex,
    int? correctAnswers,
    List<int>? riddleStars,
  }) =>
      PlayState(
        sessionId: sessionId,
        lastCompletedIndex: lastCompletedIndex ?? this.lastCompletedIndex,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        riddleStars: riddleStars ?? this.riddleStars,
      );
}

class PlayStateNotifier extends StateNotifier<PlayState?> {
  PlayStateNotifier() : super(null);

  void init(
    int sessionId,
    int lastCompletedIndex,
    int correctAnswers,
    List<int> riddleStars,
  ) {
    state = PlayState(
      sessionId: sessionId,
      lastCompletedIndex: lastCompletedIndex,
      correctAnswers: correctAnswers,
      riddleStars: riddleStars,
    );
  }

  /// Call after the user completes a riddle.
  /// [errors] = number of wrong attempts before getting it right.
  Future<void> completeRiddle(int riddleIndex, int errors) async {
    if (state == null) return;

    final stars = List<int>.from(state!.riddleStars)
      ..add(starsForErrors(errors));

    final next = state!.copyWith(
      lastCompletedIndex: riddleIndex,
      // With retry-until-correct every completed riddle counts as correct.
      correctAnswers: state!.correctAnswers + 1,
      riddleStars: stars,
    );
    state = next;

    // Persist to DB
    final db = DriftService.instance.db;
    final session = await (db.select(db.playSessions)
          ..where((t) => t.id.equals(state!.sessionId)))
        .getSingle();
    await db.update(db.playSessions).replace(
      session.copyWith(
        lastCompletedIndex: next.lastCompletedIndex,
        correctAnswers: next.correctAnswers,
        riddleStarsJson: drift.Value(jsonEncode(stars)),
      ),
    );
  }

  Future<void> finish() async {
    if (state == null) return;
    final db = DriftService.instance.db;
    final session = await (db.select(db.playSessions)
          ..where((t) => t.id.equals(state!.sessionId)))
        .getSingle();
    await db.update(db.playSessions).replace(
      session.copyWith(completedAt: drift.Value(DateTime.now())),
    );
    state = null;
  }

  void reset() => state = null;
}


final playStateProvider = StateNotifierProvider.autoDispose<PlayStateNotifier, PlayState?>(
  (_) => PlayStateNotifier(),
);

