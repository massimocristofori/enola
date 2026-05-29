import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:enola/database/schema_utils.dart';

part 'database.g.dart';

// ---

class RiddleMaps extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get subject => text().nullable()();
  BlobColumn get imageBytes => blob().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get riddlesVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Riddles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();
  TextColumn get question => text()();
  IntColumn get typeIndex => integer()();
  IntColumn get orderInMap => integer()();
  TextColumn get payloadJson => text().nullable()();
  TextColumn get choicesJson => text().nullable()();
  IntColumn get correctIndex => integer().nullable()();
  TextColumn get sourceExcerpt => text().nullable()();
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
  TextColumn get riddleStarsJson => text().nullable()();
  IntColumn get riddlesVersion => integer().withDefault(const Constant(0))();
}

class TrainingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mapId => text().references(RiddleMaps, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get poolJson => text().withDefault(const Constant('[]'))();
  TextColumn get scheduledJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// ── NEW ───────────────────────────────────────────────────────────────────────

class TrainingNotifiedRiddles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(TrainingSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get mapId => text()();
  IntColumn get riddleId => integer().references(Riddles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get notifiedAt => dateTime().withDefault(currentDateAndTime)();
}

class TrainingAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(TrainingSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get riddleId => integer().references(Riddles, #id, onDelete: KeyAction.cascade)();
  BoolColumn get correct => boolean()();
  DateTimeColumn get answeredAt => dateTime().withDefault(currentDateAndTime)();
}

// ---

sealed class RiddlePayload {
  const RiddlePayload();

  Map<String, dynamic> toJson();

  static RiddlePayload fromJson(RiddleType type, Map<String, dynamic> json) {
    return switch (type) {
      RiddleType.multipleChoice => MultipleChoicePayload.fromJson(json),
      RiddleType.trueFalse      => MultipleChoicePayload.fromJson(json),
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
        choices: (json['choices'] as List?)?.cast<String>() ?? [],
        correctIndex: (json['correctIndex'] as int?) ?? 0,
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
        items: (json['items'] as List?)?.cast<String>() ?? [],
      );

  @override
  Map<String, dynamic> toJson() => {'items': items};
}

// ---

@DriftDatabase(tables: [
  RiddleMaps,
  Riddles,
  PlaySessions,
  TrainingSessions,
  TrainingNotifiedRiddles, // NEW
  TrainingAttempts,        // NEW
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(riddles, riddles.payloadJson);
      }
      if (from < 3) {
        await m.addColumn(riddleMaps, riddleMaps.imageBytes);
      }
      if (from < 4) {
        await m.addColumn(playSessions, playSessions.riddleStarsJson);
      }
      if (from < 5) {
        await m.addColumn(riddles, riddles.sourceExcerpt);
      }
      if (from < 6) {
        await m.addColumn(riddleMaps, riddleMaps.riddlesVersion);
        await m.addColumn(playSessions, playSessions.riddlesVersion);
      }
      if (from < 7) {
        await m.createTable(trainingSessions);
      }
      if (from < 8) {
        await m.createTable(trainingNotifiedRiddles);
        await m.createTable(trainingAttempts);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---

  Future<List<RiddleMap>> getAllMaps() => select(riddleMaps).get();
  Future<void> insertMap(RiddleMapsCompanion entity) =>
      into(riddleMaps).insertOnConflictUpdate(entity);

  Future<List<Riddle>> getRiddlesForMap(String mapId) =>
      (select(riddles)..where((t) => t.mapId.equals(mapId))).get();

  Future<int> createSession(PlaySessionsCompanion entity) =>
      into(playSessions).insert(entity);
  Stream<PlaySession> watchSession(int id) =>
      (select(playSessions)..where((t) => t.id.equals(id))).watchSingle();
  Future<void> updateSession(PlaySession session) =>
      update(playSessions).replace(session);
}

// ---

extension RiddleUtils on Riddle {
  RiddleType get type => RiddleType.values[typeIndex];

  Map<String, dynamic> get _payloadMap {
    final raw = payloadJson;
    if (raw == null || raw.isEmpty || raw == '{}') return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  RiddlePayload get payload => RiddlePayload.fromJson(type, _payloadMap);

  MultipleChoicePayload? get asMultipleChoice =>
      (type == RiddleType.multipleChoice || type == RiddleType.trueFalse)
          ? payload as MultipleChoicePayload
          : null;

  OrderingPayload? get asOrdering =>
      type == RiddleType.ordering ? payload as OrderingPayload : null;

  List<String> get choices {
    final mc = asMultipleChoice;
    if (mc != null) return mc.choices;
    final ord = asOrdering;
    if (ord != null) return ord.items;
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
    return correctIndex;
  }

  String? get orderItemsJson {
    final ord = asOrdering;
    if (ord != null) return jsonEncode(ord.items);
    return choicesJson;
  }
}
