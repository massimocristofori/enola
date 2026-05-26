import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                'Ready for a Riddle?',
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
    if (width >= 500) return 3;
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
    int completedRiddlesCount = 0;

    if (session != null && session.riddleStarsJson != null) {
      try {
        final list = jsonDecode(session.riddleStarsJson!) as List;
        completedRiddlesCount = list.length;
        achievedStars = list.fold<int>(0, (sum, e) => sum + (e as int));
      } catch (_) {}
    }

    final hasBeenPlayed = session != null;
    final isComplete =
        hasBeenPlayed && count > 0 && completedRiddlesCount >= count;

    return GestureDetector(
      onTap: () => _openPlay(context),
      child: Hero(
        tag: 'map-card-${map.id}',
        flightShuttleBuilder: (_, animation, __, ___, ____) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final imageHeightFactor =
                  (1.0 - animation.value).clamp(0.0, 1.0);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: imageHeightFactor,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageBytes != null
                                      ? Image.memory(imageBytes,
                                          fit: BoxFit.cover)
                                      : Image.asset('assets/images/0.jpeg',
                                          fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(16)),
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
                                    const Icon(Icons.star_rounded,
                                        size: 17,
                                        color: Color(0xFFf59e0b)),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasBeenPlayed
                                          ? '$achievedStars / $maxStars'
                                          : '$maxStars',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: maxStars > 0 && hasBeenPlayed
                                        ? achievedStars / maxStars
                                        : 0,
                                    minHeight: 5,
                                    backgroundColor:
                                        const Color(0xFFE5E7EB),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFf59e0b)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

// ── Rank helpers ──────────────────────────────────────────────────────────────

String _rankEmoji(double starRatio) {
  if (starRatio >= 0.9) return '👑';
  if (starRatio >= 0.7) return '🏆';
  if (starRatio >= 0.5) return '⚔';
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
    // Standardizing to Stack alignment center and clipping bounds
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: SunburstPainter(
              rayCount: 16, 
              alphas: [0.36, 0.70, 0.20, 0.52], 
            ),
          ),
        ),
        Text(
          _rankEmoji(starRatio), 
          style: const TextStyle(
            fontSize: 64, 
          ),
        ),
        // Preserved structurally to avoid breaking your signature layout parameters
        Visibility(
          visible: false,
          maintainState: true,
          child: Text(_rankName(starRatio)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10), // Ensures the rays get sliced at the image edges!
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageBytes != null
                        ? Image.memory(imageBytes!, fit: BoxFit.cover)
                        : Image.asset('assets/images/0.jpeg', fit: BoxFit.cover),
                    if (isComplete)
                      Positioned.fill(
                        child: _RankOverlay(starRatio: starRatio),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _CardInfoBar(
            title: title,
            achievedStars: achievedStars,
            maxStars: maxStars,
            hasBeenPlayed: hasBeenPlayed,
            isComplete: isComplete,
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
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
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 17, color: Color(0xFFf59e0b)),
              const SizedBox(width: 4),
              Text(
                '$achievedStars / $maxStars',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maxStars > 0 && hasBeenPlayed
                  ? achievedStars / maxStars
                  : 0,
              minHeight: 5,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFf59e0b)),
            ),
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

// ── Custom Painter ────────────────────────────────────────────────────────────

class SunburstPainter extends CustomPainter {
  final int rayCount;
  final List<double> alphas;

  SunburstPainter({this.rayCount = 16, required this.alphas});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.sqrt(size.width * size.width + size.height * size.height);
    
    final angleStep = (2 * math.pi) / rayCount;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rayCount; i++) {
      final alpha = alphas[i % alphas.length];
      paint.color = Colors.white.withValues(alpha: alpha);

      final startAngle = i * angleStep;
      final endAngle = startAngle + (angleStep * 0.68); 

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        )
        ..lineTo(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SunburstPainter oldDelegate) {
    return oldDelegate.rayCount != rayCount || oldDelegate.alphas != alphas;
  }
}
