import 'package:isar/isar.dart';

part 'play_session.g.dart';

@collection
class PlaySession {
  Id id = Isar.autoIncrement;

  @Index()
  late int mapId;

  late DateTime startedAt;
  DateTime? completedAt;

  /// Total riddles in the map at time of play
  late int totalRiddles;

  /// How many the user answered correctly
  late int correctAnswers;

  bool get isCompleted => completedAt != null;

  double get scorePercent =>
      totalRiddles == 0 ? 0 : correctAnswers / totalRiddles;

  PlaySession({
    required this.mapId,
    required this.totalRiddles,
  }) {
    startedAt = DateTime.now();
    correctAnswers = 0;
  }
}
