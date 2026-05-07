import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'riddle.g.dart';

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

  @ignore
  RiddleType get type => RiddleType.values[typeIndex];

  late String question;
  String? sourceText;
  late int orderInMap;
  late DateTime createdAt;

  String? mcChoicesJson;
  int? mcCorrectIndex;
  String? orderItemsJson;

  // ── UI BRIDGE GETTERS ──────────────────────────────────────────────────────

  @ignore
  List<String> get choices {
    if (mcChoicesJson == null) return [];
    try {
      return (jsonDecode(mcChoicesJson!) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  @ignore
  String? get choiceA => choices.length > 0 ? choices[0] : null;
  @ignore
  String? get choiceB => choices.length > 1 ? choices[1] : null;
  @ignore
  String? get choiceC => choices.length > 2 ? choices[2] : null;
  @ignore
  String? get choiceD => choices.length > 3 ? choices[3] : null;

  @ignore
  int get correctChoiceIndex => mcCorrectIndex ?? 0;
}
