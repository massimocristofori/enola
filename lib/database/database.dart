import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:enola/database/schema_utils.dart';

part 'database.g.dart';

class RiddleMaps extends Table {
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
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();
  TextColumn get question => text()();
  IntColumn get typeIndex => integer()();
  IntColumn get orderInMap => integer()();
  TextColumn get choicesJson => text().nullable()(); 
  IntColumn get correctIndex => integer().nullable()();
}

class PlaySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get publicId => text().clientDefault(() => const Uuid().v4())();
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();
  
  // Track progress: -1 means none completed, 0 means first riddle done, etc.
  IntColumn get lastCompletedIndex => integer().withDefault(const Constant(-1))(); 

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get totalRiddles => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [RiddleMaps, Riddles, PlaySessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 1;

  Future<List<RiddleMap>> getAllMaps() => select(riddleMaps).get();
  Future<void> insertMap(RiddleMapsCompanion entity) => into(riddleMaps).insertOnConflictUpdate(entity);
  Future<List<Riddle>> getRiddlesForMap(String mapId) => 
      (select(riddles)..where((t) => t.mapId.equals(mapId))).get();
  Future<int> createSession(PlaySessionsCompanion entity) => into(playSessions).insert(entity);
  Stream<PlaySession> watchSession(int id) => 
      (select(playSessions)..where((t) => t.id.equals(id))).watchSingle();
  Future<void> updateSession(PlaySession session) => update(playSessions).replace(session);
}

extension RiddleUtils on Riddle {
  RiddleType get type => RiddleType.values[typeIndex];
  List<String> get choices => choicesJson != null 
      ? (jsonDecode(choicesJson!) as List).cast<String>() 
      : [];
}
