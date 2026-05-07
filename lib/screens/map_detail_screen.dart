import 'package:flutter/material.dart';
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
        backgroundColor: EnolaTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EnolaTheme.border),
        ),
        title: const Text(
          'Delete quest?',
          style: TextStyle(color: EnolaTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This map and all its riddles will be lost forever.',
          style: TextStyle(color: EnolaTheme.textSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: EnolaTheme.textSecond)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: EnolaTheme.wrong, fontWeight: FontWeight.bold)),
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

// ── Private Body Widget ──────────────────────────────────────────────────────

class _MapBody extends StatelessWidget {
  final RiddleMap map;
  final List<Riddle> riddles;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MapBody({
    required this.map,
    required this.riddles,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    map.title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  if (map.subject != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: EnolaTheme.accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        map.subject!.toUpperCase(),
                        style: const TextStyle(
                          color: EnolaTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    map.description ?? 'No description provided for this quest.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: EnolaTheme.textSecond),
                  ),
                  const SizedBox(height: 32),
                  // ✅ Added const here to satisfy the analyzer
                  const RuneDivider(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      // ✅ Corrected icon name
                      const Icon(Icons.quiz_outlined, color: EnolaTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${riddles.length} RIDDLES AWAIT',
                        style: EnolaTheme.sectionHeader,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (riddles.isEmpty)
                    const Text('This map is empty. Add some riddles to begin.')
                  else
                    ...riddles.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ParchmentCard(
                            child: Text(
                              r.question,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: EnolaTheme.wrong),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EnolaTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: EnolaTheme.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Edit Map', style: TextStyle(color: EnolaTheme.accent)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: riddles.isEmpty ? null : onPlay,
              child: const Text('Start Quest'),
            ),
          ),
        ],
      ),
    );
  }
}
