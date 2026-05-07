import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'riddle.g.dart';

// ✅ Add this Enum to fix "Undefined name 'RiddleType'"
enum RiddleType {
  multipleChoice,
  ordering,
  text,
}

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

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String publicId;

  @Index()
  late String mapId;

  late int typeIndex;

  // ✅ Add this helper getter to fix the UI errors
  @ignore
  RiddleType get type => RiddleType.values[typeIndex];

  late String question;
  String? sourceText;
  late int orderInMap;
  late DateTime createdAt;

  String? mcChoicesJson;
  int? mcCorrectIndex;
  String? orderItemsJson;
}
