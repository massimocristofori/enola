import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'play_session.g.dart';

@collection
class PlaySession {
  PlaySession({
    required this.mapId,
    required this.totalRiddles,
  }) : publicId = const Uuid().v4() {
    startedAt = DateTime.now();
    correctAnswers = 0;
  }

  /// ✅ INTERNAL Isar primary key (REQUIRED)
  Id id = Isar.autoIncrement;

  /// ✅ PUBLIC SAFE ID (for web, UI, navigation)
  @Index(unique: true)
  late String publicId;

  /// 🔥 IMPORTANT: still String UUID (not int)
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
