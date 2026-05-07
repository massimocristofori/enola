import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'riddle.dart';

part 'riddle_map.g.dart';

@collection
class RiddleMap {
  RiddleMap({
    String? id,
    required this.title,
    this.subject,
    this.description,
  }) : id = id ?? const Uuid().v4() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // ✅ FIX: String ID instead of int (web-safe)
  @Id()
  String id;

  late String title;
  String? subject;
  String? description;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  // Backlink to riddles
  final riddles = IsarLinks<Riddle>();

  void touch() {
    updatedAt = DateTime.now();
  }
}
