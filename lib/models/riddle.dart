import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'riddle.g.dart';

@collection
class Riddle {
  Riddle({
    String? id,
    required this.mapId,
    required this.typeIndex,
    required this.question,
    this.sourceText,
    required this.orderInMap,
    this.mcChoicesJson,
    this.mcCorrectIndex,
    this.orderItemsJson,
  }) : id = id ?? const Uuid().v4() {
    createdAt = DateTime.now();
  }

  /// ✅ FIX: String ID (web-safe)
  @Id()
  String id;

  /// 🔥 IMPORTANT: was int → now String to match RiddleMap.id
  @Index()
  late String mapId;

  /// Discriminator: 0 = multipleChoice, 1 = ordering
  late int typeIndex;

  late String question;

  String? sourceText;

  late int orderInMap;

  late DateTime createdAt;

  // ── Multiple choice fields ────────────────────────────────────────────────
  String? mcChoicesJson;
  int? mcCorrectIndex;

  // ── Ordering fields ───────────────────────────────────────────────────────
  String? orderItemsJson;
}

/// Enum stored in Isar — add new types here as the app grows.
enum RiddleType {
  multipleChoice,
  ordering,
}

extension RiddleTypeX on Riddle {
  RiddleType get type => RiddleType.values[typeIndex];
  set type(RiddleType t) => typeIndex = t.index;
}
