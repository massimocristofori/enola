import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/supabase_service.dart';
import 'package:enola/screens/training_dashboard_screen.dart';

const double kCardAspectRatio = 0.84;

int crossAxisCount(double width) => width >= 500 ? 3 : 2;

double cardWidth(BuildContext context) {
  final w = math.min(MediaQuery.of(context).size.width, 600.0);
  final cols = crossAxisCount(w);
  return (w - 80 - (cols - 1) * 24) / cols;
}

int rankIndex(double starRatio) {
  final score = (starRatio * 10).round();
  if (score == 0) return 0;
  if (score < 5) return 1;
  if (score <= 6) return 2;
  if (score <= 9) return 3;
  return 4;
}


// ── Pack color helpers ───────────────────────────────────────────────────

List<Color> packGradientColors(bool isOwned) => isOwned
    ? const [Color(0xa1ee8b60), Color(0xffff4c00)]
    : const [Color(0x4e249689), Color(0xFF249689)];

Color packAccentColor(bool isOwned) =>
    isOwned ? const Color(0xffff4c00) : const Color(0x4e249689);

// ── Ownership provider ──────────────────────────────────────────────────

final packOwnershipProvider =
    FutureProvider.family<OwnedPackLookup?, int>((ref, folderId) async {
  return SupabaseService.instance.lookupPackForFolder(folderId);
});

bool isOwnedLookup(OwnedPackLookup? lookup) =>
    lookup == null || lookup.isOwner;

// ── Shared pack card visual (rank grid + title bar) ──────────────────────

class PackCardBody extends ConsumerWidget {
  final Folder pack;
  final bool isOwned;
  final bool hideTitle;
	final bool flatTitle;
  const PackCardBody({
    super.key,
    required this.pack,
    required this.isOwned,
    this.hideTitle = false,
		this.flatTitle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(pack.id));
    final maps = mapsAsync.valueOrNull ?? [];

    final gradientColors = packGradientColors(isOwned);
    final accentColor = packAccentColor(isOwned);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(8),
        border: isOwned ? null : Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(70),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PackRankGrid(maps: maps),
          const SizedBox(height: 4),
          PackInfoBar(title: pack.title, hideTitle: hideTitle, flat: flatTitle),
        ],
      ),
    );
  }
}

class PackRankGrid extends ConsumerWidget {
  final List<RiddleMap> maps;
  const PackRankGrid({super.key, required this.maps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (maps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Icon(
            Icons.folder_open_rounded,
            size: 48,
            color: Color(0x8Cffffff),
          ),
        ),
      );
    }

    final rankCounts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0, 4: 0};

    for (final map in maps) {
      final countAsync = ref.watch(riddleCountProvider(map.id));
      final sessionAsync = ref.watch(latestSessionProvider(map.id));

      final count = countAsync.valueOrNull ?? 0;
      final session = sessionAsync.valueOrNull;

      int achievedStars = 0;
      if (session != null && session.riddleStarsJson != null) {
        try {
          final list = jsonDecode(session.riddleStarsJson!) as List;
          achievedStars = list.fold<int>(0, (sum, e) => sum + (e as int));
        } catch (_) {}
      }

      final maxStars = count * 3;
      final starRatio = maxStars > 0 ? achievedStars / maxStars : 0.0;
      final rank = rankIndex(starRatio);
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const cols = 3;
          const spacing = 8.0;
          final tileSize =
              (constraints.maxWidth - spacing * (cols - 1)) / cols;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int rank = 4; rank >= 0; rank--)
                RankTile(
                  rank: rank,
                  count: rankCounts[rank] ?? 0,
                  size: tileSize,
                ),
            ],
          );
        },
      ),
    );
  }
}

class RankTile extends StatelessWidget {
  final int rank;
  final int count;
  final double size;

  const RankTile({
    super.key,
    required this.rank,
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0;

    return Opacity(
      opacity: isEmpty ? 0.4 : 1.0,
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/images/$rank.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x8714181b),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackInfoBar extends StatelessWidget {
  final String title;
  final bool hideTitle;
  final bool flat;
  const PackInfoBar({
    super.key,
    required this.title,
    this.hideTitle = false,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Opacity(
      opacity: hideTitle ? 0 : 1,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    if (flat) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: text,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x44ffffff),
          borderRadius: BorderRadius.circular(6),
        ),
        child: text,
      ),
    );
  }
}


// ── Training FAB ──────────────────────────────────────────────────────────

class TrainingFab extends StatefulWidget {
  const TrainingFab({super.key});

  @override
  State<TrainingFab> createState() => _TrainingFabState();
}

class _TrainingFabState extends State<TrainingFab> {
  late Stream<List<TrainingRiddleItem>> _riddlesStream;

  @override
  void initState() {
    super.initState();
    _riddlesStream = DriftService.instance.watchAllTrainingRiddles();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrainingRiddleItem>>(
      stream: _riddlesStream,
      builder: (context, snapshot) {
        return StreamBuilder<List<TrainingSession>>(
          stream: DriftService.instance.watchActiveTrainingSessions(),
          builder: (context, sessionSnap) {
            final hasActiveSessions = (sessionSnap.data ?? []).isNotEmpty;
            final totalCount = snapshot.data?.length ?? 0;

            if (!hasActiveSessions) return const SizedBox.shrink();

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 62,
                    child: Material(
                      color: EnolaTheme.secondary,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrainingDashboardScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.school_rounded,
                                  size: 20, color: Colors.white),
                              SizedBox(height: 2),
                              Text(
                                'Training',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (totalCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: EnolaTheme.secondary, width: 1.5),
                      ),
                      child: Text(
                        '$totalCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: EnolaTheme.secondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ).animate().fadeIn().slideY(begin: 0.3, end: 0);
          },
        );
      },
    );
  }
}

