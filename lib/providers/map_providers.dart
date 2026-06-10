import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../services/drift_service.dart';

// ── Folder providers ──────────────────────────────────────────────────────────

final allFoldersProvider = StreamProvider<List<Folder>>((ref) {
  return DriftService.instance.watchAllFolders();
});

final mapsInFolderProvider = StreamProvider.family<List<RiddleMap>, int>((ref, folderId) {
  return DriftService.instance.watchMapsInFolder(folderId);
});

final unfiledMapsProvider = StreamProvider<List<RiddleMap>>((ref) {
  return DriftService.instance.watchUnfiledMaps();
});

final folderStatsProvider = FutureProvider.family<FolderStats, int>((ref, folderId) {
  return DriftService.instance.getFolderStats(folderId);
});

// ── Map providers ─────────────────────────────────────────────────────────────

// Provides all maps, sorted by most recent activity, for the root home screen
final allMapsProvider = FutureProvider<List<RiddleMap>>((ref) async {
  final db = DriftService.instance.db;
  final maps = await db.getAllMaps();

  final List<(RiddleMap, DateTime)> withTimestamp = await Future.wait(
    maps.map((m) async {
      final sessions = await (db.select(db.playSessions)
            ..where((t) => t.mapId.equals(m.id))
            ..orderBy([(t) => drift.OrderingTerm(
                  expression: t.startedAt,
                  mode: drift.OrderingMode.desc,
                )])
            ..limit(1))
          .get();
      final ts = sessions.isNotEmpty ? sessions.first.startedAt : m.createdAt;
      return (m, ts);
    }),
  );

  withTimestamp.sort((a, b) => b.$2.compareTo(a.$2));
  return withTimestamp.map((e) => e.$1).toList();
});

final mapProvider = FutureProvider.family<RiddleMap?, String>((ref, id) async {
  final db = DriftService.instance.db;
  final maps = await db.getAllMaps();
  try {
    return maps.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

final riddlesForMapProvider = FutureProvider.family<List<Riddle>, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  return db.getRiddlesForMap(mapId);
});

final riddleCountProvider = FutureProvider.family<int, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final list = await db.getRiddlesForMap(mapId);
  return list.length;
});

final latestSessionProvider = FutureProvider.family<PlaySession?, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final sessions = await (db.select(db.playSessions)
        ..where((t) => t.mapId.equals(m.id))  // ← will be caught below
        ..orderBy([(t) => drift.OrderingTerm(
              expression: t.startedAt,
              mode: drift.OrderingMode.desc,
            )])
        ..limit(1))
      .get();
  return sessions.isNotEmpty ? sessions.first : null;
});

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

class PlayState {
  final int sessionId;
  final int lastCompletedIndex;
  final int correctAnswers;
  final List<int> riddleStars;

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

  Future<void> completeRiddle(int riddleIndex, int errors) async {
    if (state == null) return;

    final stars = List<int>.from(state!.riddleStars)
      ..add(starsForErrors(errors));

    final next = state!.copyWith(
      lastCompletedIndex: riddleIndex,
      correctAnswers: state!.correctAnswers + 1,
      riddleStars: stars,
    );
    state = next;

    final db = DriftService.instance.db;
    final session = await (db.select(db.playSessions)
          ..where((t) => t.id.equals(state!.sessionId)))
        .getSingleOrNull();

    if (session == null) return;

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
        .getSingleOrNull();

    if (session == null) {
      state = null;
      return;
    }

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
