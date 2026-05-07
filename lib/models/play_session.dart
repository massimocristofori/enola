import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'play_session.g.dart';

@collection
class PlaySession {
  PlaySession({
    String? id,
    required this.mapId,
    required this.totalRiddles,
  })  : id = id ?? const Uuid().v4() {
    startedAt = DateTime.now();
    correctAnswers = 0;
  }

  /// ✅ FIX: String ID instead of autoIncrement int
  @Id()
  String id;

  /// 🔥 IMPORTANT: must match RiddleMap.id type (now String UUID)
  @Index()
  late String mapId;

  late DateTime startedAt;
  DateTime? completedAt;

  late int totalRiddles;
  late int correctAnswers;

  bool get isCompleted => completedAt != null;

  double get scorePercent =>
      totalRiddles == 0 ? 0 : correctAnswers / totalRiddles;

  void markCompleted() {
    completedAt = DateTime.now();
  }

  void incrementCorrect() {
    correctAnswers++;
  }
}
