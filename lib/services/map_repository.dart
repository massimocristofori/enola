import 'package:isar/isar.dart';
import '../models/riddle_map.dart';
import '../models/riddle.dart';
import 'isar_service.dart';

class MapRepository {
  MapRepository._();
  static final MapRepository instance = MapRepository._();

  Isar get _db => IsarService.instance.db;

  // ── Maps ──────────────────────────────────────────────────────────────────

  Future<List<RiddleMap>> getAllMaps() async {
    return _db.riddleMaps.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<RiddleMap>> watchAllMaps() {
    return _db.riddleMaps
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<RiddleMap?> getMap(int id) async {
    return _db.riddleMaps.get(id);
  }

  Future<int> saveMap(RiddleMap map) async {
    return _db.writeTxn(() async {
      map.updatedAt = DateTime.now();
      return _db.riddleMaps.put(map);
    });
  }

  Future<void> deleteMap(int id) async {
    await _db.writeTxn(() async {
      // Delete all riddles belonging to this map first
      final riddleIds = await _db.riddles
          .filter()
          .mapIdEqualTo(id)
          .idProperty()
          .findAll();
      await _db.riddles.deleteAll(riddleIds);
      await _db.riddleMaps.delete(id);
    });
  }

  // ── Riddles ───────────────────────────────────────────────────────────────

  Future<List<Riddle>> getRiddlesForMap(int mapId) async {
    return _db.riddles
        .filter()
        .mapIdEqualTo(mapId)
        .sortByOrderInMap()
        .findAll();
  }

  /// Saves a list of riddles and links them to the map.
  /// Replaces all existing riddles for this map.
  Future<void> saveRiddles(int mapId, List<Riddle> riddles) async {
    await _db.writeTxn(() async {
      // Remove old riddles
      final oldIds = await _db.riddles
          .filter()
          .mapIdEqualTo(mapId)
          .idProperty()
          .findAll();
      await _db.riddles.deleteAll(oldIds);

      // Assign mapId and save
      for (var i = 0; i < riddles.length; i++) {
        riddles[i].mapId = mapId;
        riddles[i].orderInMap = i;
      }
      await _db.riddles.putAll(riddles);
    });
  }

  Future<void> addRiddle(Riddle riddle) async {
    await _db.writeTxn(() => _db.riddles.put(riddle));
  }

  Future<void> deleteRiddle(int riddleId) async {
    await _db.writeTxn(() => _db.riddles.delete(riddleId));
  }

  Future<int> getRiddleCount(int mapId) async {
    return _db.riddles.filter().mapIdEqualTo(mapId).count();
  }
}
