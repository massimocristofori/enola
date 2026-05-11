import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';

class MapDetailScreen extends ConsumerWidget {
  final String mapId;

  const MapDetailScreen({super.key, required this.mapId});

  static const List<List<Color>> _gradients = [
    [Color(0xFFa78bfa), Color(0xFF7C3AED)],
    [Color(0xFFf472b6), Color(0xFFEC4899)],
    [Color(0xFF34d399), Color(0xFF059669)],
    [Color(0xFFfbbf24), Color(0xFFd97706)],
    [Color(0xFF60a5fa), Color(0xFF2563EB)],
    [Color(0xFFf87171), Color(0xFFDC2626)],
  ];

  List<Color> _gradient(String id) {
    final idx = id.codeUnits.fold(0, (a, b) => a + b) % _gradients.length;
    return _gradients[idx];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapProvider(mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(mapId));
    final sessionAsync = ref.watch(latestSessionProvider(mapId));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      body: mapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (map) {
          if (map == null) return const SizedBox();
          return riddlesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (riddles) {
              final session = sessionAsync.valueOrNull;
              final playedCount = session != null
                  ? (session.lastCompletedIndex + 1).clamp(0, riddles.length)
                  : 0;

              return _MapDetailBody(
                map: map,
                riddleCount: riddles.length,
                playedCount: playedCount,
                gradient: _gradient(map.id),
                onPlay: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayScreen(mapId: mapId)),
                ).then((_) {
                  ref.invalidate(latestSessionProvider(mapId));
                  ref.invalidate(mapProvider(mapId));
                  ref.invalidate(riddlesForMapProvider(mapId));
                }),
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
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete quest?',
            style: TextStyle(
                color: EnolaTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          'This map and all its riddles will be lost forever.',
          style: TextStyle(color: Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: EnolaTheme.wrong, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final db = DriftService.instance.db;
      await (db.delete(db.riddleMaps)..where((t) => t.id.equals(mapId))).go();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _MapDetailBody extends StatelessWidget {
  final RiddleMap map;
  final int riddleCount;
  final int playedCount;
  final List<Color> gradient;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MapDetailBody({
    required this.map,
    required this.riddleCount,
    required this.playedCount,
    required this.gradient,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? imageBytes =
        map.imageBytes != null ? Uint8List.fromList(map.imageBytes!) : null;
    final isCompleted = playedCount >= riddleCount && riddleCount > 0;
    final progress = riddleCount > 0 ? playedCount / riddleCount : 0.0;

    return SafeArea(
      child: Column(
        children: [
          // ── Top nav ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: EnolaTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: EnolaTheme.wrong),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero card (image / gradient) ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          // Image / gradient fill
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: imageBytes != null
                                  ? Image.memory(imageBytes, fit: BoxFit.cover)
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/0.jpeg',
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                          // Subject badge — top right
                          if (map.subject != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  map.subject!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Title + meta card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          map.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: EnolaTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        if (map.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            map.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF555555),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Stats row ──
                  Row(
                    children: [
                      // Riddle count chip
                      Expanded(
                        child: _StatCard(
                          icon: Icons.auto_stories_rounded,
                          label: 'RIDDLES',
                          value: '$riddleCount',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Progress chip
                      Expanded(
                        flex: 2,
                        child: _ProgressCard(
                          played: playedCount,
                          total: riddleCount,
                          progress: progress,
                          isCompleted: isCompleted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom actions ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF555555)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(color: Color(0xFF555555))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: riddleCount == 0 ? null : onPlay,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Start Quest'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat cards ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF555555), size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: EnolaTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 9,
                  letterSpacing: 1.1)),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int played;
  final int total;
  final double progress;
  final bool isCompleted;

  const _ProgressCard({
    required this.played,
    required this.total,
    required this.progress,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.flag_outlined,
                color: const Color(0xFF555555),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isCompleted ? 'COMPLETED' : 'PROGRESS',
                style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 9,
                    letterSpacing: 1.1),
              ),
              const Spacer(),
              Text(
                '$played / $total',
                style: const TextStyle(
                    color: EnolaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF059669) : const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
