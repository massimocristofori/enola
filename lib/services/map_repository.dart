import 'package:isar/isar.dart';
import '../models/riddle_map.dart';
import '../models/riddle.dart';
import 'isar_service.dart';

class MapRepository {
  MapRepository._();
  static final MapRepository instance = MapRepository._();

  Isar get _db => IsarService.instance.db;

  // ─────────────────────────────────────────────────────────────
  // MAPS
  // ─────────────────────────────────────────────────────────────

  Future<List<RiddleMap>> getAllMaps() async {
    return _db.riddleMaps.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<RiddleMap>> watchAllMaps() {
    return _db.riddleMaps
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<RiddleMap?> getMap(String id) async {
    return _db.riddleMaps.get(id);
  }

  Future<String> saveMap(RiddleMap map) async {
    return _db.writeTxn(() async {
      map.updatedAt = DateTime.now();
      await _db.riddleMaps.put(map);

      // Source of truth is UUID on the object
      return map.id;
    });
  }

  Future<void> deleteMap(String id) async {
    await _db.writeTxn(() async {
      // delete all riddles belonging to this map
      final riddleIds = await _db.riddles
          .filter()
          .mapIdEqualTo(id)
          .idProperty()
          .findAll();

      if (riddleIds.isNotEmpty) {
        await _db.riddles.deleteAll(riddleIds);
      }

      // delete map safely
      final map = await _db.riddleMaps.get(id);
      if (map != null) {
        await _db.riddleMaps.delete(map.id);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // RIDDLES
  // ─────────────────────────────────────────────────────────────

  Future<List<Riddle>> getRiddlesForMap(String mapId) async {
    return _db.riddles
        .filter()
        .mapIdEqualTo(mapId)
        .sortByOrderInMap()
        .findAll();
  }

  Future<void> saveRiddles(String mapId, List<Riddle> riddles) async {
    await _db.writeTxn(() async {
      // remove existing riddles for this map
      final oldIds = await _db.riddles
          .filter()
          .mapIdEqualTo(mapId)
          .idProperty()
          .findAll();

      if (oldIds.isNotEmpty) {
        await _db.riddles.deleteAll(oldIds);
      }

      // reinsert with correct ordering
      for (var i = 0; i < riddles.length; i++) {
        riddles[i].mapId = mapId;
        riddles[i].orderInMap = i;
        await _db.riddles.put(riddles[i]);
      }
    });
  }

  Future<void> addRiddle(Riddle riddle) async {
    await _db.writeTxn(() => _db.riddles.put(riddle));
  }

  Future<void> deleteRiddle(String riddleId) async {
    await _db.writeTxn(() => _db.riddles.delete(riddleId));
  }

  Future<int> getRiddleCount(String mapId) async {
    return _db.riddles.filter().mapIdEqualTo(mapId).count();
  }
}
