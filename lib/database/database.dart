import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Note: We removed the platform-specific imports (dart:io, wasm, etc.) 
// from this file because they are now handled in your connection.dart 
// to prevent compilation errors.

part 'database.g.dart';

// ── TABLES ──────────────────────────────────────────────────────────────────

class RiddleMaps extends Table {
  /// The primary key (UUID string)
  TextColumn get id => text()(); 
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get subject => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Riddles extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// Link to the parent map
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get question => text()();
  IntColumn get typeIndex => integer()();
  IntColumn get orderInMap => integer()();
  
  /// Choices stored as a JSON string (e.g., '["Blue", "Red", "Green"]')
  TextColumn get choicesJson => text().nullable()(); 
  IntColumn get correctIndex => integer().nullable()();
}

class PlaySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// Public UUID for safe referencing in UI/Web
  TextColumn get publicId => text().clientDefault(() => const Uuid().v4())();
  
  /// Link to the RiddleMap being played
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  IntColumn get totalRiddles => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();
}

// ── DATABASE CLASS ──────────────────────────────────────────────────────────

@DriftDatabase(tables: [RiddleMaps, Riddles, PlaySessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // ── HELPER QUERIES ────────────────────────────────────────────────────────

  // Maps
  Future<List<RiddleMap>> getAllMaps() => select(riddleMaps).get();
  Future<void> insertMap(RiddleMapsCompanion entity) => into(riddleMaps).insertOnConflictUpdate(entity);

  // Riddles
  Future<List<Riddle>> getRiddlesForMap(String mapId) => 
      (select(riddles)..where((t) => t.mapId.equals(mapId))).get();

  // Sessions
  Future<int> createSession(PlaySessionsCompanion entity) => into(playSessions).insert(entity);
  
  Stream<PlaySession> watchSession(int id) => 
      (select(playSessions)..where((t) => t.id.equals(id))).watchSingle();

  Future<void> updateSession(PlaySession session) => update(playSessions).replace(session);
}
