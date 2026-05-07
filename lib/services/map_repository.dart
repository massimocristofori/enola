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

  // ✅ FIX: Use the index for publicId instead of .get(int)
  Future<RiddleMap?> getMap(String publicId) async {
    return _db.riddleMaps.filter().publicIdEqualTo(publicId).findFirst();
  }

  // ✅ FIX: Return the publicId (String) instead of the internal Id (int)
  Future<String> saveMap(RiddleMap map) async {
    return _db.writeTxn(() async {
      map.updatedAt = DateTime.now();
      await _db.riddleMaps.put(map);
      return map.publicId; 
    });
  }

  Future<void> deleteMap(String publicId) async {
    await _db.writeTxn(() async {
      // 1. Delete riddles associated with this map's publicId
      final riddleIds = await _db.riddles
          .filter()
          .mapIdEqualTo(publicId)
          .idProperty()
          .findAll();

      if (riddleIds.isNotEmpty) {
        await _db.riddles.deleteAll(riddleIds);
      }

      // 2. ✅ FIX: Find the map by publicId to get the internal int id for deletion
      final map = await _db.riddleMaps.filter().publicIdEqualTo(publicId).findFirst();
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
      final oldIds = await _db.riddles
          .filter()
          .mapIdEqualTo(mapId)
          .idProperty()
          .findAll();

      if (oldIds.isNotEmpty) {
        await _db.riddles.deleteAll(oldIds);
      }

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

  // ✅ FIX: Query by publicId (if Riddle has one) or find first then delete
  Future<void> deleteRiddle(String riddlePublicId) async {
    await _db.writeTxn(() async {
      final riddle = await _db.riddles.filter().publicIdEqualTo(riddlePublicId).findFirst();
      if (riddle != null) {
        await _db.riddles.delete(riddle.id);
      }
    });
  }

  Future<int> getRiddleCount(String mapId) async {
    return _db.riddles.filter().mapIdEqualTo(mapId).count();
  }
}
