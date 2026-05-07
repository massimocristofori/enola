import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'riddle.dart';

part 'riddle_map.g.dart';

@collection
class RiddleMap {
  RiddleMap({
    required this.title,
    this.subject,
    this.description,
  }) : publicId = const Uuid().v4() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// ✅ INTERNAL Isar ID (required, must stay int)
  Id id = Isar.autoIncrement;

  /// ✅ PUBLIC ID (web-safe, use everywhere outside DB)
  @Index(unique: true)
  late String publicId;

  late String title;
  String? subject;
  String? description;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  /// Relation (works with internal Isar id OR link system)
  final riddles = IsarLinks<Riddle>();

  void touch() {
    updatedAt = DateTime.now();
  }
}
