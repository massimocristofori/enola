import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/riddle.dart';
import '../../models/riddle_map.dart';
import '../../providers/map_providers.dart';
import '../../services/map_repository.dart';
import '../../theme/enola_theme.dart';
import '../../widgets/fantasy_widgets.dart';
import '../create_map/create_map_screen.dart';
import '../play/play_screen.dart';

class MapDetailScreen extends ConsumerWidget {
  final int mapId;
  const MapDetailScreen({super.key, required this.mapId});

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
        title: const Text('Delete quest?',
            style: TextStyle(color: EnolaTheme.textPrimary)),
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
                style: TextStyle(color: EnolaTheme.wrong)),
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

// ── Map Body ──────────────────────────────────────────────────────────────────

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
    return CustomScrollView(
      slivers: [
        _MapAppBar(map: map, onEdit: onEdit, onDelete: onDelete),
        SliverToBoxAdapter(
          child: _MapStats(map: map, riddleCount: riddles.length),
        ),
        if (riddles.isEmpty)
          SliverFillRemaining(
            child: _EmptyMap(onEdit: onEdit),
          )
        else ...[
          SliverToBoxAdapter(
            child: _QuestPath(riddles: riddles),
          ),
          SliverToBoxAdapter(
            child: _PlayButton(
              onPlay: onPlay,
              riddleCount: riddles.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ],
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget {
  final RiddleMap map;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MapAppBar(
      {required this.map, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D08),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: EnolaTheme.accent),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: EnolaTheme.accent),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: EnolaTheme.textSecond),
          onPressed: onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1508), Color(0xFF0D0D08)],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (map.subject != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EnolaTheme.accentSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        map.subject!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: EnolaTheme.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  Text(
                    map.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: EnolaTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _MapStats extends StatelessWidget {
  final RiddleMap map;
  final int riddleCount;

  const _MapStats({required this.map, required this.riddleCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          _StatChip(icon: Icons.menu_book_rounded, label: '$riddleCount Riddles'),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.auto_fix_high_rounded,
            label: 'Quest Map',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A3F22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: EnolaTheme.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: EnolaTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quest Path (the main RPG map) ─────────────────────────────────────────────

class _QuestPath extends StatelessWidget {
  final List<Riddle> riddles;
  const _QuestPath({required this.riddles});

  @override
  Widget build(BuildContext context) {
    // For now, first riddle is "current", rest are locked
    // In a real play session this would come from saved progress
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Map header
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                const RuneDivider(),
              ],
            ),
          ),
          for (var i = 0; i < riddles.length; i++) ...[
            _buildNode(context, riddles[i], i, riddles.length),
            if (i < riddles.length - 1)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: PathConnector(
                  completed: false,
                  isLeft: i.isEven,
                ),
              )
                  .animate(delay: ((i + 1) * 100).ms)
                  .fadeIn(duration: 300.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildNode(
      BuildContext context, Riddle riddle, int index, int total) {
    final nodeState = index == 0 ? NodeState.current : NodeState.locked;
    final type = _typeFromRiddle(riddle);

    // Alternating left/center/right layout for path feel
    final alignment = switch (index % 3) {
      0 => Alignment.center,
      1 => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };

    return Align(
      alignment: alignment,
      child: Column(
        children: [
          QuestNode(
            index: index,
            state: nodeState,
            label: 'Riddle ${index + 1}',
            type: type,
          ),
          const SizedBox(height: 6),
          Text(
            'Riddle ${index + 1}',
            style: TextStyle(
              fontSize: 11,
              color: index == 0 ? EnolaTheme.accent : EnolaTheme.textSecond,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 120).ms)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1));
  }

  RiddleNodeType _typeFromRiddle(Riddle r) {
    return switch (r.type) {
      RiddleType.multipleChoice => RiddleNodeType.multipleChoice,
      RiddleType.ordering => RiddleNodeType.ordering,
    };
  }
}

// ── Play Button ───────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final VoidCallback onPlay;
  final int riddleCount;

  const _PlayButton({required this.onPlay, required this.riddleCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          const RuneDivider(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: EnolaTheme.accent,
                foregroundColor: EnolaTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: EnolaTheme.accent.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const TorchFlame(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Begin the Quest',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 17,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(width: 12),
                  const TorchFlame(size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 500.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

// ── Empty map state ───────────────────────────────────────────────────────────

class _EmptyMap extends StatelessWidget {
  final VoidCallback onEdit;
  const _EmptyMap({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_fix_high_rounded,
                size: 48, color: EnolaTheme.textSecond),
            const SizedBox(height: 16),
            const Text(
              'No riddles yet',
              style: TextStyle(
                  color: EnolaTheme.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add riddles manually or scan pages\nto generate them with AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: EnolaTheme.textSecond),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Add Riddles'),
            ),
          ],
        ),
      ),
    );
  }
}
