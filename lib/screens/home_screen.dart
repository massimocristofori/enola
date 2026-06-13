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

const double kCardAspectRatio = 0.84;

class HomeScreen extends ConsumerWidget {
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
                  ? _RootScrollView(onCreate: () => _openCreate(context))
                  : _FolderScrollView(
                      folderId: folderId!,
                      folderName: folderName!,
                      onCreate: () => _openCreate(context),
                    ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _isRoot
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TrainingFab(),
                  const SizedBox(width: 12),
                  _CreateFab(onTap: () => _openCreate(context)),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FolderBackFab(
                    onBack: () => Navigator.pop(context),
                    onUnfile: (mapId) async {
                      await DriftService.instance
                          .setMapFolder(mapId, null);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  _CreateFab(onTap: () => _openCreate(context)),
                ],
              ),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMapScreen(initialFolderId: folderId),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _crossAxisCount(double width) => width >= 500 ? 3 : 2;

double _cardWidth(BuildContext context) {
  final w = math.min(MediaQuery.of(context).size.width, 600.0);
  final cols = _crossAxisCount(w);
  return (w - 80 - (cols - 1) * 24) / cols;
}

// ── Root scroll view ──────────────────────────────────────────────────────────

class _RootScrollView extends ConsumerStatefulWidget {
  final VoidCallback onCreate;
  const _RootScrollView({required this.onCreate});

  @override
  ConsumerState<_RootScrollView> createState() => _RootScrollViewState();
}

class _RootScrollViewState extends ConsumerState<_RootScrollView> {
  int? _hoveredFolderId;
  bool _unfiledHovered = false;

  @override
  Widget build(BuildContext context) {
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
      return _EmptyState(onCreate: widget.onCreate);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header()),

        // ── Folders section ──
        if (folders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 14,
                childAspectRatio: kCardAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final folder = folders[i];
                  final isHovered = _hoveredFolderId == folder.id;
                  return DragTarget<RiddleMap>(
                    onWillAcceptWithDetails: (details) {
                      setState(() => _hoveredFolderId = folder.id);
                      return true;
                    },
                    onLeave: (_) =>
                        setState(() => _hoveredFolderId = null),
                    onAcceptWithDetails: (details) {
                      setState(() => _hoveredFolderId = null);
                      DriftService.instance
                          .setMapFolder(details.data.id, folder.id);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isHovered
                              ? Border.all(
                                  color: EnolaTheme.accent, width: 2.5)
                              : Border.all(
                                  color: Colors.transparent, width: 2.5),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color: EnolaTheme.accent
                                        .withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: _FolderCard(folder: folder)
                            .animate(delay: (i * 60).ms)
                            .fadeIn(duration: 350.ms)
                            .scale(begin: const Offset(0.95, 0.95)),
                      );
                    },
                  );
                },
                childCount: folders.length,
              ),
            ),
          ),

        // ── Section divider — DragTarget to unfile ──
        SliverToBoxAdapter(
          child: DragTarget<RiddleMap>(
            onWillAcceptWithDetails: (details) {
              if (details.data.folderId == null) return false;
              setState(() => _unfiledHovered = true);
              return true;
            },
            onLeave: (_) => setState(() => _unfiledHovered = false),
            onAcceptWithDetails: (details) {
              setState(() => _unfiledHovered = false);
              DriftService.instance.setMapFolder(details.data.id, null);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                decoration: BoxDecoration(
                  color: _unfiledHovered
                      ? EnolaTheme.accent.withValues(alpha: 0.06)
                      : const Color(0xFFF1F4F8),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  border: _unfiledHovered
                      ? Border.all(
                          color: EnolaTheme.accent.withValues(alpha: 0.3),
                          width: 1.5)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 16, 40, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _unfiledHovered
                              ? EnolaTheme.accent.withValues(alpha: 0.4)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _unfiledHovered ? 'Drop to unfile' : 'Maps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _unfiledHovered
                              ? EnolaTheme.accent
                              : EnolaTheme.textSecond.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Divider(
                          color: _unfiledHovered
                              ? EnolaTheme.accent.withValues(alpha: 0.4)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

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
                childAspectRatio: kCardAspectRatio,
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

        if (unfiled.isEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Folder scroll view ────────────────────────────────────────────────────────

class _FolderScrollView extends ConsumerWidget {
  final int folderId;
  final String folderName;
  final VoidCallback onCreate;

  const _FolderScrollView({
    required this.folderId,
    required this.folderName,
    required this.onCreate,
  });

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
          child: _FolderHeader(
            folderName: folderName,
            folderId: folderId,
          ),
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
                childAspectRatio: kCardAspectRatio,
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
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for a Riddle?',
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: EnolaTheme.textPrimary,
                          ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap a map to explore or play',
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: EnolaTheme.textSecond,
                          ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showCreateFolderSheet(context),
            icon: const Icon(Icons.folder_outlined),
            color: EnolaTheme.textSecond,
            tooltip: 'New Folder',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0);
  }

  void _showCreateFolderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreateFolderSheet(),
    );
  }
}

// ── Create Folder Sheet ───────────────────────────────────────────────────────

class _CreateFolderSheet extends StatefulWidget {
  const _CreateFolderSheet();

  @override
  State<_CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<_CreateFolderSheet> {
  final _controller = TextEditingController();
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final canCreate = _controller.text.trim().isNotEmpty;
      if (canCreate != _canCreate)
        setState(() => _canCreate = canCreate);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await DriftService.instance.saveFolder(title);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Folder',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: EnolaTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Geography, History…',
              hintStyle: TextStyle(
                  color: EnolaTheme.textSecond.withValues(alpha: 0.5)),
              filled: true,
              fillColor: const Color(0xFFF1F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _canCreate ? _create() : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _canCreate ? _create : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: EnolaTheme.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFFAAAAAA),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Create Folder',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header (folder) ───────────────────────────────────────────────────────────

class _FolderHeader extends ConsumerWidget {
  final String folderName;
  final int folderId;

  const _FolderHeader({
    required this.folderName,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(folderStatsProvider(folderId));
    final stats = statsAsync.valueOrNull;

    return Hero(
      tag: 'folder-$folderId',
      flightShuttleBuilder: _shuttle,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
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
      ),
    );
  }

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromCtx,
    BuildContext toCtx,
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
                  Color.lerp(const Color(0xFF39d2c0), Colors.transparent, t)!,
                  Color.lerp(const Color(0xFF249689), Colors.transparent, t)!,
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
                folderName,
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

// ── Folder Card ───────────────────────────────────────────────────────────────

class _FolderCard extends ConsumerWidget {
  final Folder folder;
  const _FolderCard({required this.folder});

  void _openFolder(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => HomeScreen(
          folderId: folder.id,
          folderName: folder.title,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
          child: child,
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

    final achievedStars = stats?.achievedStars ?? 0;

    return GestureDetector(
      onTap: () => _openFolder(context),
      child: Hero(
        tag: 'folder-${folder.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF39d2c0), Color(0xFF249689)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39d2c0).withAlpha(80),
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                    child: _FolderCoverGrid(maps: maps),
                  ),
                ),
                _FolderInfoBar(
                  title: folder.title,
                  achievedStars: achievedStars,
                  userCount: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Folder Cover Grid ─────────────────────────────────────────────────────────

class _FolderCoverGrid extends StatelessWidget {
  final List<RiddleMap> maps;
  const _FolderCoverGrid({required this.maps});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 4;
    const gridCols = 2;
    final displayMaps = maps.take(maxVisible).toList();
    final overflow = maps.length - maxVisible;

    if (maps.isEmpty) {
      return Center(
        child: Icon(
          Icons.folder_open_rounded,
          size: 48,
          color: Colors.white.withAlpha(140),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCols,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: displayMaps.length,
        itemBuilder: (context, i) {
          final map = displayMaps[i];
          final isLast = i == displayMaps.length - 1 && overflow > 0;
          final imageBytes = map.imageBytes != null
              ? Uint8List.fromList(map.imageBytes!)
              : null;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white.withAlpha(40),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: isLast && overflow > 0
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageBytes != null)
                          Image.memory(imageBytes, fit: BoxFit.cover)
                        else
                          Image.asset('assets/images/0.jpeg',
                              fit: BoxFit.cover),
                        Container(color: Colors.black.withAlpha(100)),
                        Center(
                          child: Text(
                            '+$overflow',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : imageBytes != null
                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                      : Image.asset('assets/images/0.jpeg',
                          fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

// ── Folder Info Bar ───────────────────────────────────────────────────────────

class _FolderInfoBar extends StatelessWidget {
  final String title;
  final int achievedStars;
  final int userCount;

  const _FolderInfoBar({
    required this.title,
    required this.achievedStars,
    required this.userCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '$achievedStars',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.group_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '$userCount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? imageBytes = map.imageBytes != null
        ? Uint8List.fromList(map.imageBytes!)
        : null;

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
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(
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

    final cardShell = _CardShell(
      imageBytes: imageBytes,
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

          final cardW = _cardWidth(context);
          final cardH = cardW / kCardAspectRatio;

          return LongPressDraggable<RiddleMap>(
            data: map,
            delay: const Duration(milliseconds: 350),
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
                    imageBytes: imageBytes,
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
                  : Image.asset('assets/images/0.jpeg', fit: BoxFit.cover),
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

// ── Card Shell Dragging ───────────────────────────────────────────────────────

class _CardShellDragging extends StatelessWidget {
  final Uint8List? imageBytes;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool isComplete;

  const _CardShellDragging({
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageBytes != null
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : Image.asset('assets/images/0.jpeg',
                          fit: BoxFit.cover),
                  Container(color: Colors.black.withAlpha(55)),
                ],
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
            0, 0, 0, 1, 0,
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
              'Create a map or drag existing maps\ninto this folder.',
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

// ── Folder Back FAB ───────────────────────────────────────────────────────────

class _FolderBackFab extends StatefulWidget {
  final VoidCallback onBack;
  final Future<void> Function(String mapId) onUnfile;

  const _FolderBackFab({
    required this.onBack,
    required this.onUnfile,
  });

  @override
  State<_FolderBackFab> createState() => _FolderBackFabState();
}

class _FolderBackFabState extends State<_FolderBackFab> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<RiddleMap>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isDraggingOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDraggingOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDraggingOver = false);
        widget.onUnfile(details.data.id);
      },
      builder: (context, candidateData, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _isDraggingOver ? EnolaTheme.accent : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _isDraggingOver
                    ? EnolaTheme.accent.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: widget.onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isDraggingOver
                      ? Icons.folder_off_outlined
                      : Icons.chevron_left_rounded,
                  size: 22,
                  color: _isDraggingOver
                      ? Colors.white
                      : EnolaTheme.textPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  _isDraggingOver ? 'Drop to unfile' : 'My Folders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isDraggingOver
                        ? Colors.white
                        : EnolaTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
