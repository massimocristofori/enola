import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:enola/database/database.dart';
import 'package:enola/connection/connection.dart' as impl;
import 'package:enola/database/schema_utils.dart';

class DriftService {
  static final DriftService instance = DriftService._internal();
  late AppDatabase db;
  late Future<void> _ready;

  DriftService._internal() {
    db = AppDatabase(impl.connect());
    _ready = db.customSelect('SELECT 1').get().then((_) {}).catchError((_) {});
  }

  Future<void> ensureReady() => _ready;

  // ── FOLDERS ───────────────────────────────────────────────────────────────

  Stream<List<Folder>> watchAllFolders() {
    return (db.select(db.folders)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<int> saveFolder(String title) async {
    return await db.into(db.folders).insert(
      FoldersCompanion.insert(title: title),
    );
  }

  Future<void> updateFolderTitle(int folderId, String title) async {
    await (db.update(db.folders)..where((t) => t.id.equals(folderId)))
        .write(FoldersCompanion(title: Value(title)));
  }

  Future<void> deleteFolder(int folderId) async {
    await (db.delete(db.folders)..where((t) => t.id.equals(folderId))).go();
  }

  Future<void> setMapFolder(String mapId, int? folderId) async {
    await (db.update(db.riddleMaps)..where((t) => t.id.equals(mapId)))
        .write(RiddleMapsCompanion(folderId: Value(folderId)));
  }

  Stream<List<RiddleMap>> watchMapsInFolder(int folderId) {
    return (db.select(db.riddleMaps)
          ..where((t) => t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Stream<List<RiddleMap>> watchUnfiledMaps() {
    return (db.select(db.riddleMaps)
          ..where((t) => t.folderId.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<FolderStats> getFolderStats(int folderId) async {
    final maps = await (db.select(db.riddleMaps)
          ..where((t) => t.folderId.equals(folderId)))
        .get();

    int totalStars = 0;
    int achievedStars = 0;

    for (final map in maps) {
      final riddles = await (db.select(db.riddles)
            ..where((t) => t.mapId.equals(map.id)))
          .get();
      totalStars += riddles.length * 3;

      final sessions = await (db.select(db.playSessions)
            ..where((t) => t.mapId.equals(map.id))
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(1))
          .get();

      if (sessions.isNotEmpty && sessions.first.riddleStarsJson != null) {
        try {
          final list = jsonDecode(sessions.first.riddleStarsJson!) as List;
          achievedStars += list.fold<int>(0, (sum, e) => sum + (e as int));
        } catch (_) {}
      }
    }

    return FolderStats(
      mapCount: maps.length,
      totalStars: totalStars,
      achievedStars: achievedStars,
    );
  }

  // ── MAPS ──────────────────────────────────────────────────────────────────

  Future<void> saveMap(
    String id,
    String title,
    String? description,
    String? subject, {
    Uint8List? imageBytes,
    int? folderId,
  }) async {
    final existingRow = await (db.select(db.riddleMaps)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    int sortOrder;
    if (existingRow != null) {
      sortOrder = existingRow.sortOrder;
    } else {
      final siblings = folderId == null
          ? await (db.select(db.riddleMaps)
                ..where((t) => t.folderId.isNull()))
              .get()
          : await (db.select(db.riddleMaps)
                ..where((t) => t.folderId.equals(folderId)))
              .get();
      sortOrder = siblings.isEmpty
          ? 0
          : siblings.map((m) => m.sortOrder).reduce(math.max) + 1;
    }

    await db.into(db.riddleMaps).insertOnConflictUpdate(
      RiddleMapsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        subject: Value(subject),
        imageBytes: Value(imageBytes),
        folderId: Value(folderId),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Stream<List<RiddleMap>> watchAllMaps() => db.select(db.riddleMaps).watch();

  Future<void> reorderMaps(List<RiddleMap> ordered) async {
    await db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        await (db.update(db.riddleMaps)
              ..where((t) => t.id.equals(ordered[i].id)))
            .write(RiddleMapsCompanion(sortOrder: Value(i)));
      }
    });
  }

  // ── RIDDLES VERSION ───────────────────────────────────────────────────────

  Future<void> bumpRiddlesVersion(String mapId) async {
    final newVersion = DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.riddleMaps)..where((t) => t.id.equals(mapId)))
        .write(RiddleMapsCompanion(riddlesVersion: Value(newVersion)));
  }

  // ── RIDDLES ───────────────────────────────────────────────────────────────

  Stream<List<Riddle>> watchRiddles(String mapId) {
    return (db.select(db.riddles)
          ..where((t) => t.mapId.equals(mapId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderInMap)]))
        .watch();
  }

  Future<void> saveMultipleChoiceRiddle({
    required String mapId,
    required String question,
    required int orderInMap,
    required List<String> choices,
    required int correctIndex,
    int? existingId,
  }) async {
    final payload = MultipleChoicePayload(
      choices: choices,
      correctIndex: correctIndex,
    );
    final companion = RiddlesCompanion(
      id: existingId != null ? Value(existingId) : const Value.absent(),
      mapId: Value(mapId),
      question: Value(question),
      typeIndex: Value(RiddleType.multipleChoice.index),
      orderInMap: Value(orderInMap),
      payloadJson: Value(jsonEncode(payload.toJson())),
      choicesJson: Value(jsonEncode(choices)),
      correctIndex: Value(correctIndex),
    );
    await db.into(db.riddles).insertOnConflictUpdate(companion);
    await bumpRiddlesVersion(mapId);
  }

  Future<void> saveOrderingRiddle({
    required String mapId,
    required String question,
    required int orderInMap,
    required List<String> items,
    int? existingId,
  }) async {
    final payload = OrderingPayload(items: items);
    final companion = RiddlesCompanion(
      id: existingId != null ? Value(existingId) : const Value.absent(),
      mapId: Value(mapId),
      question: Value(question),
      typeIndex: Value(RiddleType.ordering.index),
      orderInMap: Value(orderInMap),
      payloadJson: Value(jsonEncode(payload.toJson())),
      choicesJson: Value(jsonEncode(items)),
      correctIndex: const Value(null),
    );
    await db.into(db.riddles).insertOnConflictUpdate(companion);
    await bumpRiddlesVersion(mapId);
  }

  Future<void> saveRiddle({
    required String mapId,
    required String question,
    required int orderInMap,
    required RiddlePayload payload,
    int? existingId,
  }) async {
    switch (payload) {
      case MultipleChoicePayload():
        await saveMultipleChoiceRiddle(
          mapId: mapId,
          question: question,
          orderInMap: orderInMap,
          choices: payload.choices,
          correctIndex: payload.correctIndex,
          existingId: existingId,
        );
      case OrderingPayload():
        await saveOrderingRiddle(
          mapId: mapId,
          question: question,
          orderInMap: orderInMap,
          items: payload.items,
          existingId: existingId,
        );
    }
  }

  Future<void> deleteRiddle(int riddleId) async {
    final riddle = await (db.select(db.riddles)
          ..where((t) => t.id.equals(riddleId)))
        .getSingleOrNull();
    await (db.delete(db.riddles)..where((t) => t.id.equals(riddleId))).go();
    if (riddle != null) {
      await bumpRiddlesVersion(riddle.mapId);
    }
  }

  Future<void> deleteRiddlesForMap(String mapId) async {
    await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();
    await bumpRiddlesVersion(mapId);
  }

  Future<void> reorderRiddles(List<Riddle> ordered) async {
    await db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        await (db.update(db.riddles)
              ..where((t) => t.id.equals(ordered[i].id)))
            .write(RiddlesCompanion(orderInMap: Value(i)));
      }
    });
    if (ordered.isNotEmpty) {
      await bumpRiddlesVersion(ordered.first.mapId);
    }
  }

  Future<int> insertBlankRiddle({
    required String mapId,
    required int orderInMap,
  }) async {
    final newId = await db.into(db.riddles).insert(
      RiddlesCompanion(
        id: Value.absent(),
        mapId: Value(mapId),
        orderInMap: Value(orderInMap),
        question: Value("New Riddle"),
        typeIndex: Value(0),
        correctIndex: Value(0),
        payloadJson: Value('{}'),
        choicesJson: Value('["Option 1", "Option 2"]'),
      ),
    );
    await bumpRiddlesVersion(mapId);
    return newId;
  }

  Future<void> saveRiddleFromRow({
    required String mapId,
    required int orderInMap,
    required Riddle riddle,
  }) async {
    final companion = RiddlesCompanion(
      mapId: Value(mapId),
      question: Value(riddle.question),
      typeIndex: Value(riddle.typeIndex),
      orderInMap: Value(orderInMap),
      payloadJson: Value(riddle.payloadJson),
      choicesJson: Value(riddle.choicesJson),
      correctIndex: Value(riddle.correctIndex),
      sourceExcerpt: Value(riddle.sourceExcerpt),
    );
    await db.into(db.riddles).insert(companion);
    await bumpRiddlesVersion(mapId);
  }

  // ── PLAY SESSIONS ─────────────────────────────────────────────────────────

  Future<int> startSession(String mapId, int totalRiddles) async {
    final currentMap = await (db.select(db.riddleMaps)
          ..where((t) => t.id.equals(mapId)))
        .getSingleOrNull();
    final currentVersion = currentMap?.riddlesVersion ?? 0;

    return await db.into(db.playSessions).insert(
      PlaySessionsCompanion.insert(
        mapId: mapId,
        totalRiddles: Value(totalRiddles),
        correctAnswers: const Value(0),
        startedAt: Value(DateTime.now()),
        riddlesVersion: Value(currentVersion),
      ),
    );
  }

  Future<void> incrementScore(int sessionId) async {
    final current = await (db.select(db.playSessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
    if (current == null) return;
    await db.update(db.playSessions).replace(
      current.copyWith(correctAnswers: current.correctAnswers + 1),
    );
  }

  Future<void> advanceProgress(int sessionId, int completedIndex) async {
    await (db.update(db.playSessions)..where((t) => t.id.equals(sessionId)))
        .write(
            PlaySessionsCompanion(lastCompletedIndex: Value(completedIndex)));
  }

  Future<void> completeSession(int sessionId) async {
    await (db.update(db.playSessions)..where((t) => t.id.equals(sessionId)))
        .write(PlaySessionsCompanion(completedAt: Value(DateTime.now())));
  }

  Stream<PlaySession> watchSession(int sessionId) {
    return (db.select(db.playSessions)
          ..where((t) => t.id.equals(sessionId)))
        .watchSingle();
  }

  Future<List<PlaySession>> getSessionsForMap(String mapId) {
    return (db.select(db.playSessions)
          ..where((t) => t.mapId.equals(mapId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  Future<void> clearDatabase() async {
    await db.transaction(() async {
      await db.delete(db.playSessions).go();
      await db.delete(db.riddles).go();
      await db.delete(db.riddleMaps).go();
      await db.delete(db.folders).go();
    });
  }

  // ── TRAINING NOTIFIED RIDDLES ─────────────────────────────────────────────

  Future<void> insertNotifiedRiddle({
    required int sessionId,
    required String mapId,
    required int riddleId,
  }) async {
    await db.into(db.trainingNotifiedRiddles).insertOnConflictUpdate(
      TrainingNotifiedRiddlesCompanion.insert(
        sessionId: sessionId,
        mapId: mapId,
        riddleId: riddleId,
        notifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> removeNotifiedRiddle({
    required int sessionId,
    required int riddleId,
  }) async {
    await (db.delete(db.trainingNotifiedRiddles)
          ..where((t) =>
              t.sessionId.equals(sessionId) & t.riddleId.equals(riddleId)))
        .go();
  }

  Stream<List<PendingTrainingRiddle>> watchPendingNotifiedRiddles() {
    final query = db.select(db.trainingNotifiedRiddles).join([
      innerJoin(
        db.riddles,
        db.riddles.id.equalsExp(db.trainingNotifiedRiddles.riddleId),
      ),
      innerJoin(
        db.trainingSessions,
        db.trainingSessions.id
            .equalsExp(db.trainingNotifiedRiddles.sessionId),
      ),
    ])
      ..where(db.trainingSessions.completedAt.isNull())
      ..orderBy([OrderingTerm.asc(db.trainingNotifiedRiddles.notifiedAt)]);

    return query.watch().map((rows) => rows.map((row) {
          return PendingTrainingRiddle(
            notified: row.readTable(db.trainingNotifiedRiddles),
            riddle: row.readTable(db.riddles),
            session: row.readTable(db.trainingSessions),
          );
        }).toList());
  }

  Stream<Map<String, int>> watchPendingCountPerMap() {
    return watchPendingNotifiedRiddles().map((rows) {
      final counts = <String, int>{};
      for (final row in rows) {
        counts[row.notified.mapId] =
            (counts[row.notified.mapId] ?? 0) + 1;
      }
      return counts;
    });
  }

  Stream<List<TrainingSession>> watchActiveTrainingSessions() {
    return (db.select(db.trainingSessions)
          ..where((t) => t.completedAt.isNull()))
        .watch()
        .map((sessions) => sessions
            .where((s) => DateTime.now().isBefore(s.endsAt))
            .toList());
  }

  // ── TRAINING ATTEMPTS ─────────────────────────────────────────────────────

  Future<void> insertTrainingAttempt({
    required int sessionId,
    required int riddleId,
    required bool correct,
  }) async {
    await db.into(db.trainingAttempts).insert(
      TrainingAttemptsCompanion.insert(
        sessionId: sessionId,
        riddleId: riddleId,
        correct: correct,
        answeredAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<TrainingAttempt>> getAttemptsForRiddle({
    required int sessionId,
    required int riddleId,
  }) async {
    return (db.select(db.trainingAttempts)
          ..where((t) =>
              t.sessionId.equals(sessionId) & t.riddleId.equals(riddleId))
          ..orderBy([(t) => OrderingTerm.asc(t.answeredAt)]))
        .get();
  }

  Future<int> getTrainingStreak() async {
    final activeSessions = await (db.select(db.trainingSessions)
          ..where((t) => t.completedAt.isNull()))
        .get();

    final now = DateTime.now();
    final activeIds = activeSessions
        .where((s) => now.isBefore(s.endsAt))
        .map((s) => s.id)
        .toList();

    if (activeIds.isEmpty) return 0;

    final attempts = await (db.select(db.trainingAttempts)
          ..where((t) => t.sessionId.isIn(activeIds))
          ..orderBy([(t) => OrderingTerm.desc(t.answeredAt)]))
        .get();

    int streak = 0;
    for (final attempt in attempts) {
      if (attempt.correct) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<Map<String, _MasteryProgress>> getMasteryPerMap() async {
    final sessions = await (db.select(db.trainingSessions)
          ..where((t) => t.completedAt.isNull()))
        .get();

    final result = <String, _MasteryProgress>{};

    for (final session in sessions) {
      final allRiddles = await (db.select(db.riddles)
            ..where((t) => t.mapId.equals(session.mapId)))
          .get();

      final attempts = await (db.select(db.trainingAttempts)
            ..where((t) => t.sessionId.equals(session.id)))
          .get();

      final masteredIds = attempts
          .where((a) => a.correct)
          .map((a) => a.riddleId)
          .toSet();

      result[session.mapId] = _MasteryProgress(
        mastered: masteredIds.length,
        total: allRiddles.length,
      );
    }

    return result;
  }

  // ── TRAINING PROGRESS (for dashboard) ─────────────────────────────────────

  /// One row per training session (both active and completed), joined with
  /// its map's title. `masteredCount` is the number of distinct riddles that
  /// have at least one correct attempt in that session; `totalCount` is
  /// that plus whatever's still left in the session's pool. A riddle that
  /// was answered wrong and later answered correctly moves from "remaining"
  /// to "mastered" and is never counted as wrong again — it simply leaves
  /// the pool. Reactive: every answer (right or wrong) writes to
  /// `trainingSessions` (pool/schedule update), which is what this stream
  /// watches, so it recomputes on every attempt automatically.
  Stream<List<TrainingProgress>> watchTrainingProgress() {
    final query = db.select(db.trainingSessions).join([
      innerJoin(
        db.riddleMaps,
        db.riddleMaps.id.equalsExp(db.trainingSessions.mapId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(db.trainingSessions.startedAt)]);

    return query.watch().asyncMap((rows) async {
      final result = <TrainingProgress>[];

      for (final row in rows) {
        final session = row.readTable(db.trainingSessions);
        final map = row.readTable(db.riddleMaps);

        final remainingPool = _parsePoolJson(session.poolJson);

        final correctAttempts = await (db.select(db.trainingAttempts)
              ..where((t) =>
                  t.sessionId.equals(session.id) & t.correct.equals(true)))
            .get();
        final masteredIds =
            correctAttempts.map((a) => a.riddleId).toSet();

        final total = masteredIds.length + remainingPool.length;

        result.add(TrainingProgress(
          sessionId: session.id,
          mapId: session.mapId,
          mapTitle: map.title,
          startedAt: session.startedAt,
					endsAt: session.endsAt,
          completedAt: session.completedAt,
          masteredCount: masteredIds.length,
          totalCount: total,
        ));
      }

      return result;
    });
  }

  /// Deletes [folderId] and everything inside it: maps, their riddles,
  /// their play sessions, and any DownloadedPack/DownloadedPackMaps
  /// tracking rows tied to those maps. Used for both the owner-delete and
  /// generic-user-delete flows — Supabase is handled separately by the
  /// caller (only relevant for owners).
  Future<void> deleteFolderAndContents(int folderId) async {
    await db.transaction(() async {
      final maps = await (db.select(db.riddleMaps)
            ..where((t) => t.folderId.equals(folderId)))
          .get();

      for (final map in maps) {
        await (db.delete(db.riddles)..where((t) => t.mapId.equals(map.id)))
            .go();
        await (db.delete(db.playSessions)
              ..where((t) => t.mapId.equals(map.id)))
            .go();
        await (db.delete(db.downloadedPackMaps)
              ..where((t) => t.localMapId.equals(map.id)))
            .go();
      }

      await (db.delete(db.riddleMaps)..where((t) => t.folderId.equals(folderId)))
          .go();
      await (db.delete(db.folders)..where((t) => t.id.equals(folderId))).go();
    });
  }

  /// Removes the DownloadedPacks tracking row for [packId], if any.
  /// Called when a non-owner deletes their local copy of a downloaded pack,
  /// so a future "Get a Pack" with the same code re-downloads cleanly
  /// instead of silently no-op'ing against a stale tracking row.
  Future<void> removePackTracking(String packId) async {
    await (db.delete(db.downloadedPacks)..where((t) => t.id.equals(packId)))
        .go();
  }

  // ── DOWNLOADED PACKS ──────────────────────────────────────────────────────

  Stream<List<DownloadedPack>> watchDownloadedPacks() {
    return db.select(db.downloadedPacks).watch();
  }

  Future<bool> isPackDownloaded(String packId) async {
    final row = await (db.select(db.downloadedPacks)
          ..where((t) => t.id.equals(packId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<List<DownloadedPackMap>> getDownloadedMapsForPack(
      String packId) async {
    return (db.select(db.downloadedPackMaps)
          ..where((t) => t.packId.equals(packId)))
        .get();
  }

  /// Returns the pack_maps.id (supabase) for a given local map id,
  /// so the teacher can push updates.
  Future<DownloadedPackMap?> getDownloadedPackMapByLocalId(
      String localMapId) async {
    return (db.select(db.downloadedPackMaps)
          ..where((t) => t.localMapId.equals(localMapId)))
        .getSingleOrNull();
  }

  /// Finds the DownloadedPacks row associated with [folderId], if this
  /// folder has ever been involved in pack sharing — either because this
  /// device uploaded it (creatorId is null in that case, see uploadFolder)
  /// or because this device downloaded it from someone else (creatorId is
  /// set to the original creator's uid).
  ///
  /// Returns null if this folder has never been shared or downloaded.
  Future<DownloadedPack?> findPackRecordForFolder(int folderId) async {
    final maps = await (db.select(db.riddleMaps)
          ..where((t) => t.folderId.equals(folderId)))
        .get();
    if (maps.isEmpty) return null;

    final mapIds = maps.map((m) => m.id).toList();

    final packMapRows = await (db.select(db.downloadedPackMaps)
          ..where((t) => t.localMapId.isIn(mapIds)))
        .get();
    if (packMapRows.isEmpty) return null;

    final packId = packMapRows.first.packId;

    return (db.select(db.downloadedPacks)
          ..where((t) => t.id.equals(packId)))
        .getSingleOrNull();
  }

  /// Given a remote pack id, finds the local folder that pack's existing
  /// maps live in — used when a new map is added to an already-downloaded
  /// pack, so the new map lands in the right pack instead of unfiled.
  Future<int?> getFolderIdForPack(String packId) async {
    final link = await (db.select(db.downloadedPackMaps)
          ..where((t) => t.packId.equals(packId))
          ..limit(1))
        .getSingleOrNull();
    if (link == null) return null;

    final map = await (db.select(db.riddleMaps)
          ..where((t) => t.id.equals(link.localMapId)))
        .getSingleOrNull();
    return map?.folderId;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  List<int> _parsePoolJson(String json) {
    try {
      return (jsonDecode(json) as List).cast<int>();
    } catch (_) {
      return [];
    }
  }
}

// ── Supporting data classes ───────────────────────────────────────────────────

class FolderStats {
  final int mapCount;
  final int totalStars;
  final int achievedStars;

  const FolderStats({
    required this.mapCount,
    required this.totalStars,
    required this.achievedStars,
  });
}

class PendingTrainingRiddle {
  final TrainingNotifiedRiddle notified;
  final Riddle riddle;
  final TrainingSession session;

  const PendingTrainingRiddle({
    required this.notified,
    required this.riddle,
    required this.session,
  });
}

class _MasteryProgress {
  final int mastered;
  final int total;
  const _MasteryProgress({required this.mastered, required this.total});
}

class MasteryProgress {
  final int mastered;
  final int total;
  const MasteryProgress({required this.mastered, required this.total});
}

/// Progress snapshot for a single training session, used by the
/// simplified training dashboard.
class TrainingProgress {
  final int sessionId;
  final String mapId;
  final String mapTitle;
  final DateTime startedAt;
  final DateTime endsAt;
  final DateTime? completedAt;
  final int masteredCount;
  final int totalCount;

  const TrainingProgress({
    required this.sessionId,
    required this.mapId,
    required this.mapTitle,
    required this.startedAt,
    required this.endsAt,
    required this.completedAt,
    required this.masteredCount,
    required this.totalCount,
  });

  /// True once explicitly completed/stopped OR once the training's time
  /// window has simply run out (even if nothing has lazily marked
  /// `completedAt` yet).
  bool get isFinished =>
      completedAt != null || DateTime.now().isAfter(endsAt);

  /// 0.0–1.0. Defaults to 0 for an (edge-case) empty map.
  double get percentage =>
      totalCount == 0 ? 0.0 : masteredCount / totalCount;
}

