import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/drift_service.dart';
import 'package:drift/drift.dart';

final allMapsProvider = StreamProvider<List<RiddleMap>>((ref) {
  return DriftService.instance.watchAllMaps();
});

final mapProvider = FutureProvider.family<RiddleMap?, String>((ref, id) async {
  final db = DriftService.instance.db;
  return await (db.select(db.riddleMaps)..where((t) => t.id.equals(id))).getSingleOrNull();
});

final riddlesForMapProvider = StreamProvider.family<List<Riddle>, String>((ref, mapId) {
  return DriftService.instance.watchRiddles(mapId);
});

final riddleCountProvider = StreamProvider.family<int, String>((ref, mapId) {
  return DriftService.instance.watchRiddles(mapId).map((list) => list.length);
});

// Provider to get the latest session for progress tracking
final latestSessionProvider = StreamProvider.family<PlaySession?, String>((ref, mapId) {
  final db = DriftService.instance.db;
  return (db.select(db.playSessions)
    ..where((t) => t.mapId.equals(mapId))
    ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderMode.desc)])
    ..limit(1))
    .watchSingleOrNull();
});
