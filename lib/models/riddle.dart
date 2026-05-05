import 'package:isar/isar.dart';

part 'riddle.g.dart';

/// Enum stored in Isar — add new types here as the app grows.
@collection
class Riddle {
  Id id = Isar.autoIncrement;

  /// Foreign key back to the parent RiddleMap
  @Index()
  late int mapId;

  /// Discriminator: 0 = multipleChoice, 1 = ordering
  late int typeIndex;

  late String question;

  /// The original source text chunk this riddle was generated from (nullable)
  String? sourceText;

  late int orderInMap;

  late DateTime createdAt;

  // ── Multiple choice fields ──────────────────────────────────────────────────
  /// JSON-encoded list of choice strings, e.g. '["Rome","Paris","Berlin"]'
  String? mcChoicesJson;
  int? mcCorrectIndex;

  // ── Ordering fields ─────────────────────────────────────────────────────────
  /// JSON-encoded list of item strings in the CORRECT order
  String? orderItemsJson;

  Riddle() {
    createdAt = DateTime.now();
  }
}

/// Convenience enum — kept in sync with typeIndex
enum RiddleType {
  multipleChoice, // 0
  ordering,       // 1
}

extension RiddleTypeX on Riddle {
  RiddleType get type => RiddleType.values[typeIndex];
  set type(RiddleType t) => typeIndex = t.index;
}
