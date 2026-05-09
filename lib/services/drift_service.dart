import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:enola/database/database.dart';
import 'package:enola/connection/connection.dart' as impl;
import 'package:uuid/uuid.dart';
import 'package:enola/database/schema_utils.dart';


class DriftService {
  // Singleton pattern
  static final DriftService instance = DriftService._internal();
  late AppDatabase db;

  DriftService._internal() {
    db = AppDatabase(impl.connect());
  }

  // ── MAPS ──────────────────────────────────────────────────────────────────

  /// Saves or updates a map using insertOnConflictUpdate (safe, no cascade delete).
  Future<void> saveMap(String id, String title, String? description, String? subject) async {
    await db.into(db.riddleMaps).insertOnConflictUpdate(
      RiddleMapsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        subject: Value(subject),
      ),
    );
  }

  /// Streams all maps for the UI (e.g., a map list screen)
  Stream<List<RiddleMap>> watchAllMaps() => db.select(db.riddleMaps).watch();

  // ── RIDDLES ───────────────────────────────────────────────────────────────

  /// Streams all riddles for a specific map, ordered by position.
  Stream<List<Riddle>> watchRiddles(String mapId) {
    return (db.select(db.riddles)
          ..where((t) => t.mapId.equals(mapId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderInMap)]))
        .watch();
  }

  /// Saves a multiple-choice riddle (new API — writes payloadJson).
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
      // Legacy columns kept in sync so old screens don't break.
      choicesJson: Value(jsonEncode(choices)),
      correctIndex: Value(correctIndex),
    );
    await db.into(db.riddles).insertOnConflictUpdate(companion);
  }

  /// Saves an ordering riddle (new API — writes payloadJson).
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
      // Legacy columns: ordering has no correctIndex; choicesJson holds items
      // so old screens that read choicesJson still get something sensible.
      choicesJson: Value(jsonEncode(items)),
      correctIndex: const Value(null),
    );
    await db.into(db.riddles).insertOnConflictUpdate(companion);
  }

  /// Generic save that dispatches to the correct typed method.
  /// Use this when you already have a RiddlePayload object.
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

  /// Deletes a single riddle by id.
  Future<void> deleteRiddle(int riddleId) async {
    await (db.delete(db.riddles)..where((t) => t.id.equals(riddleId))).go();
  }

  /// Deletes all riddles for a map (e.g. before a full re-import).
  Future<void> deleteRiddlesForMap(String mapId) async {
    await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();
  }

  /// Reorders riddles after drag-and-drop. Pass the full ordered list.
  Future<void> reorderRiddles(List<Riddle> ordered) async {
    await db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        await (db.update(db.riddles)..where((t) => t.id.equals(ordered[i].id)))
            .write(RiddlesCompanion(orderInMap: Value(i)));
      }
    });
  }

  // ── PLAY SESSIONS ─────────────────────────────────────────────────────────

  /// Starts a new session and returns the internal ID.
  Future<int> startSession(String mapId, int totalRiddles) async {
    return await db.into(db.playSessions).insert(
      PlaySessionsCompanion.insert(
        publicId: Value(const Uuid().v4()),
        mapId: mapId,
        totalRiddles: Value(totalRiddles),
        correctAnswers: const Value(0),
        startedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates the score for an active session.
  Future<void> incrementScore(int sessionId) async {
    final current = await (db.select(db.playSessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingle();
    await db.update(db.playSessions).replace(
      current.copyWith(correctAnswers: current.correctAnswers + 1),
    );
  }

  /// Advances lastCompletedIndex so the session can resume mid-map.
  Future<void> advanceProgress(int sessionId, int completedIndex) async {
    await (db.update(db.playSessions)..where((t) => t.id.equals(sessionId)))
        .write(PlaySessionsCompanion(lastCompletedIndex: Value(completedIndex)));
  }

  /// Marks a session as finished.
  Future<void> completeSession(int sessionId) async {
    await (db.update(db.playSessions)..where((t) => t.id.equals(sessionId)))
        .write(PlaySessionsCompanion(completedAt: Value(DateTime.now())));
  }

  /// Streams the current session state (useful for score overlays).
  Stream<PlaySession> watchSession(int sessionId) {
    return (db.select(db.playSessions)..where((t) => t.id.equals(sessionId)))
        .watchSingle();
  }

  /// Returns past sessions for a given map, newest first.
  Future<List<PlaySession>> getSessionsForMap(String mapId) {
    return (db.select(db.playSessions)
          ..where((t) => t.mapId.equals(mapId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  // ── UTILITIES ─────────────────────────────────────────────────────────────

  /// Clears everything (useful for testing or "Reset App" settings).
  Future<void> clearDatabase() async {
    await db.transaction(() async {
      await db.delete(db.playSessions).go();
      await db.delete(db.riddles).go();
      await db.delete(db.riddleMaps).go();
    });
  }
}
