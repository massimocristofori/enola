import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ Import the new database classes instead of old models
import '../database/database.dart';
import '../services/drift_service.dart';

// ── Maps ──────────────────────────────────────────────────────────────────────

/// Streams all quest maps from the database. 
/// UI will rebuild automatically when maps are added or deleted.
final allMapsProvider = StreamProvider<List<RiddleMap>>((ref) {
  return DriftService.instance.watchAllMaps();
});

/// Fetches a single map by its ID.
final mapProvider = FutureProvider.family<RiddleMap?, String>((ref, id) async {
  // We can use the Drift instance directly
  final db = DriftService.instance.db;
  return await (db.select(db.riddleMaps)..where((t) => t.id.equals(id))).getSingleOrNull();
});

// ── Riddles ───────────────────────────────────────────────────────────────────

/// Streams the list of riddles for a specific map.
final riddlesForMapProvider = StreamProvider.family<List<Riddle>, String>((ref, mapId) {
  return DriftService.instance.watchRiddles(mapId);
});

/// Streams the count of riddles for a specific map.
/// This is used in the HomeScreen tiles.
final riddleCountProvider = StreamProvider.family<int, String>((ref, mapId) {
  return DriftService.instance.watchRiddles(mapId).map((list) => list.length);
});

// ── Play Sessions (New) ───────────────────────────────────────────────────────

/// Watches a specific play session's progress.
final sessionProvider = StreamProvider.family<PlaySession, int>((ref, sessionId) {
  return DriftService.instance.watchSession(sessionId);
});
