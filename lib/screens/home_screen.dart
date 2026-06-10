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
import 'package:enola/screens/training_dashboard_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/training_service.dart';

import 'package:drift/drift.dart' as drift_orm;

class HomeScreen extends ConsumerWidget {
  /// When non-null, this screen shows only the maps inside this folder.
  final int? folderId;
  final String? folderName;

  const HomeScreen({
    super.key,
    this.folderId,
    this.folderName,
  });

  bool get _isRoot => folderId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECEFF4), Colors.white],
          stops: [0.0, 0.65],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _isRoot
                  ? _RootScrollView(onCreate: () => _openCreate(context, ref))
                  : _FolderScrollView(
                      folderId: folderId!,
                      folderName: folderName!,
                      onCreate: () => _openCreate(context, ref),
                    ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRoot) ...[
              const _TrainingFab(),
              const SizedBox(width: 12),
            ],
            _CreateFab(onTap: () => _openCreate(context, ref)),
          ],
        ),
      ),
    );
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMapScreen()),
    );
  }
}

// ── Root scroll view (folders + unfiled maps) ─────────────────────────────────

class _RootScrollView extends ConsumerWidget {
  final VoidCallback onCreate;
  const _RootScrollView({required this.onCreate});

  int _crossAxisCount(double width) => width >= 500 ? 3 : 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final unfiledAsync = ref.watch(unfiledMapsProvider);
    final width = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(width);

    final folders = foldersAsync.valueOrNull ?? [];
    final unfiled = unfiledAsync.valueOrNull ?? [];

