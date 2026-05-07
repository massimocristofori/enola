import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/models/riddle.dart';
import 'package:enola/models/riddle_map.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/services/map_repository.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';

class MapDetailScreen extends ConsumerWidget {
  final String mapId;

  const MapDetailScreen({
    super.key,
    required this.mapId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapProvider(mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(mapId));

    return Scaffold(
      body: FantasyBackground(
        child: mapAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: EnolaTheme.accent),
          ),
          error: (e, _) => Center(child: Text('$e')),
          data: (map) {
            if (map == null) return const SizedBox();

            return riddlesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: EnolaTheme.accent),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (riddles) => _MapBody(
                map: map,
                riddles: riddles,
                onPlay: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayScreen(mapId: mapId),
                  ),
                ),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateMapScreen(existingMapId: mapId),
                  ),
                ).then((_) {
                  ref.invalidate(mapProvider(mapId));
                  ref.invalidate(riddlesForMapProvider(mapId));
                }),
                onDelete: () => _confirmDelete(context, ref),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4A3F22)),
        ),
        title: const Text(
          'Delete quest?',
          style: TextStyle(color: EnolaTheme.textPrimary),
        ),
        content: const Text(
          'This map and all its riddles will be lost forever.',
          style: TextStyle(color: EnolaTheme.textSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: EnolaTheme.textSecond),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: EnolaTheme.wrong),
            ),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await MapRepository.instance.deleteMap(mapId);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
