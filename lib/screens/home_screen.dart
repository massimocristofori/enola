import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/download_pack_screen.dart';
import 'package:enola/screens/pack_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/supabase_service.dart';
import 'package:enola/screens/pack_shared.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  void _openPack(BuildContext context, Folder pack) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 750),
				reverseTransitionDuration: const Duration(milliseconds: 600),
				pageBuilder: (_, animation, __) => PackScreen(
  packId: pack.id,
  packName: pack.title,
  flightAnimation: animation,
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
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(allFoldersProvider);
    final packs = packsAsync.valueOrNull ?? [];

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
              child: packsAsync.isLoading
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
                          child: _Header(
                            staleMaps: _staleMaps,
                            onApplyUpdates: _applyUpdates,
                            onCreatePack: () => _openCreatePack(context),
                            onGetPack: () => _openGetPack(context),
                          ),
                        ),
                        if (packs.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyHomeState(
                              onCreatePack: () => _openCreatePack(context),
                              onGetPack: () => _openGetPack(context),
                            ),
                          )
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(40, 0, 40, 100),
                            sliver: SliverToBoxAdapter(
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 14,
                                children: [
                                  for (int i = 0; i < packs.length; i++)
                                    SizedBox(
                                      width: cardWidth(context),
                                      child: _PackGridItem(
                                        pack: packs[i],
                                        index: i,
                                        onTap: () =>
                                            _openPack(context, packs[i]),
                                      ),
                                    ),
                                ],
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
        floatingActionButton: const TrainingFab(),
      ),
    );
  }
}

// ── Pack grid item ────────────────────────────────────────────────────────

class _PackGridItem extends StatelessWidget {
  final Folder pack;
  final int index;
  final VoidCallback onTap;

  const _PackGridItem({
    required this.pack,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PackCard(pack: pack, onTap: onTap)
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Empty Home State (no packs yet) ──────────────────────────────────────

class _EmptyHomeState extends StatelessWidget {
  final VoidCallback onCreatePack;
  final VoidCallback onGetPack;

  const _EmptyHomeState({
    required this.onCreatePack,
    required this.onGetPack,
  });

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
              'No packs yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: EnolaTheme.accent),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your own pack or download one to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: onCreatePack,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Pack'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onGetPack,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Get a Pack'),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms).scale(
            begin: const Offset(0.9, 0.9),
          ),
    );
  }
}

// ── Header (root) ────────────────────────────────────────────────────────

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
        if (staleMaps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: EnolaTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: EnolaTheme.accent.withOpacity(0.25)),
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

// ── Create Pack Sheet ─────────────────────────────────────────────────────

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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

// ── Pack Card ─────────────────────────────────────────────────────────────
//
// Wraps the shared PackCardBody in the Hero + tap handler. The visual
// (rank grid + title bar) itself lives in pack_shared.dart so the pack
// screen's lip can reuse the exact same widget.

class _PackCard extends ConsumerWidget {
  final Folder pack;
  final VoidCallback onTap;
  const _PackCard({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownershipAsync = ref.watch(packOwnershipProvider(pack.id));
    final bool isOwned = isOwnedLookup(ownershipAsync.valueOrNull);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'pack-${pack.id}',
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: double.infinity,
            child: PackCardBody(pack: pack, isOwned: isOwned),
          ),
        ),
      ),
    );
  }
}
