import 'dart:async';
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

/// Consecutive correct answers across active sessions only, most recent first.
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

  // ── ALL TRAINING RIDDLES STREAM ───────────────────────────────────────────

  /// Streams all riddles across all active training sessions, classified by
  /// status. Order: failedNotified → pendingNotified → notYetNotified.
  /// Riddles answered correctly are excluded (their notified row is deleted).
  Stream<List<TrainingRiddleItem>> watchAllTrainingRiddles() {
    final notifiedStream = watchPendingNotifiedRiddles();
    final sessionsStream = (db.select(db.trainingSessions)
          ..where((t) => t.completedAt.isNull()))
        .watch();

    late StreamController<List<TrainingRiddleItem>> controller;
    List<PendingTrainingRiddle> latestNotified = [];
    List<TrainingSession> latestSessions = [];
    bool notifiedReady = false;
    bool sessionsReady = false;
    StreamSubscription<List<PendingTrainingRiddle>>? notifiedSub;
    StreamSubscription<List<TrainingSession>>? sessionsSub;

    Future<List<TrainingRiddleItem>> compute() async {
      final now = DateTime.now();
      final activeSessions =
          latestSessions.where((s) => now.isBefore(s.endsAt)).toList();

      if (activeSessions.isEmpty) return [];

      final items = <TrainingRiddleItem>[];

      final notifiedMap = {
        for (final p in latestNotified) p.riddle.id: p,
      };

      // Collect all riddle IDs that have at least one wrong attempt,
      // across all active sessions
      final wrongAttemptRiddleIds = <int>{};
      for (final session in activeSessions) {
        final attempts = await (db.select(db.trainingAttempts)
              ..where((t) =>
                  t.sessionId.equals(session.id) &
                  t.correct.equals(false)))
            .get();
        for (final a in attempts) {
          wrongAttemptRiddleIds.add(a.riddleId);
        }
      }

      for (final session in activeSessions) {
        final pool = _parsePoolJson(session.poolJson);
        if (pool.isEmpty) continue;

        final riddles = await (db.select(db.riddles)
              ..where((t) => t.id.isIn(pool)))
            .get();

        for (final riddle in riddles) {
          final notifiedEntry = notifiedMap[riddle.id];
          final TrainingRiddleStatus status;

          if (notifiedEntry != null) {
            status = wrongAttemptRiddleIds.contains(riddle.id)
                ? TrainingRiddleStatus.failedNotified
                : TrainingRiddleStatus.pendingNotified;
          } else {
            status = TrainingRiddleStatus.notYetNotified;
          }

          items.add(TrainingRiddleItem(
            riddle: riddle,
            mapId: session.mapId,
            sessionId: session.id,
            status: status,
            notifiedAt: notifiedEntry?.notified.notifiedAt,
          ));
        }
      }

      const order = {
        TrainingRiddleStatus.failedNotified: 0,
        TrainingRiddleStatus.pendingNotified: 1,
        TrainingRiddleStatus.notYetNotified: 2,
      };
      items.sort((a, b) {
        final statusCmp = order[a.status]!.compareTo(order[b.status]!);
        if (statusCmp != 0) return statusCmp;
        if (a.notifiedAt != null && b.notifiedAt != null) {
          return a.notifiedAt!.compareTo(b.notifiedAt!);
        }
        return a.riddle.orderInMap.compareTo(b.riddle.orderInMap);
      });

      return items;
    }

    void emit() {
      if (!notifiedReady || !sessionsReady) return;
      compute().then((result) {
        if (!controller.isClosed) controller.add(result);
      });
    }

    controller = StreamController<List<TrainingRiddleItem>>(
      onListen: () {
        notifiedSub = notifiedStream.listen((data) {
          latestNotified = data;
          notifiedReady = true;
          emit();
        });
        sessionsSub = sessionsStream.listen((data) {
          latestSessions = data;
          sessionsReady = true;
          emit();
        });
      },
      onCancel: () {
        notifiedSub?.cancel();
        sessionsSub?.cancel();
      },
    );

    return controller.stream;
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

// ── Training riddle status ────────────────────────────────────────────────────

enum TrainingRiddleStatus {
  /// Notified and answered at least once incorrectly (no correct answer yet)
  failedNotified,
  /// Notified but never attempted yet
  pendingNotified,
  /// In the pool but not yet notified
  notYetNotified,
}

class TrainingRiddleItem {
  final Riddle riddle;
  final String mapId;
  final int sessionId;
  final TrainingRiddleStatus status;
  final DateTime? notifiedAt;

  const TrainingRiddleItem({
    required this.riddle,
    required this.mapId,
    required this.sessionId,
    required this.status,
    this.notifiedAt,
  });
}
