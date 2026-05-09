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
        ..orderBy([(t) => drift.OrderingTerm(expression: t.startedAt, mode: drift.OrderingMode.desc)])
        ..limit(1))
      .get();
  return sessions.isNotEmpty ? sessions.first : null;
});

// Provides the 5 most recent overall sessions for the Activity Feed
final recentSessionsProvider = FutureProvider<List<PlaySession>>((ref) async {
  final db = DriftService.instance.db;
  return (db.select(db.playSessions)
    ..orderBy([(t) => drift.OrderingTerm(expression: t.startedAt, mode: drift.OrderingMode.desc)])
    ..limit(5))
    .get();
});

// ── Live play state ───────────────────────────────────────────────────────────
// Holds the in-memory progress for the currently active play session.
// lastCompletedIndex mirrors PlaySession.lastCompletedIndex:
//   -1  = not started
//    n  = riddle at index n has been answered (correctly or not)

class PlayState {
  final int sessionId;
  final int lastCompletedIndex;
  final int correctAnswers;

  const PlayState({
    required this.sessionId,
    required this.lastCompletedIndex,
    required this.correctAnswers,
  });

  PlayState copyWith({int? lastCompletedIndex, int? correctAnswers}) => PlayState(
        sessionId: sessionId,
        lastCompletedIndex: lastCompletedIndex ?? this.lastCompletedIndex,
        correctAnswers: correctAnswers ?? this.correctAnswers,
      );
}

class PlayStateNotifier extends StateNotifier<PlayState?> {
  PlayStateNotifier() : super(null);

  /// Call when the user starts or resumes a map.
  void init(int sessionId, int lastCompletedIndex, int correctAnswers) {
    state = PlayState(
      sessionId: sessionId,
      lastCompletedIndex: lastCompletedIndex,
      correctAnswers: correctAnswers,
    );
  }

  /// Call after the user answers a riddle.
  Future<void> completeRiddle(int riddleIndex, bool wasCorrect) async {
    if (state == null) return;
    final next = state!.copyWith(
      lastCompletedIndex: riddleIndex,
      correctAnswers: state!.correctAnswers + (wasCorrect ? 1 : 0),
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
      ),
    );
  }

  /// Call when the map is finished.
  Future<void> finish() async {
    if (state == null) return;
    final db = DriftService.instance.db;
    final session = await (db.select(db.playSessions)
          ..where((t) => t.id.equals(state!.sessionId)))
        .getSingle();
    await db.update(db.playSessions).replace(
      session.copyWith(completedAt: DateTime.now()),
    );
    state = null;
  }

  void reset() => state = null;
}

final playStateProvider = StateNotifierProvider<PlayStateNotifier, PlayState?>(
  (_) => PlayStateNotifier(),
);
