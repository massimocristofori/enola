import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift_orm;

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/supabase_service.dart';
import 'package:enola/services/training_service.dart';
import 'package:enola/screens/share_pack_screen.dart';
import 'package:enola/screens/pack_shared.dart';
import 'package:enola/utils/rank_image.dart';

const double kLipHeightExpanded = 34.0; //46
const double kLipHeightCollapsed = 34.0;
const double kLipCollapseScrollThreshold = 34.0; //40

class PackScreen extends ConsumerStatefulWidget {
  final int packId;
  final String packName;
  final Animation<double>? flightAnimation;

  const PackScreen({
    super.key,
    required this.packId,
    required this.packName,
    this.flightAnimation,
  });

  @override
  ConsumerState<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends ConsumerState<PackScreen> {
  final ScrollController _scrollController = ScrollController();
  //double _collapseT = 0.0;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    //_scrollController.addListener(_onScroll);
    final anim = widget.flightAnimation;
    if (anim == null) {
      _showContent = true;
    } else {
      _showContent = anim.isCompleted;
      anim.addStatusListener(_onFlightStatus);
    }
  }

  void _onFlightStatus(AnimationStatus status) {
    if (!mounted) return;
    setState(() => _showContent = status == AnimationStatus.completed);
  }

  @override
  void dispose() {
    widget.flightAnimation?.removeStatusListener(_onFlightStatus);
    //_scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final t = (_scrollController.offset / kLipCollapseScrollThreshold)
        .clamp(0.0, 1.0);
    if (t != _collapseT) {
      setState(() => _collapseT = t);
    }
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMapScreen(initialFolderId: widget.packId),
      ),
    );
  }

  void _sharePack(BuildContext context, Folder pack) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SharePackScreen(folder: pack)),
    );
  }

  Future<void> _handleDeleteTap(BuildContext context) async {
    final lookup =
        await SupabaseService.instance.lookupPackForFolder(widget.packId);

    if (lookup == null) {
      await _confirmPlainDelete(context);
      return;
    }

    if (lookup.isOwner) {
      await _confirmOwnerDelete(context, lookup.packId);
    } else {
      await _confirmNonOwnerDelete(context, lookup.packId);
    }
  }

  Future<void> _confirmPlainDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pack?'),
        content: Text(
          'This will permanently delete "${widget.packName}" and all maps inside it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DriftService.instance.deleteFolderAndContents(widget.packId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmOwnerDelete(
      BuildContext context, String remotePackId) async {
    final choice = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete shared pack?'),
        content: Text(
          'This will permanently delete "${widget.packName}" and all maps inside it. '
          'This pack is shared — do you also want to remove it from '
          'Supabase? Anyone who downloaded it will keep their copy, but '
          'won\'t be able to receive future updates and the share code '
          'will stop working.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep in Supabase'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete everywhere'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == true) {
      await SupabaseService.instance.deletePackRemote(remotePackId);
    }
    await DriftService.instance.deleteFolderAndContents(widget.packId);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmNonOwnerDelete(
      BuildContext context, String remotePackId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pack?'),
        content: Text(
          'This will delete "${widget.packName}" and all maps inside it from this '
          'device only. The shared pack itself is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DriftService.instance.deleteFolderAndContents(widget.packId);
      await DriftService.instance.removePackTracking(remotePackId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapsAsync = ref.watch(mapsInFolderProvider(widget.packId));
    final width = MediaQuery.of(context).size.width;
    final cols = crossAxisCount(width);
    final maps = mapsAsync.valueOrNull ?? [];
    final topInset = MediaQuery.of(context).padding.top;

    final packsAsync = ref.watch(allFoldersProvider);
    final matches =
        packsAsync.valueOrNull?.where((f) => f.id == widget.packId) ?? [];
    final pack = matches.isNotEmpty ? matches.first : null;

    // Same ownership lookup the header and the home-screen card use, so
    // the page background starts on the exact color the Hero is
    // flying from/to.
    final ownershipAsync = ref.watch(packOwnershipProvider(widget.packId));
    final bool isOwned = isOwnedLookup(ownershipAsync.valueOrNull);
    final gradientColors = packGradientColors(isOwned);

    final lipHeight = kLipHeightExpanded -
        (kLipHeightExpanded - kLipHeightCollapsed) * _collapseT;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
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
          body: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_showContent,
                  child: AnimatedOpacity(
                    opacity: _showContent ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: SafeArea(
                      top: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: mapsAsync.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(
                                        color: EnolaTheme.accent),
                                  ),
                                )
                              : CustomScrollView(
                                  controller: _scrollController,
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                          height: topInset + lipHeight + 10),
                                    ),
                                    if (maps.isEmpty)
                                      SliverToBoxAdapter(
                                        child: _EmptyPackState(
                                            onCreate: () =>
                                                _openCreate(context)),
                                      )
                                    else
                                      SliverPadding(
                                        padding: const EdgeInsets.fromLTRB(
                                            40, 4, 40, 100),
                                        sliver: SliverToBoxAdapter(
                                          child: _ReorderableMapGrid(
                                            maps: maps,
                                            crossAxisCount: cols,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _PackHeader(
                      packId: widget.packId,
                      packName: widget.packName,
                      topInset: topInset,
                      lipHeight: lipHeight,
                      chromeVisible: _showContent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: IgnorePointer(
  ignoring: !_showContent,
  child: AnimatedOpacity(
    opacity: _showContent ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FabBar(
          children: [
            _FabBarItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _FabBarItem(
              icon: Icons.add_rounded,
              label: 'New Map',
              background: EnolaTheme.accent,
              onTap: () => _openCreate(context),
            ),
            _FabBarItem(
              icon: Icons.ios_share,
              label: 'Share',
              onTap: pack == null ? null : () => _sharePack(context, pack),
            ),
            _FabBarItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              background: Colors.red,
              onTap: () => _handleDeleteTap(context),
            ),
          ],
        ),
        const SizedBox(width: 12),
        const TrainingFab(),
      ],
    ),
  ),
),

        ),
      ),
    );
  }
}

