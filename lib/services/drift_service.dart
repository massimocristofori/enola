import 'package:drift/drift.dart';
import 'package:enola/database/database.dart';
import 'package:enola/database/connection/connection.dart' as impl;

class DriftService {
  // Singleton pattern
  static final DriftService instance = DriftService._internal();
  late AppDatabase db;

  DriftService._internal() {
    db = AppDatabase(impl.connect());
  }

  // Example: Save a Map
  Future<void> saveMap(String id, String title, String? description) async {
    await db.into(db.riddleMaps).insert(
      RiddleMapsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // Example: Get Riddles for a specific Map
  Stream<List<Riddle>> watchRiddles(String mapId) {
    return (db.select(db.riddles)..where((t) => t.mapId.equals(mapId))).watch();
  }
}
