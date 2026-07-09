import 'dart:convert';

import 'package:flutter/material.dart';
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

class PackScreen extends ConsumerWidget {
  final int packId;
  final String packName;

  const PackScreen({super.key, required this.packId, required this.packName});

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMapScreen(initialFolderId: packId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(packId));
    final width = MediaQuery.of(context).size.width;
    final cols = crossAxisCount(width);
    final maps = mapsAsync.valueOrNull ?? [];

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
              child: mapsAsync.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: EnolaTheme.accent),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _PackHeader(packName: packName, packId: packId),
                        ),
                        if (maps.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyPackState(
                                onCreate: () => _openCreate(context)),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(40, 4, 40, 100),
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
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PackBackFab(onBack: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            _CreateFab(onTap: () => _openCreate(context)),
            const SizedBox(width: 12),
            const TrainingFab(),
          ],
        ),
      ),
    );
  }
}

// ── Header (inside a pack) ────────────────────────────────────────────────

class _PackHeader extends ConsumerWidget {
  final String packName;
  final int packId;

  const _PackHeader({
    required this.packName,
    required this.packId,
  });

  Future<void> _handleDeleteTap(BuildContext context) async {
    final lookup =
        await SupabaseService.instance.lookupPackForFolder(packId);

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
          'This will permanently delete "$packName" and all maps inside it.',
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
      await DriftService.instance.deleteFolderAndContents(packId);
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
          'This will permanently delete "$packName" and all maps inside it. '
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
    await DriftService.instance.deleteFolderAndContents(packId);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmNonOwnerDelete(
      BuildContext context, String remotePackId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pack?'),
        content: Text(
          'This will delete "$packName" and all maps inside it from this '
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
      await DriftService.instance.deleteFolderAndContents(packId);
      await DriftService.instance.removePackTracking(remotePackId);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _sharePack(BuildContext context, Folder pack) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SharePackScreen(folder: pack)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(folderStatsProvider(packId));
    final stats = statsAsync.valueOrNull;
    final packsAsync = ref.watch(allFoldersProvider);
    final matches =
        packsAsync.valueOrNull?.where((f) => f.id == packId) ?? [];
    final pack = matches.isNotEmpty ? matches.first : null;

    final ownershipAsync = ref.watch(packOwnershipProvider(packId));
    final bool isOwned = isOwnedLookup(ownershipAsync.valueOrNull);

    final List<Color> gradientColors = isOwned
        ? const [Color(0xa1ee8b60), Color(0xffff4c00)]
        : const [Color(0xFF81D7FD), Color(0xFF249689)];

    return Hero(
      tag: 'pack-$packId',
      flightShuttleBuilder: (flightContext, animation, direction, fromCtx, toCtx) =>
          _shuttle(flightContext, animation, direction, fromCtx, toCtx, gradientColors),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PackHeaderLip(gradientColors: gradientColors),
            //_PackRankPeek(packId: packId),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EditablePackTitle(
                          packId: packId,
                          initialName: packName,
                        ),
                        if (stats != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${stats.mapCount} maps · '
                            '${stats.achievedStars} / ${stats.totalStars} ★',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: EnolaTheme.textSecond,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        pack == null ? null : () => _sharePack(context, pack),
                    icon: const Icon(Icons.ios_share),
                    color: EnolaTheme.textSecond,
                  ),
                  IconButton(
                    onPressed: () => _handleDeleteTap(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: EnolaTheme.textSecond,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromCtx,
    BuildContext toCtx,
    List<Color> gradientColors,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ).value;
        return Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(gradientColors[0], Colors.transparent, t)!,
                  Color.lerp(gradientColors[1], Colors.transparent, t)!,
                ],
              ),
              borderRadius: BorderRadius.circular(8 * (1.0 - t)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((25 * (1.0 - t)).round()),
                  blurRadius: 16 * (1.0 - t),
                  offset: Offset(0, 4 * (1.0 - t)),
                ),
              ],
            ),
            padding: EdgeInsets.lerp(
              const EdgeInsets.all(8),
              const EdgeInsets.fromLTRB(20, 28, 20, 16),
              t,
            ),
            child: Opacity(
              opacity: t,
              child: Text(
                packName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: EnolaTheme.textPrimary.withValues(alpha: t),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Header lip (colored echo of the card edge) ───────────────────────────

class _PackHeaderLip extends StatelessWidget {
  final List<Color> gradientColors;
  const _PackHeaderLip({required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
    );
  }
}

// ── Peeking rank tiles (faded echo of the card's rank grid) ──────────────

class _PackRankPeek extends ConsumerWidget {
  final int packId;
  const _PackRankPeek({required this.packId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(packId));
    final maps = mapsAsync.valueOrNull ?? [];
    if (maps.isEmpty) return const SizedBox.shrink();

    final ranksPresent = <int>{};
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
      ranksPresent.add(rankIndex(starRatio));
    }

    final shown = (ranksPresent.toList()..sort((a, b) => b.compareTo(a)))
        .take(4)
        .toList();

    if (shown.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          for (final rank in shown)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Opacity(
                opacity: 0.55,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/$rank.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Editable pack title ─────────────────────────────────────────────────

class _EditablePackTitle extends StatefulWidget {
  final int packId;
  final String initialName;

  const _EditablePackTitle({
    required this.packId,
    required this.initialName,
  });

  @override
  State<_EditablePackTitle> createState() => _EditablePackTitleState();
}

class _EditablePackTitleState extends State<_EditablePackTitle> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _commit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  Future<void> _commit() async {
    final newName = _controller.text.trim();
    setState(() => _isEditing = false);
    if (newName.isEmpty || newName == widget.initialName) {
      _controller.text = widget.initialName;
      return;
    }
    await DriftService.instance.updateFolderTitle(widget.packId, newName);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: EnolaTheme.textPrimary,
        );

    if (_isEditing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: style,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _commit(),
      );
    }

    return GestureDetector(
      onTap: _startEditing,
      child: Text(
        _controller.text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
                    color: EnolaTheme.accent,
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

    final String coverAsset = rankImage(starRatio);

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

// ── FABs ─────────────────────────────────────────────────────────────────

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

class _PackBackFab extends StatelessWidget {
  final VoidCallback onBack;

  const _PackBackFab({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.home_rounded,
          size: 24,
          color: EnolaTheme.textPrimary,
        ),
      ),
    );
  }
}
