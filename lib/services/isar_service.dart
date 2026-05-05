import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/riddle_map.dart';
import '../models/riddle.dart';
import '../models/play_session.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;

  Isar get db {
    assert(_isar != null, 'IsarService not initialised. Call init() first.');
    return _isar!;
  }

  Future<void> init() async {
    if (_isar != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        RiddleMapSchema,
        RiddleSchema,
        PlaySessionSchema,
      ],
      directory: dir.path,
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
