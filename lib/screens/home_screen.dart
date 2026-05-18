import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';
import 'package:enola/services/drift_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(allMapsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
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
                'Enola - My Maps',
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Map'),
        content: const Text(
            'Are you sure you want to delete this map? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteMap(context, ref);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMap(BuildContext context, WidgetRef ref) async {
    try {
      final db = DriftService.instance.db;
      await (db.delete(db.riddleMaps)..where((t) => t.id.equals(map.id))).go();
      ref.invalidate(allMapsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete map: $e'),
            backgroundColor: EnolaTheme.wrong,
          ),
        );
      }
    }
  }

  void _openPlay(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => PlayScreen(mapId: map.id),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? imageBytes =
        map.imageBytes != null ? Uint8List.fromList(map.imageBytes!) : null;

    final countAsync = ref.watch(riddleCountProvider(map.id));
    final sessionAsync = ref.watch(latestSessionProvider(map.id));

    final count = countAsync.valueOrNull ?? 0;
    final maxStars = count * 3;
    final session = sessionAsync.valueOrNull;

    int achievedStars = 0;
    if (session != null && session.riddleStarsJson != null) {
      try {
        final list = jsonDecode(session.riddleStarsJson!) as List;
        achievedStars = list.fold<int>(0, (sum, e) => sum + (e as int));
      } catch (_) {}
    }

    final hasBeenPlayed = session != null;
    final isComplete =
        hasBeenPlayed && maxStars > 0 && achievedStars >= maxStars;

    return GestureDetector(
      onTap: () => _openPlay(context),
      child: Hero(
        tag: 'map-card-${map.id}',
        flightShuttleBuilder: (_, animation, __, ___, ____) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Material(
                type: MaterialType.transparency,
                child: _CardShell(
                  imageBytes: imageBytes,
                  isComplete: isComplete,
                  title: map.title,
                  achievedStars: achievedStars,
                  maxStars: maxStars,
                  hasBeenPlayed: hasBeenPlayed,
                ),
              );
            },
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _CardShell(
              imageBytes: imageBytes,
              isComplete: isComplete,
              title: map.title,
              achievedStars: achievedStars,
              maxStars: maxStars,
              hasBeenPlayed: hasBeenPlayed,
            ),

            // ── Top-left ear (Edit) ──
            Positioned(
              top: -6,
              left: -6,
              child: _EarButton(
                icon: Icons.edit_rounded,
                iconColor: EnolaTheme.textSecond.withValues(alpha: 0.5),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateMapScreen(existingMapId: map.id),
                  ),
                ),
              ),
            ),

            // ── Top-right ear (Delete) ──
            Positioned(
              top: -6,
              right: -6,
              child: _EarButton(
                icon: Icons.delete_forever_rounded,
                iconColor: Colors.redAccent.withValues(alpha: 0.5),
                onTap: () => _confirmDelete(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rank helpers (mirrors ResultScreen thresholds exactly) ────────────────────

String _rankEmoji(double starRatio) {
  if (starRatio >= 0.9) return '👑';
  if (starRatio >= 0.7) return '🏆';
  if (starRatio >= 0.5) return '⚔️';
  return '📜';
}

String _rankName(double starRatio) {
  if (starRatio >= 0.9) return 'Grand Sage';
  if (starRatio >= 0.7) return 'Scholar';
  if (starRatio >= 0.5) return 'Apprentice';
  return 'Novice';
}

// ── Rank Overlay ──────────────────────────────────────────────────────────────

class _RankOverlay extends StatelessWidget {
  final double starRatio;
  const _RankOverlay({required this.starRatio});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _rankEmoji(starRatio),
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _rankName(starRatio),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Card Shell ────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool isComplete;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;

  const _CardShell({
    required this.imageBytes,
    required this.isComplete,
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
  });

  @override
  Widget build(BuildContext context) {
    final double starRatio = maxStars > 0 ? achievedStars / maxStars : 0;

    return Container(
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
                        imageBytes!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFffffff), Color(0xFFf3f6f4)],
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

            // ── Rank overlay — centered in the image area above the info bar ──
            if (isComplete)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 70, // leaves room for the info bar
                child: Center(
                  child: _RankOverlay(starRatio: starRatio),
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
                child: _CardInfoBar(
                  title: title,
                  achievedStars: achievedStars,
                  maxStars: maxStars,
                  hasBeenPlayed: hasBeenPlayed,
                  isComplete: isComplete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Info Bar ─────────────────────────────────────────────────────────────

class _CardInfoBar extends StatelessWidget {
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardInfoBar({
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 17, color: Color(0xFFf59e0b)),
                  const SizedBox(width: 4),
                  Text(
                    hasBeenPlayed ? '$achievedStars / $maxStars' : '$maxStars',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // ── Progress bar — crown icon REMOVED ──
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxStars > 0 && hasBeenPlayed
                      ? achievedStars / maxStars
                      : 0,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFf59e0b)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ear Button ────────────────────────────────────────────────────────────────

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
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: iconColor),
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
