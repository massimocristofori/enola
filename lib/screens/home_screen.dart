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

// ── Ownership provider ────────────────────────────────────────────────────────

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
/// as owned, matching the existing plain-delete-dialog logic.
bool _isOwnedLookup(OwnedPackLookup? lookup) => lookup == null || lookup.isOwner;

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
                  _PackBackFab(onBack: () => Navigator.pop(context)),
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
            onCreatePack: () => _openCreatePack(context),
            onGetPack: () => _openGetPack(context),
          ),
        ),

        // ── Packs section ──
        // Uses a Wrap (not a SliverGrid) so each Pack Card can size itself
        // to its own content height instead of being forced into a fixed
        // aspect-ratio cell. Cards are pinned to the same per-column width
        // as before via _cardWidth(context).
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                for (int i = 0; i < packs.length; i++)
                  SizedBox(
                    width: _cardWidth(context),
                    child: _PackGridItem(
                      pack: packs[i],
                      index: i,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Section divider ──
        /*SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Divider(color: Color(0xFFE5E7EB)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Maps',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EnolaTheme.textSecond.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Divider(color: Color(0xFFE5E7EB)),
                ),
              ],
            ),
          ),
        ),*/

        // ── Unfiled maps ──
        if (unfiled.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(40, 8, 40, 100),
            sliver: SliverToBoxAdapter(
              child: _ReorderableMapGrid(
                maps: unfiled,
                crossAxisCount: cols,
              ),
            ),
          ),

        if (unfiled.isEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Pack grid item ─────────────────────────────────────────────────────────────

/// Plain wrapper around a Pack Card. No longer a DragTarget — packs can no
/// longer receive maps via drag; map order is purely user-controlled via
/// in-list reordering (see _ReorderableMapGrid).
class _PackGridItem extends StatelessWidget {
  final Folder pack;
  final int index;

  const _PackGridItem({
    required this.pack,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return _PackCard(pack: pack)
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.95, 0.95));
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
            sliver: SliverToBoxAdapter(
              child: _ReorderableMapGrid(
                maps: maps,
                crossAxisCount: cols,
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
  final VoidCallback onCreatePack;
  final VoidCallback onGetPack;

  const _Header({
    required this.staleMaps,
    required this.onApplyUpdates,
    required this.onCreatePack,
    required this.onGetPack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              ),
              IconButton(
                onPressed: onCreatePack,
                icon: const Icon(Icons.add_rounded),
                color: EnolaTheme.textSecond,
                tooltip: 'Create Pack',
              ),
              IconButton(
                onPressed: onGetPack,
                icon: const Icon(Icons.download_rounded),
                color: EnolaTheme.textSecond,
                tooltip: 'Get a Pack',
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

// ── Header (inside a pack) ────────────────────────────────────────────────────

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
      // Never shared / never downloaded — plain local delete.
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
    // Returns: null = cancel, false = local only, true = local + remote
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
    final bool isOwned = _isOwnedLookup(ownershipAsync.valueOrNull);

    final List<Color> gradientColors = isOwned
        ? const [Color(0xa1ee8b60), Color(0xffff4c00)]
        : const [Color(0xFF81D7FD), Color(0xFF00ADFF)];

    return Hero(
      tag: 'pack-$packId',
      flightShuttleBuilder: (flightContext, animation, direction, fromCtx, toCtx) =>
          _shuttle(flightContext, animation, direction, fromCtx, toCtx, gradientColors),
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
                onPressed: () => _handleDeleteTap(context),
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

    final ownershipAsync = ref.watch(packOwnershipProvider(pack.id));
    final bool isOwned = _isOwnedLookup(ownershipAsync.valueOrNull);

    final List<Color> gradientColors = isOwned
        ? const [Color(0xa1ee8b60), Color(0xffff4c00)]
        : const [Color(0xFF81D7FD), Color(0xFF00ADFF)];
    final Color accentColor =
        isOwned ? const Color(0xffff4c00) : const Color(0xFF00ADFF);

    return GestureDetector(
      onTap: () => _openPack(context),
      child: Hero(
        tag: 'pack-${pack.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(8),
              border: isOwned
                  ? null
                  : Border.all(color: accentColor, width: 2),
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
            // Content-sized: the card grows to fit the rank grid + info bar
            // exactly, instead of being forced into a fixed aspect ratio.
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
              // Highest rank (4) first, down to 0
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

// ── Reorderable Map Grid ──────────────────────────────────────────────────────

/// Renders maps in the existing fixed-aspect-ratio grid, but supports
/// dragging a card to reorder it among its siblings ONLY — order is purely
/// user-driven (persisted via RiddleMap.sortOrder). Dragging never moves a
/// map in/out of a pack anymore; there is no cross-list drop target.
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
    // Only resync from the incoming stream snapshot when not actively
    // dragging, and only if the set/order of ids actually changed — this
    // avoids fighting the live reorder while a drag is in progress, while
    // still picking up external changes (new map created, map deleted).
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
            width: _cardWidth(context),
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

// ── Map Card ──────────────────────────────────────────────────────────────────

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

/// Plain back button — dragging a map onto this no longer unfiles it.
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
