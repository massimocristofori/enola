import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/riddle_map.dart';
import '../models/riddle.dart';
import '../services/map_repository.dart';

// ── Maps ──────────────────────────────────────────────────────────────────────

/// Stream of all maps, used on the Home screen.
final allMapsProvider = StreamProvider<List<RiddleMap>>((ref) {
  return MapRepository.instance.watchAllMaps();
});

/// A single map by id.
final mapProvider = FutureProvider.family<RiddleMap?, int>((ref, id) {
  return MapRepository.instance.getMap(id);
});

// ── Riddles ───────────────────────────────────────────────────────────────────

/// All riddles for a given map id.
final riddlesForMapProvider =
    FutureProvider.family<List<Riddle>, int>((ref, mapId) {
  return MapRepository.instance.getRiddlesForMap(mapId);
});

/// Riddle count for a map (used in list tiles).
final riddleCountProvider = FutureProvider.family<int, int>((ref, mapId) {
  return MapRepository.instance.getRiddleCount(mapId);
});
