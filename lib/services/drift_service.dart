import 'dart:convert';
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

  // ── MAPS ──────────────────────────────────────────────────────────────────

  Future<void> saveMap(
    String id,
    String title,
    String? description,
    String? subject, {
    Uint8List? imageBytes,
  }) async {
    await db.into(db.riddleMaps).insertOnConflictUpdate(
      RiddleMapsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        subject: Value(subject),
        imageBytes: Value(imageBytes),
      ),
    );
  }

  Stream<List<RiddleMap>> watchAllMaps() => db.select(db.riddleMaps).watch();

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
    });
  }

  // ── TRAINING NOTIFIED RIDDLES ─────────────────────────────────────────────

  /// Inserts a notified row. Safe to call multiple times — if a row already
  /// exists for this session + riddle it is replaced (idempotent).
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

  /// Removes the pending row once a riddle is answered correctly.
  Future<void> removeNotifiedRiddle({
    required int sessionId,
    required int riddleId,
  }) async {
    await (db.delete(db.trainingNotifiedRiddles)
          ..where((t) =>
              t.sessionId.equals(sessionId) & t.riddleId.equals(riddleId)))
        .go();
  }

  /// Stream of all pending notified riddles across all active training sessions,
  /// joined with their riddle data. Ordered by notifiedAt ascending so the
  /// oldest surfaced riddle appears first.
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

  /// Stream of pending count per mapId, for the dashboard header summary.
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

	/// Stream of all currently active (non-completed, not expired) training sessions.
	/// Used by the home screen FAB to decide whether to show itself.
	Stream<List<TrainingSession>> watchActiveTrainingSessions() {
 	 return (DriftService.instance.db.select(
          DriftService.instance.db.trainingSessions)
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

  /// Returns all attempts for a specific riddle in a session, oldest first.
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

  /// Computes the current training streak: consecutive correct answers
  /// across all sessions, walking backwards from the most recent attempt.
  Future<int> getTrainingStreak() async {
    final attempts = await (db.select(db.trainingAttempts)
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

  /// Returns mastery progress per map: how many riddles have been answered
  /// correctly at least once across all training sessions for that map.
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
}

// ── Supporting data classes ───────────────────────────────────────────────────

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

// Make it public so the dashboard can use it
class MasteryProgress {
  final int mastered;
  final int total;
  const MasteryProgress({required this.mastered, required this.total});
}