    if (foldersAsync.isLoading || unfiledAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: EnolaTheme.accent),
        ),
      );
    }

    if (folders.isEmpty && unfiled.isEmpty) {
      return _EmptyState(onCreate: onCreate);
    }

    return CustomScrollView(
      slivers: [
        // ── Static header ──
        SliverToBoxAdapter(
          child: _Header(),
        ),

        // ── Folders section ──
        if (folders.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 14,
                childAspectRatio: 0.84,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _FolderCard(folder: folders[i])
                    .animate(delay: (i * 60).ms)
                    .fadeIn(duration: 350.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                childCount: folders.length,
              ),
            ),
          ),

          // ── Divider between folders and unfiled maps ──
          if (unfiled.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 4),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    const SizedBox(width: 12),
                    Text(
                      'Unfiled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EnolaTheme.textSecond.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  ],
                ),
              ),
            ),
        ],

        // ── Unfiled maps ──
        if (unfiled.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              40,
              folders.isEmpty ? 4 : 8,
              40,
              100,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 14,
                childAspectRatio: 0.84,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final offset = folders.length;
                  return _MapCard(map: unfiled[i])
                      .animate(delay: ((offset + i) * 60).ms)
                      .fadeIn(duration: 350.ms)
                      .scale(begin: const Offset(0.95, 0.95));
                },
                childCount: unfiled.length,
              ),
            ),
          ),

        // ── Bottom padding if only folders (no unfiled) ──
        if (unfiled.isEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Folder scroll view (maps inside a folder) ─────────────────────────────────

class _FolderScrollView extends ConsumerWidget {
  final int folderId;
  final String folderName;
  final VoidCallback onCreate;

  const _FolderScrollView({
    required this.folderId,
    required this.folderName,
    required this.onCreate,
  });

  int _crossAxisCount(double width) => width >= 500 ? 3 : 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(folderId));
    final width = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(width);

    final maps = mapsAsync.valueOrNull ?? [];

    if (mapsAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: EnolaTheme.accent),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _FolderHeader(folderName: folderName, folderId: folderId),
        ),
        if (maps.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyFolderState(onCreate: onCreate),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 4, 40, 100),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 14,
                childAspectRatio: 0.84,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MapCard(map: maps[i])
                    .animate(delay: (i * 60).ms)
                    .fadeIn(duration: 350.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                childCount: maps.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Header (root) ─────────────────────────────────────────────────────────────

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

// ── Header (folder) ───────────────────────────────────────────────────────────

class _FolderHeader extends ConsumerWidget {
  final String folderName;
  final int folderId;

  const _FolderHeader({required this.folderName, required this.folderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(folderStatsProvider(folderId));
    final stats = statsAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back chevron
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 32),
            color: EnolaTheme.textPrimary,
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folderName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: EnolaTheme.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (stats != null)
                  Text(
                    '${stats.mapCount} maps · ${stats.achievedStars} / ${stats.totalStars} ★',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: EnolaTheme.textSecond,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0);
  }
}

// ── Folder Card ───────────────────────────────────────────────────────────────

class _FolderCard extends ConsumerWidget {
  final Folder folder;
  const _FolderCard({required this.folder});

  void _openFolder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          folderId: folder.id,
          folderName: folder.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(folder.id));
    final statsAsync = ref.watch(folderStatsProvider(folder.id));

    final maps = mapsAsync.valueOrNull ?? [];
    final stats = statsAsync.valueOrNull;

    return GestureDetector(
      onTap: () => _openFolder(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Mini map grid cover ──
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: _FolderCoverGrid(maps: maps),
              ),
            ),
            // ── Info bar ──
            _FolderInfoBar(
              title: folder.title,
              stats: stats,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Folder Cover Grid (iPhone-style mini squares) ─────────────────────────────

class _FolderCoverGrid extends ConsumerWidget {
  final List<RiddleMap> maps;
  const _FolderCoverGrid({required this.maps});

  /// Map completion color based on latest session stars
  Color _colorForMap(RiddleMap map, int riddleCount, PlaySession? session) {
    if (riddleCount == 0 || session == null) return const Color(0xFFE5E7EB);

    int achieved = 0;
    int completedCount = 0;
    if (session.riddleStarsJson != null) {
      try {
        final list = jsonDecode(session.riddleStarsJson!) as List;
        completedCount = list.length;
        achieved = list.fold<int>(0, (sum, e) => sum + (e as int));
      } catch (_) {}
    }

    final isComplete = completedCount >= riddleCount;
    if (isComplete) {
      // Gold if complete
      final ratio = riddleCount > 0 ? achieved / (riddleCount * 3) : 0.0;
      if (ratio >= 0.9) return const Color(0xFFFFD700);
      if (ratio >= 0.5) return const Color(0xFFFFD700).withValues(alpha: 0.7);
      return const Color(0xFFFFD700).withValues(alpha: 0.5);
    }
    // Teal if in progress
    return EnolaTheme.accent.withValues(alpha: 0.65);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const maxVisible = 9;
    const gridCols = 3;
    final displayMaps = maps.take(maxVisible).toList();
    final overflow = maps.length - maxVisible;

    return Container(
      color: const Color(0xFFF1F4F8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: maps.isEmpty
            ? Center(
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 40,
                  color: EnolaTheme.textSecond.withValues(alpha: 0.3),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCols,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: displayMaps.length,
                itemBuilder: (context, i) {
                  final map = displayMaps[i];
                  final isLast = i == displayMaps.length - 1 && overflow > 0;

                  // Watch riddle count and latest session for this map
                  final countAsync = ref.watch(riddleCountProvider(map.id));
                  final sessionAsync = ref.watch(latestSessionProvider(map.id));
                  final count = countAsync.valueOrNull ?? 0;
                  final session = sessionAsync.valueOrNull;

                  final color = _colorForMap(map, count, session);

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: isLast
                        ? Container(
                            color: const Color(0xFFE5E7EB),
                            child: Center(
                              child: Text(
                                '+$overflow',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ),
                          )
                        : Container(color: color),
                  );
                },
              ),
      ),
    );
  }
}

// ── Folder Info Bar ───────────────────────────────────────────────────────────

class _FolderInfoBar extends StatelessWidget {
  final String title;
  final FolderStats? stats;

  const _FolderInfoBar({required this.title, required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row — 38px
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_rounded,
                    size: 14, color: EnolaTheme.textSecond),
                const SizedBox(width: 5),
                Flexible(
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
              ],
            ),
          ),
          // Stats row — 38px
          SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (s != null) ...[
                    Text(
                      '${s.mapCount} maps',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCCCCC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFF1C40F)),
                    const SizedBox(width: 3),
                    Text(
                      '${s.achievedStars} / ${s.totalStars}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ] else
                    const Text(
                      'Empty folder',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
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

// ── Map Card ──────────────────────────────────────────────────────────────────

class _MapCard extends ConsumerWidget {
  final RiddleMap map;
  const _MapCard({required this.map});

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

  Future<void> _toggleTraining(BuildContext context) async {
    final isActive = await TrainingService.instance.isTrainingActive(map.id);

    if (isActive) {
      await TrainingService.instance.stopTraining(map.id);
      return;
    }

    final riddles = await (DriftService.instance.db.select(
      DriftService.instance.db.riddles,
    )..where((t) => t.mapId.equals(map.id)))
        .get();

    if (riddles.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add riddles to this map before training.'),
          ),
        );
      }
      return;
    }

    await TrainingService.instance.startTraining(
      mapId: map.id,
      riddles: riddles,
      durationMinutes: 60,
    );
  }

  /// Shows a bottom sheet to move this map to a folder (or unfile it).
  Future<void> _showMoveToFolder(BuildContext context) async {
    final folders = await DriftService.instance.watchAllFolders().first;

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Move "${map.title}" to…',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: EnolaTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (folders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No folders yet. Create a folder first.',
                    style: TextStyle(color: EnolaTheme.textSecond),
                  ),
                )
              else ...[
                // Option to unfile
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined,
                      color: EnolaTheme.textSecond),
                  title: const Text('Unfiled'),
                  onTap: () async {
                    await DriftService.instance.setMapFolder(map.id, null);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                ...folders.map(
                  (f) => ListTile(
                    leading: const Icon(Icons.folder_rounded,
                        color: EnolaTheme.accent),
                    title: Text(f.title),
                    onTap: () async {
                      await DriftService.instance.setMapFolder(map.id, f.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
    final double starRatio = maxStars > 0 ? achievedStars / maxStars : 0;

    Widget flightShuttle(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection flightDirection,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
    ) {
      final RenderBox? fromBox =
          fromHeroContext.findRenderObject() as RenderBox?;
      final double fromHeight = fromBox?.size.height ?? 200.0;
      const double infoBarHeight = kPlayHeaderHeight;

      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final imageHeight =
              ((fromHeight - infoBarHeight) * (1.0 - t)).clamp(0.0, double.infinity);

          return Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: imageHeight > 0
                        ? ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              maxHeight: fromHeight - infoBarHeight,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                                child: imageBytes != null
                                    ? Image.memory(imageBytes,
                                        fit: BoxFit.cover,
                                        width: double.infinity)
                                    : Image.asset(
                                        'assets/images/0.jpeg',
                                        fit: BoxFit.cover,
                                        width: double.infinity),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: _CardInfoBar(
                      title: map.title,
                      achievedStars: achievedStars,
                      maxStars: maxStars,
                      hasBeenPlayed: hasBeenPlayed,
                      isComplete: isComplete,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _openPlay(context),
      onLongPress: () => _showMoveToFolder(context),
      child: Hero(
        tag: 'map-card-${map.id}',
        flightShuttleBuilder: flightShuttle,
        child: StreamBuilder<TrainingSession?>(
          stream: (DriftService.instance.db.select(
            DriftService.instance.db.trainingSessions,
          )
                ..where((t) => t.mapId.equals(map.id))
                ..where((t) => t.completedAt.isNull())
                ..orderBy([
                  (t) => drift_orm.OrderingTerm.desc(t.startedAt),
                ])
                ..limit(1))
              .watchSingleOrNull(),
          builder: (context, trainingSnap) {
            final rawSession = trainingSnap.data;
            final isTrainingOn = rawSession != null &&
                DateTime.now().isBefore(rawSession.endsAt);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _CardShell(
                  imageBytes: imageBytes,
                  title: map.title,
                  achievedStars: achievedStars,
                  maxStars: maxStars,
                  hasBeenPlayed: hasBeenPlayed,
                  isComplete: isComplete,
                ),

                if (isComplete)
                  Positioned(
                    left: -4,
                    right: -4,
                    top: 0,
                    bottom: 20,
                    child: _RankRibbonOverlay(starRatio: starRatio),
                  ),

                Positioned(
                  top: -8,
                  right: -8,
                  child: _EarButton(
                    icon: isTrainingOn
                        ? Icons.school_rounded
                        : Icons.school_outlined,
                    iconColor: isTrainingOn
                        ? Colors.white
                        : EnolaTheme.textSecond.withValues(alpha: 0.95),
                    backgroundColor:
                        isTrainingOn ? EnolaTheme.secondary : Colors.white,
                    onTap: () => _toggleTraining(context),
                  ),
                ),
              ],
            );
          },
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

// ── Floating Ribbon Overlay ───────────────────────────────────────────────────

class _RankRibbonOverlay extends StatelessWidget {
  final double starRatio;
  const _RankRibbonOverlay({required this.starRatio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF9CF58).withValues(alpha: 0.9),
              const Color(0xFFF6B700).withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.33, 0.33, 0.33, 0, 180,
            0.33, 0.33, 0.33, 0, 180,
            0.33, 0.33, 0.33, 0, 180,
            0,    0,    0,    1, 0,
          ]),
          child: Text(
            _rankEmoji(starRatio),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 42),
          ),
        ),
      ),
    );
  }
}

// ── Custom Progress Bar ───────────────────────────────────────────────────────

class _StarProgressBar extends StatelessWidget {
  final double progress;

  const _StarProgressBar({required this.progress});

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
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (progress > 0)
                Container(
                  height: barHeight,
                  width: leftOffset,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              Positioned(
                left: leftOffset,
                child: Container(
                  transform: Matrix4.translationValues(
                      -starSize / 2, -2.0, 0),
                  child: const Icon(
                    Icons.star_rounded,
                    size: starSize,
                    color: Color(0xFFF1C40F),
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

// ── Card Shell ────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Uint8List? imageBytes;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardShell({
    required this.imageBytes,
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Image.asset('assets/images/0.jpeg',
                      fit: BoxFit.cover),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 38,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
          SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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

// ── Ear Button ────────────────────────────────────────────────────────────────

class _EarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color backgroundColor;

  const _EarButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26, color: iconColor),
      ),
    );
  }
}

// ── Empty States ──────────────────────────────────────────────────────────────

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

class _EmptyFolderState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyFolderState({required this.onCreate});

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
              'No maps in this folder',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: EnolaTheme.accent,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a map or move existing maps\nhere with a long press.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Map'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms).scale(
            begin: const Offset(0.9, 0.9),
          ),
    );
  }
}

// ── FABs ──────────────────────────────────────────────────────────────────────

class _CreateFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'create_fab',
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

// ── Training FAB ──────────────────────────────────────────────────────────────

class _TrainingFab extends StatefulWidget {
  const _TrainingFab();

  @override
  State<_TrainingFab> createState() => _TrainingFabState();
}

class _TrainingFabState extends State<_TrainingFab> {
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
            final hasActiveSessions =
                (sessionSnap.data ?? []).isNotEmpty;

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
              backgroundColor: EnolaTheme.secondary,
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
