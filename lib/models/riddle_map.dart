import 'package:isar/isar.dart';
import 'riddle.dart';

part 'riddle_map.g.dart';

@collection
class RiddleMap {
  Id id = Isar.autoIncrement;

  late String title;
  String? subject;
  String? description;

  @Index()
  late DateTime createdAt;
  late DateTime updatedAt;

  // Backlink to riddles
  final riddles = IsarLinks<Riddle>();

  RiddleMap({
    required this.title,
    this.subject,
    this.description,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }
}
