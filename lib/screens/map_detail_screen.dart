import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';

class MapDetailScreen extends ConsumerWidget {
  final String mapId;

  const MapDetailScreen({super.key, required this.mapId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapProvider(mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(mapId));
    final sessionAsync = ref.watch(latestSessionProvider(mapId));

    return Scaffold(
      body: FantasyBackground(
        child: mapAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
          error: (e, _) => Center(child: Text('$e')),
          data: (map) {
            if (map == null) return const SizedBox();
            return riddlesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
              error: (e, _) => Center(child: Text('$e')),
              data: (riddles) {
                final session = sessionAsync.valueOrNull;
                final playedCount = session != null
                    ? (session.lastCompletedIndex + 1).clamp(0, riddles.length)
                    : 0;

                return _MapBody(
                  map: map,
                  riddleCount: riddles.length,
                  playedCount: playedCount,
                  mapId: mapId,
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
        title: const Text('Delete quest?',
            style: TextStyle(
                color: EnolaTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          'This map and all its riddles will be lost forever.',
          style: TextStyle(color: EnolaTheme.textSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: EnolaTheme.textSecond)),
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

class _MapBody extends StatelessWidget {
  final RiddleMap map;
  final int riddleCount;
  final int playedCount;
  final String mapId;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MapBody({
    required this.map,
    required this.riddleCount,
    required this.playedCount,
    required this.mapId,
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
                  _buildCoverImage(),
                  const SizedBox(height: 24),
                  _buildTitleRow(context),
                  const SizedBox(height: 24),
                  const RuneDivider(),
                  const SizedBox(height: 24),
                  _buildStatsRow(context),
                  if (map.description != null) ...[
                    const SizedBox(height: 24),
                    const RuneDivider(),
                    const SizedBox(height: 24),
                    Text(
                      map.description!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: EnolaTheme.textSecond),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final bytes = map.imageBytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Container(
                color: EnolaTheme.accentSoft,
                child: const Center(
                  child: Icon(Icons.map_outlined,
                      size: 56, color: EnolaTheme.accent),
                ),
              ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          map.title,
          style: Theme.of(context)
              .textTheme
              .displayLarge
              ?.copyWith(fontSize: 28),
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
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final progress = riddleCount > 0 ? playedCount / riddleCount : 0.0;
    final isCompleted = playedCount >= riddleCount && riddleCount > 0;

    return Row(
      children: [
        _StatChip(
          icon: Icons.quiz_outlined,
          label: 'RIDDLES',
          value: '$riddleCount',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProgressChip(
            played: playedCount,
            total: riddleCount,
            progress: progress,
            isCompleted: isCompleted,
          ),
        ),
      ],
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
            icon: const Icon(Icons.delete_outline_rounded,
                color: EnolaTheme.wrong),
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
            color: Colors.black.withAlpha(13),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Edit Map',
                  style: TextStyle(color: EnolaTheme.accent)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: riddleCount == 0 ? null : onPlay,
              child: const Text('Start Quest'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chips ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: EnolaTheme.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EnolaTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: EnolaTheme.accent, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: EnolaTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: EnolaTheme.textSecond,
                  fontSize: 9,
                  letterSpacing: 1.1)),
        ],
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final int played;
  final int total;
  final double progress;
  final bool isCompleted;

  const _ProgressChip({
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
        color: EnolaTheme.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EnolaTheme.border),
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
                color: EnolaTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isCompleted ? 'COMPLETED' : 'PROGRESS',
                style: const TextStyle(
                    color: EnolaTheme.textSecond,
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
              backgroundColor: EnolaTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(EnolaTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}
