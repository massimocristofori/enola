import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/riddle_map.dart';
import '../models/riddle.dart';
import '../services/map_repository.dart';

// ── Maps ──────────────────────────────────────────────────────────────────────

final allMapsProvider = StreamProvider<List<RiddleMap>>((ref) {
  return MapRepository.instance.watchAllMaps();
});

final mapProvider =
    FutureProvider.family<RiddleMap?, String>((ref, id) {
  return MapRepository.instance.getMap(id);
});

// ── Riddles ───────────────────────────────────────────────────────────────────

final riddlesForMapProvider =
    FutureProvider.family<List<Riddle>, String>((ref, mapId) {
  return MapRepository.instance.getRiddlesForMap(mapId);
});

final riddleCountProvider =
    FutureProvider.family<int, String>((ref, mapId) {
  return MapRepository.instance.getRiddleCount(mapId);
});
