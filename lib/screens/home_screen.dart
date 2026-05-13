import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      backgroundColor: const Color(0xFFF0F0F5),
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: mapsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: EnolaTheme.accent),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: EnolaTheme.wrong)),
                ),
                data: (maps) => maps.isEmpty
                    ? _EmptyState(onCreate: () => _openCreate(context))
                    : _MapGrid(
                        maps: maps,
                        onCreate: () => _openCreate(context),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _CreateFab(onTap: () => _openCreate(context)),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMapScreen()),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Quest Maps',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: EnolaTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap a map to explore or play',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: EnolaTheme.textSecond,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0);
  }
}

// ── Responsive Grid ───────────────────────────────────────────────────────────

class _MapGrid extends ConsumerWidget {
  final List<RiddleMap> maps;
  final VoidCallback onCreate;

  const _MapGrid({required this.maps, required this.onCreate});

  int _crossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(width);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: maps.length,
      itemBuilder: (context, i) {
        return _MapCard(map: maps[i])
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: 350.ms)
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────


class _MapCard extends ConsumerWidget {
  final RiddleMap map;
  const _MapCard({required this.map});

  // --- RESTORED GRADIENT DATA ---
  static const List<List<Color>> _gradients = [
    [Color(0xFFa78bfa), Color(0xFF7C3AED)],
    [Color(0xFFf472b6), Color(0xFFEC4899)],
    [Color(0xFF34d399), Color(0xFF059669)],
    [Color(0xFFfbbf24), Color(0xFFd97706)],
    [Color(0xFF60a5fa), Color(0xFF2563EB)],
    [Color(0xFFf87171), Color(0xFFDC2626)],
  ];

  // --- RESTORED GRADIENT METHOD ---
  List<Color> _gradient() {
    final idx = map.id.codeUnits.fold(0, (a, b) => a + b) % _gradients.length;
    return _gradients[idx];
  }

  // Confirmation dialog for deletion
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Map'),
        content: const Text('Are you sure you want to delete this map? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Call your delete provider logic here
              // ref.read(yourMapProvider.notifier).delete(map.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final countAsync = ref.watch(riddleCountProvider(map.id));
  final count = countAsync.valueOrNull ?? 0;
  final grad = _gradient();

  final Uint8List? imageBytes =
      map.imageBytes != null ? Uint8List.fromList(map.imageBytes!) : null;

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapDetailScreen(mapId: map.id)),
    ),
    // --- KEY: clipBehavior.none so ears can overflow ---
    child: Stack(
      clipBehavior: Clip.none,
      children: [

        // ── The card itself ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                // ── Full card image / gradient ──
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: grad,
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

                // ── Bottom info bar ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10)),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            map.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: EnolaTheme.textPrimary,
                              height: 1.3,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.auto_stories_rounded,
                                  size: 14, color: Color(0xFF555555)),
                              const SizedBox(width: 4),
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Top-left ear (Edit) — overflows the card ──
        Positioned(
          top: -14,
          left: -14,
          child: _EarButton(
            icon: Icons.edit_rounded,
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => EditMapScreen(map: map)));
            },
          ),
        ),

        // ── Top-right ear (Delete) — overflows the card ──
        Positioned(
          top: -14,
          right: -14,
          child: _EarButton(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.redAccent,
            onTap: () => _confirmDelete(context, ref),
          ),
        ),

      ],
    ),
  );
}


// Helper Widget for the Ear Buttons
class _EarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _EarButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black26, // Semi-transparent background for visibility
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}


// ── Empty State ───────────────────────────────────────────────────────────────

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

// ── FAB ───────────────────────────────────────────────────────────────────────

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
