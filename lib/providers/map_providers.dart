import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'; // ✅ This MUST be here to fix OrderMode errors
import '../database/database.dart';
import '../services/drift_service.dart';

// Renamed from mapsProvider to match HomeScreen
final allMapsProvider = FutureProvider<List<RiddleMap>>((ref) async {
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

// Added for HomeScreen Map Tiles
final riddleCountProvider = FutureProvider.family<int, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final list = await db.getRiddlesForMap(mapId);
  return list.length;
});

// Added for TreasureMapPath progress tracking
final latestSessionProvider = FutureProvider.family<PlaySession?, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final sessions = await (db.select(db.playSessions)
        ..where((t) => t.mapId.equals(mapId))
        ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderMode.desc)])
        ..limit(1))
      .get();
  return sessions.isNotEmpty ? sessions.first : null;
});

// Added for displaying recent activity
final recentSessionsProvider = FutureProvider<List<PlaySession>>((ref) async {
  final db = DriftService.instance.db;
  return (db.select(db.playSessions)
    ..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderMode.desc)])
    ..limit(5))
    .get();
});
