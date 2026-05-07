import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';

import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/map_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(allMapsProvider);

    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              const SizedBox(height: 8),
              Expanded(
                child: mapsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: EnolaTheme.accent,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: EnolaTheme.wrong),
                    ),
                  ),
                  data: (maps) => maps.isEmpty
                      ? _EmptyState(
                          onCreate: () => _openCreate(context),
                        )
                      : _MapList(
                          maps: maps,
                          onCreate: () => _openCreate(context),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _CreateFab(
        onTap: () => _openCreate(context),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateMapScreen(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          const EnolaLogo(fontSize: 28),
          const SizedBox(height: 6),
          Text(
            'Your Quest Maps',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EnolaTheme.textSecond,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 16),
          const RuneDivider(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }
}

class _MapList extends ConsumerWidget {
  final List<RiddleMap> maps;
  final VoidCallback onCreate;

  // ✅ FIXED: Removed super.key to satisfy linter
  const _MapList({
    required this.maps,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: maps.length,
      itemBuilder: (context, i) {
        final map = maps[i];

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _MapTile(map: map, index: i),
        )
            .animate(delay: (i * 80).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.15, end: 0);
      },
    );
  }
}

class _MapTile extends ConsumerWidget {
  final RiddleMap map;
  final int index;

  // ✅ FIXED: Removed super.key to satisfy linter
  const _MapTile({
    required this.map,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(riddleCountProvider(map.id));
    final count = countAsync.valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapDetailScreen(
            mapId: map.id, 
          ),
        ),
      ),
      child: ParchmentCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: EnolaTheme.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: EnolaTheme.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    map.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (map.subject != null) ...[
                        _Tag(map.subject!),
                        const SizedBox(width: 8),
                      ],
                      _Tag('$count riddles'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y').format(map.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: EnolaTheme.textSecond,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: EnolaTheme.accent,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: EnolaTheme.accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: EnolaTheme.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TorchFlame(size: 48)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 1200.ms,
                ),
            const SizedBox(height: 24),
            Text(
              'No quest maps yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: EnolaTheme.accent,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first map of riddles\nand begin the adventure.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Quest Map'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms).scale(
            begin: const Offset(0.9, 0.9),
          ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: EnolaTheme.accent,
      foregroundColor: EnolaTheme.background,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Map',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
