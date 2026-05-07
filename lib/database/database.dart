import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// ── TABLES ──────────────────────────────────────────────────────────────────

class RiddleMaps extends Table {
  TextColumn get id => text()(); // We use the String publicId as the primary key
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
  TextColumn get choicesJson => text().nullable()(); // Store as JSON string
  IntColumn get correctIndex => integer().nullable()();
}

// ── DATABASE CLASS ──────────────────────────────────────────────────────────

@DriftDatabase(tables: [RiddleMaps, Riddles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // Simple CRUD Example
  Future<List<RiddleMap>> getAllMaps() => select(riddleMaps).get();
  Future<int> insertMap(RiddleMapsCompanion entity) => into(riddleMaps).insert(entity);
}
