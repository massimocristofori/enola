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

String rankImage(double starRatio) {
  final score = (starRatio * 10).round();
  if (score == 0) return 'assets/images/0.jpg';
  if (score < 5) return 'assets/images/1.jpg';
  if (score <= 6) return 'assets/images/2.jpg';
  if (score <= 9) return 'assets/images/3.jpg';
  return 'assets/images/4.jpg';
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
  const PackCardBody({
    super.key,
    required this.pack,
    required this.isOwned,
    this.hideTitle = false,
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
          PackInfoBar(title: pack.title, hideTitle: hideTitle),
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
  const PackInfoBar({super.key, required this.title, this.hideTitle = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x44ffffff),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Opacity(
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
        ),
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

            return FloatingActionButton.extended(
              heroTag: 'training_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingDashboardScreen(),
                ),
              ),
              backgroundColor: const Color(0xFF249689),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.school_rounded),
              label: Row(
                children: [
                  const Text(
                    'Training',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0);
          },
        );
      },
    );
  }
}
