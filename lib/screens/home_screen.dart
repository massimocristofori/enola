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
import 'package:enola/screens/download_pack_screen.dart';
import 'package:enola/screens/share_pack_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/supabase_service.dart';
import 'package:enola/services/training_service.dart';

import 'package:drift/drift.dart' as drift_orm;

const double kCardAspectRatio = 0.84;
const double kPackCardAspectRatio = 0.68; // taller, to fit 2 rows + info bar


class HomeScreen extends ConsumerWidget {
  final int? packId;
  final String? packName;

  const HomeScreen({
    super.key,
    this.packId,
    this.packName,
  });

  bool get _isRoot => packId == null;

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
                  ? _RootScrollView(onCreateMap: () => _openCreate(context))
                  : _PackScrollView(
                      packId: packId!,
                      packName: packName!,
                      onCreate: () => _openCreate(context),
                    ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _isRoot
            ? const _TrainingFab()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PackBackFab(
                    onBack: () => Navigator.pop(context),
                    onUnfile: (mapId) async {
                      await DriftService.instance.setMapFolder(mapId, null);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  _CreateFab(onTap: () => _openCreate(context)),
                  const SizedBox(width: 12),
                  const _TrainingFab(),
                ],
              ),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMapScreen(initialFolderId: packId),
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
  final VoidCallback onCreateMap;
  const _RootScrollView({required this.onCreateMap});

  @override
  ConsumerState<_RootScrollView> createState() => _RootScrollViewState();
}

class _RootScrollViewState extends ConsumerState<_RootScrollView> {
  int? _hoveredPackId;
  bool _unfiledHovered = false;
  List<StaleMapInfo> _staleMaps = [];

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final stale = await SupabaseService.instance.checkForUpdates();
      if (stale.isNotEmpty && mounted) {
        setState(() => _staleMaps = stale);
      }
    } catch (_) {
      // Offline — silently ignore
    }
  }

  Future<void> _applyUpdates() async {
    for (final info in _staleMaps) {
      await SupabaseService.instance.applyMapUpdate(info);
    }
    if (mounted) {
      setState(() => _staleMaps = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All packs updated!')),
      );
    }
  }

  void _openCreatePack(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _CreatePackSheet(),
    );
  }

  void _openGetPack(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DownloadPackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(allFoldersProvider);
    final unfiledAsync = ref.watch(unfiledMapsProvider);
    final width = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(width);

    final packs = packsAsync.valueOrNull ?? [];
    final unfiled = unfiledAsync.valueOrNull ?? [];

    if (packsAsync.isLoading || unfiledAsync.isLoading) {
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
          child: _Header(
            staleMaps: _staleMaps,
            onApplyUpdates: _applyUpdates,
          ),
        ),

        // ── Packs section (always has at least the two Add Pack cards) ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 24,
              mainAxisSpacing: 14,
              childAspectRatio: kPackCardAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i == 0) {
                  return _CreatePackCard(
                    onTap: () => _openCreatePack(context),
                  ).animate().fadeIn(duration: 350.ms).scale(
                        begin: const Offset(0.95, 0.95),
                      );
                }
                if (i == 1) {
                  return _GetPackCard(
                    onTap: () => _openGetPack(context),
                  ).animate().fadeIn(duration: 350.ms).scale(
                        begin: const Offset(0.95, 0.95),
                      );
                }

                final pack = packs[i - 2];
                final isHovered = _hoveredPackId == pack.id;
                return DragTarget<RiddleMap>(
                  onWillAcceptWithDetails: (details) {
                    setState(() => _hoveredPackId = pack.id);
                    return true;
                  },
                  onLeave: (_) => setState(() => _hoveredPackId = null),
                  onAcceptWithDetails: (details) {
                    setState(() => _hoveredPackId = null);
                    DriftService.instance
                        .setMapFolder(details.data.id, pack.id);
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
                      child: _PackCard(pack: pack)
                          .animate(delay: (i * 60).ms)
                          .fadeIn(duration: 350.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                    );
                  },
                );
              },
              childCount: packs.length + 2,
            ),
          ),
        ),

        // ── Section divider ──
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
                      : Colors.transparent,
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
                              : EnolaTheme.textSecond
                                  .withValues(alpha: 0.7),
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
            padding: const EdgeInsets.fromLTRB(40, 8, 40, 100),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 14,
                childAspectRatio: kCardAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return _MapCard(map: unfiled[i])
                      .animate(delay: (i * 60).ms)
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

