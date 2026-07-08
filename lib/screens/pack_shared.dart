import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
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

// ── Ownership provider ──────────────────────────────────────────────────────

/// Resolves whether the local folder [folderId] is an owned pack (created
/// on this device, or never shared at all) vs. a downloaded, non-owned
/// pack. Wraps SupabaseService.lookupPackForFolder, which does a local
/// Drift lookup (fast, no network call) — null result means "never shared
/// or downloaded", which counts as owned.
final packOwnershipProvider =
    FutureProvider.family<OwnedPackLookup?, int>((ref, folderId) async {
  return SupabaseService.instance.lookupPackForFolder(folderId);
});

/// True if [lookup] represents an owned pack. Treats "never shared" (null)
/// as owned.
bool isOwnedLookup(OwnedPackLookup? lookup) =>
    lookup == null || lookup.isOwner;

// ── Training FAB (used on both HomeScreen and PackScreen) ───────────────────

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
              backgroundColor: const Color(0xFF249689), // EnolaTheme.secondary
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
