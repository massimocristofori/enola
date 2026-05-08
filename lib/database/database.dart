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

  // Single payload column replaces choicesJson + correctIndex.
  // Shape is type-specific — see RiddlePayload below.
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();

  // ── Kept for backwards compatibility with existing screens/services ──
  // These are now derived from payloadJson. Do not write to them directly.
  TextColumn get choicesJson => text().nullable()();
  IntColumn get correctIndex => integer().nullable()();
}

class PlaySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get publicId => text().clientDefault(() => const Uuid().v4())();
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();
  IntColumn get lastCompletedIndex => integer().withDefault(const Constant(-1))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get totalRiddles => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();
}

// ---------------------------------------------------------------------------
// Riddle type enum — add new values here as you expand
// ---------------------------------------------------------------------------

enum RiddleType {
  multipleChoice,  // index 0
  ordering,        // index 1
}

// ---------------------------------------------------------------------------
// Typed payload wrappers — one class per riddle type.
// Services and screens should use these instead of raw JSON.
// ---------------------------------------------------------------------------

sealed class RiddlePayload {
  const RiddlePayload();

  Map<String, dynamic> toJson();

  static RiddlePayload fromJson(RiddleType type, Map<String, dynamic> json) {
    return switch (type) {
      RiddleType.multipleChoice => MultipleChoicePayload.fromJson(json),
      RiddleType.ordering       => OrderingPayload.fromJson(json),
    };
  }
}

class MultipleChoicePayload extends RiddlePayload {
  final List<String> choices;
  final int correctIndex;

  const MultipleChoicePayload({
    required this.choices,
    required this.correctIndex,
  });

  factory MultipleChoicePayload.fromJson(Map<String, dynamic> json) =>
      MultipleChoicePayload(
        choices: (json['choices'] as List).cast<String>(),
        correctIndex: json['correctIndex'] as int,
      );

  @override
  Map<String, dynamic> toJson() => {
    'choices': choices,
    'correctIndex': correctIndex,
  };

  String? get choiceA => choices.isNotEmpty ? choices[0] : null;
  String? get choiceB => choices.length > 1 ? choices[1] : null;
  String? get choiceC => choices.length > 2 ? choices[2] : null;
  String? get choiceD => choices.length > 3 ? choices[3] : null;
}

class OrderingPayload extends RiddlePayload {
  final List<String> items;

  const OrderingPayload({required this.items});

  factory OrderingPayload.fromJson(Map<String, dynamic> json) =>
      OrderingPayload(
        items: (json['items'] as List).cast<String>(),
      );

  @override
  Map<String, dynamic> toJson() => {'items': items};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [RiddleMaps, Riddles, PlaySessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Add payloadJson to existing installs.
        // choicesJson and correctIndex are kept as-is; payloadJson starts empty.
        await m.addColumn(riddles, riddles.payloadJson);
      }
    },
  );

  // ── Maps ──
  Future<List<RiddleMap>> getAllMaps() => select(riddleMaps).get();
  Future<void> insertMap(RiddleMapsCompanion entity) =>
      into(riddleMaps).insertOnConflictUpdate(entity);

  // ── Riddles ──
  Future<List<Riddle>> getRiddlesForMap(String mapId) =>
      (select(riddles)..where((t) => t.mapId.equals(mapId))).get();

  // ── Sessions ──
  Future<int> createSession(PlaySessionsCompanion entity) =>
      into(playSessions).insert(entity);
  Stream<PlaySession> watchSession(int id) =>
      (select(playSessions)..where((t) => t.id.equals(id))).watchSingle();
  Future<void> updateSession(PlaySession session) =>
      update(playSessions).replace(session);
}

// ---------------------------------------------------------------------------
// Extension on Riddle
// Backwards-compatible helpers are preserved; new code should use .payload
// ---------------------------------------------------------------------------

extension RiddleUtils on Riddle {
  RiddleType get type => RiddleType.values[typeIndex];

  // ── New API ──

  Map<String, dynamic> get _payloadMap =>
      payloadJson.isNotEmpty && payloadJson != '{}'
          ? jsonDecode(payloadJson) as Map<String, dynamic>
          : {};

  RiddlePayload get payload => RiddlePayload.fromJson(type, _payloadMap);

  // Convenience typed accessors
  MultipleChoicePayload? get asMultipleChoice =>
      type == RiddleType.multipleChoice ? payload as MultipleChoicePayload : null;

  OrderingPayload? get asOrdering =>
      type == RiddleType.ordering ? payload as OrderingPayload : null;

  // ── Legacy API (kept for existing screens/services) ──
  // Reads from payloadJson first; falls back to the old choicesJson column.

  List<String> get choices {
    final mc = asMultipleChoice;
    if (mc != null) return mc.choices;
    final ord = asOrdering;
    if (ord != null) return ord.items;
    // fallback to old column
    if (choicesJson != null) {
      return (jsonDecode(choicesJson!) as List).cast<String>();
    }
    return [];
  }

  String? get choiceA => choices.isNotEmpty ? choices[0] : null;
  String? get choiceB => choices.length > 1 ? choices[1] : null;
  String? get choiceC => choices.length > 2 ? choices[2] : null;
  String? get choiceD => choices.length > 3 ? choices[3] : null;

  int? get correctChoiceIndex {
    final mc = asMultipleChoice;
    if (mc != null) return mc.correctIndex;
    return correctIndex; // legacy column fallback
  }

  String? get orderItemsJson {
    final ord = asOrdering;
    if (ord != null) return jsonEncode(ord.items);
    return choicesJson; // legacy fallback
  }
}
