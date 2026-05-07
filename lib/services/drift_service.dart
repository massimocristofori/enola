import 'package:drift/drift.dart';
import 'package:enola/database/database.dart';
import 'package:enola/database/connection.dart' as impl;
import 'package:uuid/uuid.dart';

class DriftService {
  // Singleton pattern
  static final DriftService instance = DriftService._internal();
  late AppDatabase db;

  DriftService._internal() {
    db = AppDatabase(impl.connect());
  }

  // ── MAPS & RIDDLES ────────────────────────────────────────────────────────

  /// Saves or updates a map. Using insertOrReplace handles updates smoothly.
  Future<void> saveMap(String id, String title, String? description, String? subject) async {
    await db.into(db.riddleMaps).insert(
      RiddleMapsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        subject: Value(subject),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Streams all maps for the UI (e.g., a map list screen)
  Stream<List<RiddleMap>> watchAllMaps() => db.select(db.riddleMaps).watch();

  /// Gets all riddles for a specific map
  Stream<List<Riddle>> watchRiddles(String mapId) {
    return (db.select(db.riddles)..where((t) => t.mapId.equals(mapId))).watch();
  }

  // ── PLAY SESSIONS ─────────────────────────────────────────────────────────

  /// Starts a new session and returns the internal ID
  Future<int> startSession(String mapId, int totalRiddles) async {
    return await db.into(db.playSessions).insert(
      PlaySessionsCompanion.insert(
        publicId: Value(const Uuid().v4()), // Generates a safe web-friendly ID
        mapId: mapId,
        totalRiddles: Value(totalRiddles),
        correctAnswers: const Value(0),
        startedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates the score for an active session
  Future<void> incrementScore(int sessionId) async {
    final current = await (db.select(db.playSessions)..where((t) => t.id.equals(sessionId))).getSingle();
    
    await db.update(db.playSessions).replace(
      current.copyWith(correctAnswers: current.correctAnswers + 1),
    );
  }

  /// Marks a session as finished
  Future<void> completeSession(int sessionId) async {
    final query = db.update(db.playSessions)..where((t) => t.id.equals(sessionId));
    await query.write(
      PlaySessionsCompanion(completedAt: Value(DateTime.now())),
    );
  }

  /// Streams the current session state (useful for score overlays)
  Stream<PlaySession> watchSession(int sessionId) {
    return (db.select(db.playSessions)..where((t) => t.id.equals(sessionId))).watchSingle();
  }

  // ── UTILITIES ─────────────────────────────────────────────────────────────

  /// Clears everything (useful for testing or "Reset App" settings)
  Future<void> clearDatabase() async {
    await db.transaction(() async {
      await db.delete(db.playSessions).go();
      await db.delete(db.riddles).go();
      await db.delete(db.riddleMaps).go();
    });
  }
}
