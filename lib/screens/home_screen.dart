// ── home_screen.dart ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/play_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assuming a provider that fetches a list of maps available to the user
    final mapsAsync = ref.watch(allMapsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          'My Maps',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: EnolaTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SafeArea(
        child: mapsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: EnolaTheme.accent),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading maps: $err', style: const TextStyle(color: Colors.red)),
          ),
          data: (maps) {
            if (maps.isEmpty) {
              return const Center(child: Text('No maps available.'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final map = maps[index];
                
                // Fetch stats for the map (adjust according to your provider logic)
                final sessionAsync = ref.watch(latestSessionProvider(map.id));
                final session = sessionAsync.valueOrNull;
                
                final int maxStars = map.riddleCount * 3;
                final int achievedStars = session?.totalStars ?? 0;
                final bool hasBeenPlayed = session != null && session.lastCompletedIndex >= 0;
                final bool isComplete = session?.completedAt != null;
                final double starRatio = maxStars > 0 ? achievedStars / maxStars : 0.0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayScreen(mapId: map.id),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'map-card-${map.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: _CardShell(
                        imageBytes: map.imageBytes,
                        isComplete: isComplete,
                        starRatio: starRatio,
                        infoBar: _CardInfoBar(
                          title: map.title,
                          achievedStars: achievedStars,
                          maxStars: maxStars,
                          hasBeenPlayed: hasBeenPlayed,
                          isComplete: isComplete,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Card Shell ───────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final dynamic imageBytes;
  final bool isComplete;
  final double starRatio;
  final Widget infoBar;

  const _CardShell({
    this.imageBytes,
    required this.isComplete,
    required this.starRatio,
    required this.infoBar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: imageBytes != null
                      // Adjust to match how your imageBytes are handled
                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                      : Container(color: const Color(0xFFE5E7EB)),
                ),
                if (isComplete)
                  _RankRibbonOverlay(starRatio: starRatio),
              ],
            ),
          ),
          infoBar,
        ],
      ),
    );
  }
}

// ── Floating Ribbon Overlay ───────────────────────────────────────────────────

class _RankRibbonOverlay extends StatelessWidget {
  final double starRatio;
  const _RankRibbonOverlay({required this.starRatio});

  String _rankEmoji(double ratio) {
    if (ratio == 1.0) return '🏆';
    if (ratio >= 0.8) return '🥇';
    if (ratio >= 0.5) return '🥈';
    if (ratio > 0.0) return '🥉';
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          border: Border(
            top: BorderSide(color: const Color(0xFFE5E7EB).withValues(alpha: 0.6), width: 1),
            bottom: BorderSide(color: const Color(0xFFE5E7EB).withValues(alpha: 0.6), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          _rankEmoji(starRatio),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 42), // Increased size
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── The Flush Title Rectangle ──
          Container(
            height: 38, // Explicit height for perfect Hero matching
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: EnolaTheme.textPrimary,
                height: 1.3,
                letterSpacing: 0.1,
              ),
            ),
          ),
          // ── The Progress Bar Row ──
          SizedBox(
            height: 50, // Explicit height for perfect Hero matching
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '$achievedStars',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StarProgressBar(
                      progress: maxStars > 0 && hasBeenPlayed
                          ? achievedStars / maxStars
                          : 0.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$maxStars',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Progress Bar ───────────────────────────────────────────────────────

class _StarProgressBar extends StatelessWidget {
  final double progress;
  final Key? starKey;

  const _StarProgressBar({required this.progress, this.starKey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double starSize = 26.0;
        const double barHeight = 8.0;
        
        final double leftOffset = width * progress.clamp(0.0, 1.0);

        return SizedBox(
          height: starSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // Background track
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Fill track
              if (progress > 0)
                Container(
                  height: barHeight,
                  width: leftOffset,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              // Thumb precisely center-anchored and shifted 2px up
              Positioned(
                left: leftOffset,
                child: Container(
                  transform: Matrix4.translationValues(-starSize / 2, -2.0, 0),
                  child: Icon(
                    key: starKey,
                    Icons.star_rounded,
                    size: starSize,
                    color: const Color(0xFFF1C40F),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
