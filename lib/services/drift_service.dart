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
    await (db.delete(db.riddles)..where((t) => t.id.equals(riddleId))).go();
  }

  Future<void> deleteRiddlesForMap(String mapId) async {
    await (db.delete(db.riddles)..where((t) => t.mapId.equals(mapId))).go();
  }

  Future<void> reorderRiddles(List<Riddle> ordered) async {
    await db.transaction(() async {
      for (var i = 0; i < ordered.length; i++) {
        await (db.update(db.riddles)..where((t) => t.id.equals(ordered[i].id)))
            .write(RiddlesCompanion(orderInMap: Value(i)));
      }
    });
  }

	Future<int> insertBlankRiddle({
	  required String mapId,
	  required int orderInMap,
	}) async {
	  return await db.into(db.riddles).insert(
	    RiddlesCompanion(
	      id: Value.absent(),
	      mapId: Value(mapId),
	      orderInMap: Value(orderInMap),
	      // Default template values to prevent UI crashes
	      question: Value("New Riddle"),
	      typeIndex: Value(0), // 0 = Multiple Choice
	      correctIndex: Value(0),
	      payloadJson: Value('{}'),
	      choicesJson: Value('["Option 1", "Option 2"]'),
	    ),
	  );
	}



  
  Future<void> saveRiddleFromRow({
    required String mapId,
    required int orderInMap,
    required Riddle riddle,
  }) async {
    final companion = RiddlesCompanion(
      //id: const Value.absent(),
      mapId: Value(mapId),
      question: Value(riddle.question),
      typeIndex: Value(riddle.typeIndex),
      orderInMap: Value(orderInMap),
      payloadJson: Value(riddle.payloadJson),
      choicesJson: Value(riddle.choicesJson),
      correctIndex: Value(riddle.correctIndex),
    );
    await db.into(db.riddles).insert(companion);
  }


  // ── PLAY SESSIONS ─────────────────────────────────────────────────────────

  Future<int> startSession(String mapId, int totalRiddles) async {
    return await db.into(db.playSessions).insert(
      PlaySessionsCompanion.insert(
        mapId: mapId,
        totalRiddles: Value(totalRiddles),
        correctAnswers: const Value(0),
        startedAt: Value(DateTime.now()),
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
        .write(PlaySessionsCompanion(lastCompletedIndex: Value(completedIndex)));
  }

  Future<void> completeSession(int sessionId) async {
    await (db.update(db.playSessions)..where((t) => t.id.equals(sessionId)))
        .write(PlaySessionsCompanion(completedAt: Value(DateTime.now())));
  }

  Stream<PlaySession> watchSession(int sessionId) {
    return (db.select(db.playSessions)..where((t) => t.id.equals(sessionId)))
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
}