// ── Pack scroll view (inside a pack) ─────────────────────────────────────────

class _PackScrollView extends ConsumerWidget {
  final int packId;
  final String packName;
  final VoidCallback onCreate;

  const _PackScrollView({
    required this.packId,
    required this.packName,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(packId));
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
          child: _PackHeader(
            packName: packName,
            packId: packId,
          ),
        ),
        if (maps.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyPackState(onCreate: onCreate),
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
  final List<StaleMapInfo> staleMaps;
  final VoidCallback onApplyUpdates;

  const _Header({
    required this.staleMaps,
    required this.onApplyUpdates,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Column(
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
                'Tap a pack to explore or play',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: EnolaTheme.textSecond,
                    ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0),

        // ── Staleness banner ─────────────────────────────────────────────
        if (staleMaps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: EnolaTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: EnolaTheme.accent.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.update_rounded,
                    size: 18, color: EnolaTheme.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${staleMaps.length} map${staleMaps.length > 1 ? 's have' : ' has'} updates available.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: EnolaTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onApplyUpdates,
                  style: TextButton.styleFrom(
                    foregroundColor: EnolaTheme.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

// ── Create Pack Sheet ─────────────────────────────────────────────────────────

class _CreatePackSheet extends StatefulWidget {
  const _CreatePackSheet();

  @override
  State<_CreatePackSheet> createState() => _CreatePackSheetState();
}

class _CreatePackSheetState extends State<_CreatePackSheet> {
  final _controller = TextEditingController();
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final canCreate = _controller.text.trim().isNotEmpty;
      if (canCreate != _canCreate) setState(() => _canCreate = canCreate);
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
            'New Pack',
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
              'Create Pack',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Pack Card (dashed, root grid) ────────────────────────────────────────

class _CreatePackCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreatePackCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFC7CCD4),
          radius: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded,
                      size: 26, color: EnolaTheme.textSecond),
                  const SizedBox(height: 6),
                  Text(
                    'Create Pack',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EnolaTheme.textSecond,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Get a Pack Card (dashed, root grid) ─────────────────────────────────────────

class _GetPackCard extends StatelessWidget {
  final VoidCallback onTap;
  const _GetPackCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFC7CCD4),
          radius: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded,
                      size: 26, color: EnolaTheme.textSecond),
                  const SizedBox(height: 6),
                  Text(
                    'Get a Pack',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EnolaTheme.textSecond,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = _dashPath(path, dashWidth: dashWidth, dashGap: dashGap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double dashWidth, required double dashGap}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dest.addPath(
          metric.extractPath(distance, math.min(next, metric.length)),
          Offset.zero,
        );
        distance = next + dashGap;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ── Header (inside a pack) ────────────────────────────────────────────────────

class _PackHeader extends ConsumerWidget {
  final String packName;
  final int packId;

  const _PackHeader({
    required this.packName,
    required this.packId,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pack?'),
        content: Text(
          'This will delete "$packName". Maps inside it will be unfiled, not deleted.',
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
      final maps = await (DriftService.instance.db
              .select(DriftService.instance.db.riddleMaps)
            ..where((t) => t.folderId.equals(packId)))
          .get();
      for (final map in maps) {
        await DriftService.instance.setMapFolder(map.id, null);
      }
      await DriftService.instance.deleteFolder(packId);
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

    return Hero(
      tag: 'pack-$packId',
      flightShuttleBuilder: _shuttle,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
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
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded),
                color: EnolaTheme.textSecond,
              ),
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
                  Color.lerp(
                      const Color(0xa1ee8b60), Colors.transparent, t)!,
                  Color.lerp(
                      const Color(0xffff4c00), Colors.transparent, t)!,
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

// ── Editable pack title ───────────────────────────────────────────────────────

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

// ── Pack Card ──────────────────────────────────────────────────────────────────

class _PackCard extends ConsumerWidget {
  final Folder pack;
  const _PackCard({required this.pack});

  void _openPack(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => HomeScreen(
          packId: pack.id,
          packName: pack.title,
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
    final mapsAsync = ref.watch(mapsInFolderProvider(pack.id));
    final maps = mapsAsync.valueOrNull ?? [];

    return GestureDetector(
      onTap: () => _openPack(context),
      child: Hero(
        tag: 'pack-${pack.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xa1ee8b60), Color(0xffff4c00)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffff4c00).withAlpha(70),
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
    _PackRankGrid(maps: maps),
    const SizedBox(height: 4),
    _PackInfoBar(title: pack.title),
  ],
),

          ),
        ),
      ),
    );
  }
}

// ── Pack Rank Grid ─────────────────────────────────────────────────────────────

/// Shows a 3-column grid of rank icons (assets/images/4.jpg down to 0.jpg)
/// with the count of maps in this pack currently sitting at each rank.

class _PackRankGrid extends ConsumerWidget {
  final List<RiddleMap> maps;
  const _PackRankGrid({required this.maps});

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
      final rank = _rankIndex(starRatio);
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const cols = 3;
          const spacing = 8.0;
          final tileSize = (constraints.maxWidth - spacing * (cols - 1)) / cols;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int rank = 4; rank >= 0; rank--)
                _RankTile(
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



class _RankTile extends StatelessWidget {
  final int rank;
  final int count;
  final double size;

  const _RankTile({
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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


/// Same buckets as _rankImage, but returns the index (0..4) instead of asset path.
int _rankIndex(double starRatio) {
  final score = (starRatio * 10).round();
  if (score == 0) return 0;
  if (score < 5) return 1;
  if (score <= 6) return 2;
  if (score <= 9) return 3;
  return 4;
}

// ── Pack Info Bar ─────────────────────────────────────────────────────────────

class _PackInfoBar extends StatelessWidget {
  final String title;
  const _PackInfoBar({required this.title});

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

    // The map's cover image is now always the rank image, reflecting
    // current star progress (rank 0 if not started).
    final String coverAsset = _rankImage(starRatio);

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



// ── Card Shell ────────────────────────────────────────────────────────────────

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

// ── Rank helpers ──────────────────────────────────────────────────────────────

String _rankImage(double starRatio) {
  final score = (starRatio * 10).round();
  if (score == 0) return 'assets/images/0.jpg';
  if (score < 5) return 'assets/images/1.jpg';
  if (score <= 6) return 'assets/images/2.jpg';
  if (score <= 9) return 'assets/images/3.jpg';
  return 'assets/images/4.jpg';
}

// ── Rank Ribbon Overlay ───────────────────────────────────────────────────────

class _RankRibbonOverlay extends StatelessWidget {
  final double starRatio;
  const _RankRibbonOverlay({required this.starRatio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEE8B60), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          _rankImage(starRatio),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ── Star Progress Bar ─────────────────────────────────────────────────────────

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

// ── Empty Pack State ───────────────────────────────────────────────────────────

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
              'Create a map or drag existing maps\ninto this pack.',
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

// ── Pack Back FAB ──────────────────────────────────────────────────────────────

class _PackBackFab extends StatefulWidget {
  final VoidCallback onBack;
  final Future<void> Function(String mapId) onUnfile;

  const _PackBackFab({
    required this.onBack,
    required this.onUnfile,
  });

  @override
  State<_PackBackFab> createState() => _PackBackFabState();
}

class _PackBackFabState extends State<_PackBackFab> {
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
        return GestureDetector(
          onTap: widget.onBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isDraggingOver ? EnolaTheme.accent : Colors.white,
              shape: BoxShape.circle,
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
            child: Icon(
              _isDraggingOver
                  ? Icons.folder_off_outlined
                  : Icons.home_rounded,
              size: 24,
              color: _isDraggingOver
                  ? Colors.white
                  : EnolaTheme.textPrimary,
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