// ── Pack lip header ────────────────────────────────────────────────────

class _PackHeader extends ConsumerStatefulWidget {
  final int packId;
  final String packName;
  final double topInset;
  final double lipHeight;
  final bool chromeVisible;

  const _PackHeader({
    required this.packId,
    required this.packName,
    required this.topInset,
    required this.lipHeight,
    required this.chromeVisible,
  });

  @override
  ConsumerState<_PackHeader> createState() => _PackHeaderState();
}

@override
Widget build(BuildContext context) {
  final packsAsync = ref.watch(allFoldersProvider);
  final matches =
      packsAsync.valueOrNull?.where((f) => f.id == widget.packId) ?? [];
  final pack = matches.isNotEmpty ? matches.first : null;
  final currentTitle = pack?.title ?? widget.packName;

  final ownershipAsync = ref.watch(packOwnershipProvider(widget.packId));
  final bool isOwned = isOwnedLookup(ownershipAsync.valueOrNull);
  final gradientColors = packGradientColors(isOwned);

  // Slightly lighter than the card's own top color, not as light as the
  // home-screen card's lightest tone — keeps the seam subtle without
  // fighting the Hero flight.
  final Color statusBarTopColor =
      Color.lerp(gradientColors.first, Colors.white, 0.18)!;

  return SizedBox(
    height: widget.topInset + widget.lipHeight,
    child: Column(
      children: [
        // Gradient strip behind the status bar. Its bottom edge matches
        // PackCardBody's own top color exactly, so the two blend with
        // no visible seam.
        Container(
          height: widget.topInset,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [statusBarTopColor, gradientColors.first],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Hero(
                    tag: 'pack-${widget.packId}',
                    child: SizedBox(
                      width: double.infinity,
                      child: pack == null
                          ? Material(
                              type: MaterialType.transparency,
                              child: Container(color: gradientColors.first),
                            )
                          : Material(
                              type: MaterialType.transparency,
                              child: PackCardBody(
                                pack: pack,
                                isOwned: isOwned,
                                flatTitle: true,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildNormalRow(BuildContext context, String currentTitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            currentTitle,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _startEditingTitle(currentTitle),
          icon: const Icon(Icons.edit_rounded, size: 18),
          color: Colors.white,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEditingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            autofocus: true,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _commitTitle(),
          ),
        ),
        IconButton(
          onPressed: _commitTitle,
          icon: const Icon(Icons.check_rounded, size: 20),
          color: Colors.white,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}



// ── Empty Pack State ─────────────────────────────────────────────────────

class _EmptyPackState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyPackState({required this.onCreate});

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
              'No maps in this pack',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a map to get started.',
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

// ── Reorderable Map Grid ──────────────────────────────────────────────────

class _ReorderableMapGrid extends StatefulWidget {
  final List<RiddleMap> maps;
  final int crossAxisCount;

  const _ReorderableMapGrid({
    required this.maps,
    required this.crossAxisCount,
  });

  @override
  State<_ReorderableMapGrid> createState() => _ReorderableMapGridState();
}

class _ReorderableMapGridState extends State<_ReorderableMapGrid> {
  late List<RiddleMap> _order;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.maps);
  }

  @override
  void didUpdateWidget(_ReorderableMapGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingIndex == null) {
      final incomingIds = widget.maps.map((m) => m.id).toList();
      final currentIds = _order.map((m) => m.id).toList();
      if (!_listEquals(incomingIds, currentIds)) {
        _order = List.of(widget.maps);
      }
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onHoverAt(int targetIndex) {
    if (_draggingIndex == null || _draggingIndex == targetIndex) return;
    setState(() {
      final item = _order.removeAt(_draggingIndex!);
      _order.insert(targetIndex, item);
      _draggingIndex = targetIndex;
    });
  }

  Future<void> _commitOrder() async {
    await DriftService.instance.reorderMaps(_order);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 14,
      children: [
        for (int i = 0; i < _order.length; i++)
          SizedBox(
            width: cardWidth(context),
            child: DragTarget<String>(
              onWillAcceptWithDetails: (details) {
                _onHoverAt(i);
                return true;
              },
              builder: (context, candidateData, rejectedData) {
                return _MapCard(
                  key: ValueKey(_order[i].id),
                  map: _order[i],
                  onDragStarted: () => setState(() => _draggingIndex = i),
                  onDragEnd: () {
                    setState(() => _draggingIndex = null);
                    _commitOrder();
                  },
                )
                    .animate(delay: (i * 60).ms)
                    .fadeIn(duration: 350.ms)
                    .scale(begin: const Offset(0.95, 0.95));
              },
            ),
          ),
      ],
    );
  }
}

// ── Map Card ───────────────────────────────────────────────────────────

class _MapCard extends ConsumerWidget {
  final RiddleMap map;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const _MapCard({
    super.key,
    required this.map,
    this.onDragStarted,
    this.onDragEnd,
  });

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
    final isActive =
        await TrainingService.instance.isTrainingActive(map.id);
    if (isActive) {
      await TrainingService.instance.stopTraining(map.id);
      return;
    }
    final riddles = await (DriftService.instance.db
            .select(DriftService.instance.db.riddles)
          ..where((t) => t.mapId.equals(map.id)))
        .get();
    if (riddles.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Add riddles to this map before training.'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        achievedStars =
            list.fold<int>(0, (sum, e) => sum + (e as int));
      } catch (_) {}
    }

    final hasBeenPlayed = session != null;
    final isComplete =
        hasBeenPlayed && count > 0 && completedRiddlesCount >= count;
    final double starRatio =
        maxStars > 0 ? achievedStars / maxStars : 0;

    final String coverAsset = rankImageForRatio(starRatio);

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
      const double infoBarHeight = 38;

      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final imageHeight =
              ((fromHeight - infoBarHeight) * (1.0 - t))
                  .clamp(0.0, double.infinity);

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
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 4),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10)),
                                  child: Image.asset(coverAsset,
                                      fit: BoxFit.cover,
                                      width: double.infinity),
                                ),
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

    final cardShell = _CardShell(
      coverAsset: coverAsset,
      title: map.title,
      achievedStars: achievedStars,
      maxStars: maxStars,
      hasBeenPlayed: hasBeenPlayed,
      isComplete: isComplete,
    );

    return Hero(
      tag: 'map-card-${map.id}',
      flightShuttleBuilder: flightShuttle,
      child: StreamBuilder<TrainingSession?>(
        stream: (DriftService.instance.db
                .select(DriftService.instance.db.trainingSessions)
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

          final cardW = cardWidth(context);
          final cardH = cardW / kCardAspectRatio;

          return LongPressDraggable<String>(
            data: map.id,
            delay: const Duration(milliseconds: 350),
            onDragStarted: onDragStarted,
            onDragEnd: (_) => onDragEnd?.call(),
            feedback: SizedBox(
              width: cardW,
              height: cardH,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(90),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: _CardShellDragging(
                    coverAsset: coverAsset,
                    title: map.title,
                    achievedStars: achievedStars,
                    maxStars: maxStars,
                    hasBeenPlayed: hasBeenPlayed,
                    isComplete: isComplete,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: cardShell,
            ),
            child: GestureDetector(
              onTap: () => _openPlay(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  cardShell,
                  Positioned(
                    top: -8,
                    right: -8,
                    child: _EarButton(
                      icon: isTrainingOn
                          ? Icons.school_rounded
                          : Icons.school_outlined,
                      iconColor: isTrainingOn
                          ? Colors.white
                          : EnolaTheme.textSecond
                              .withValues(alpha: 0.95),
                      backgroundColor: isTrainingOn
                          ? EnolaTheme.secondary
                          : Colors.white,
                      onTap: () => _toggleTraining(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Card Shell ─────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final String coverAsset;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardShell({
    required this.coverAsset,
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
        border: isComplete
            ? Border.all(color: const Color(0xFFEE8B60), width: 2)
            : null,
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
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Opacity(
                  opacity: hasBeenPlayed ? 1.0 : 0.45,
                  child: Image.asset(coverAsset, fit: BoxFit.cover),
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

class _CardShellDragging extends StatelessWidget {
  final String coverAsset;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardShellDragging({
    required this.coverAsset,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(coverAsset, fit: BoxFit.cover),
                    Container(color: Colors.black.withAlpha(55)),
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

// ── Card Info Bar ────────────────────────────────────────────────────────

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
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(
                vertical: 3, horizontal: 12),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: EnolaTheme.textPrimary,
                height: 1.3,
                letterSpacing: 0.1,
              ),
            ),
          ),
          SizedBox(
            height: 26,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
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

// ── Star Progress Bar ────────────────────────────────────────────────────

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
        final double leftOffset =
            width * progress.clamp(0.0, 1.0);

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

// ── Ear Button ───────────────────────────────────────────────────────────

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

// ── FAB bar ──────────────────────────────────────────────────────────────
//
// A single pill-shaped container holding several icon-only FAB actions,
// iOS-dock style, replacing what used to be separate floating circles.

class _FabBar extends StatelessWidget {
  final List<Widget> children;
  const _FabBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _FabBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? background; // null = plain white/black item
  final Color? foreground;

  const _FabBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final bool special = background != null;

    final fg = foreground ??
        (special ? Colors.white : EnolaTheme.textPrimary);
    final resolvedFg = disabled ? fg.withValues(alpha: 0.35) : fg;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: resolvedFg),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: resolvedFg,
          ),
        ),
      ],
    );

    return SizedBox(
      width: 62,
      child: Material(
        color: special
            ? (disabled ? background!.withValues(alpha: 0.35) : background)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: content,
          ),
        ),
      ),
    );
  }
}

