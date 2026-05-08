import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; // ✅ Use a prefix to avoid any shadowing
import '../database/database.dart';
import '../services/drift_service.dart';

// Provides all maps for the HomeScreen
final allMapsProvider = FutureProvider<List<RiddleMap>>((ref) async {
  final db = DriftService.instance.db;
  return db.getAllMaps();
});

// Provides a single map by its ID
final mapProvider = FutureProvider.family<RiddleMap?, String>((ref, id) async {
  final db = DriftService.instance.db;
  final maps = await db.getAllMaps();
  try {
    return maps.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

// Provides all riddles for a specific map
final riddlesForMapProvider = FutureProvider.family<List<Riddle>, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  return db.getRiddlesForMap(mapId);
});

// Provides the count of riddles for the HomeScreen tiles
final riddleCountProvider = FutureProvider.family<int, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final list = await db.getRiddlesForMap(mapId);
  return list.length;
});

// Provides the most recent play session for the Map Detail Screen
final latestSessionProvider = FutureProvider.family<PlaySession?, String>((ref, mapId) async {
  final db = DriftService.instance.db;
  final sessions = await (db.select(db.playSessions)
        ..where((t) => t.mapId.equals(mapId))
        ..orderBy([(t) => drift.OrderingTerm(expression: t.startedAt, mode: drift.OrderMode.desc)]) // ✅ Explicitly use drift prefix
        ..limit(1))
      .get();
  return sessions.isNotEmpty ? sessions.first : null;
});

// Provides the 5 most recent overall sessions for the Activity Feed
final recentSessionsProvider = FutureProvider<List<PlaySession>>((ref) async {
  final db = DriftService.instance.db;
  return (db.select(db.playSessions)
    ..orderBy([(t) => drift.OrderingTerm(expression: t.startedAt, mode: drift.OrderMode.desc)]) // ✅ Explicitly use drift prefix
    ..limit(5))
    .get();
});
