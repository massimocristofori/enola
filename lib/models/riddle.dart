import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'riddle.g.dart';

@collection
class Riddle {
  Riddle({
    required this.mapId,
    required this.typeIndex,
    required this.question,
    this.sourceText,
    required this.orderInMap,
    this.mcChoicesJson,
    this.mcCorrectIndex,
    this.orderItemsJson,
  }) : publicId = const Uuid().v4() {
    createdAt = DateTime.now();
  }

  /// ✅ INTERNAL Isar ID (required)
  Id id = Isar.autoIncrement;

  /// ✅ PUBLIC SAFE ID (use everywhere outside DB)
  @Index(unique: true)
  late String publicId;

  /// 🔥 UUID of parent map (NOT int)
  @Index()
  late String mapId;

  late int typeIndex;

  late String question;

  String? sourceText;

  late int orderInMap;

  late DateTime createdAt;

  // ── Multiple choice ─────────────────────────────
  String? mcChoicesJson;
  int? mcCorrectIndex;

  // ── Ordering ────────────────────────────────────
  String? orderItemsJson;
}
