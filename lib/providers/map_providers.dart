import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'; // ✅ Added for OrderMode
import '../database/database.dart';
import '../services/drift_service.dart';

final mapsProvider = FutureProvider<List<RiddleMap>>((ref) async {
  final db = DriftService.instance.db;
  return db.getAllMaps();
});

final mapProvider = FutureProvider.family<RiddleMap?, String>((ref, id) async {
  final db = DriftService.instance.db;
  final maps = await db.getAllMaps();
  try {
    return maps.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

final riddlesForMapProvider = FutureProvider.family<List<Riddle>, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  return db.getRiddlesForMap(mapId);
});

final recentSessionsProvider = FutureProvider<List<PlaySession>>((ref) async {
  final db = DriftService.instance.db;
  return (db.select(db.playSessions)
    ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderMode.desc)])
    ..limit(5))
    .get();
});
