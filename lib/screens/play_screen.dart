// ── play_screen.dart ──────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/treasure_map_path.dart';
import 'package:enola/screens/riddle_screen.dart';
import 'package:enola/screens/result_screen.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/training_service.dart';
import 'package:enola/services/notification_service.dart';

import 'package:drift/drift.dart' as drift;

// Title row (38) + star row (38) = 76
const double kPlayHeaderHeight = 76.0;
// Compact: only star row visible
const double kPlayHeaderCompact = 38.0;

class PlayScreen extends ConsumerStatefulWidget {
  final String mapId;
  const PlayScreen({super.key, required this.mapId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  bool _initialising = true;
  String? _initError;
  bool _isCompleted = false;

  int? _activeRiddleIndex;
  bool _activeRiddleReadOnly = false;
  bool _activeRiddleTraining = false;
  int? _activeRiddleId;

  // ── Training state ─────────────────────────────────────────────────────────
  bool _trainingActive = false;

  // ── Star animation state ───────────────────────────────────────────────────
  final GlobalKey _headerStarKey = GlobalKey();
  final Map<int, GlobalKey> _nodeKeys = {};
  int? _animatedStars;
  OverlayEntry? _starOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSession();
      await _loadTrainingState();
    });
  }

  @override
  void dispose() {
    _starOverlay?.remove();
    _starOverlay = null;
    super.dispose();
  }

  // ── Training ───────────────────────────────────────────────────────────────

  Future<void> _loadTrainingState() async {
    final active =
        await TrainingService.instance.isTrainingActive(widget.mapId);
    if (mounted) setState(() => _trainingActive = active);
  }

  Future<void> _onToggleTraining(List<Riddle> riddles) async {
    if (_trainingActive) {
      final confirm = await _showStopTrainingDialog();
      if (!confirm) return;
      await TrainingService.instance.stopTraining(widget.mapId);
      if (mounted) setState(() => _trainingActive = false);
    } else {
      final minutes = await _showStartTrainingDialog();
      if (minutes == null) return;

      final granted =
          await NotificationService.instance.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission is required for training mode.'),
            ),
          );
        }
        return;
      }

      await TrainingService.instance.startTraining(
        mapId: widget.mapId,
        riddles: riddles,
        durationMinutes: minutes,
      );
      if (mounted) setState(() => _trainingActive = true);
    }
  }

  Future<int?> _showStartTrainingDialog() async {
    const options = [
      ('1 hour', 60),
      ('3 hours', 180),
      ('6 hours', 360),
      ('12 hours', 720),
      ('24 hours', 1440),
      ('48 hours', 2880),
    ];

    int selectedMinutes = 1440;

    return await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Start Training'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How much time do you have to learn this?',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Riddles will be delivered as notifications. Failed ones will be repeated.',
                style: TextStyle(
                    fontSize: 12, height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final (label, minutes) = opt;
                  final selected = selectedMinutes == minutes;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedMinutes = minutes),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? EnolaTheme.accent
                            : EnolaTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? EnolaTheme.accent
                              : EnolaTheme.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : EnolaTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedMinutes),
              style: ElevatedButton.styleFrom(
                backgroundColor: EnolaTheme.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showStopTrainingDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Stop Training?'),
            content: const Text(
                'This will cancel all scheduled training notifications for this map.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Stop',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Session loading ────────────────────────────────────────────────────────

  Future<void> _loadSession() async {
    if (mounted) {
      setState(() {
        _initialising = true;
        _initError = null;
        _isCompleted = false;
        _activeRiddleIndex = null;
      });
    }

    try {
      try {
        ref.read(playStateProvider.notifier).reset();
      } catch (e) {
        debugPrint("STEP 0 reset failed (ignored): $e");
      }

      await DriftService.instance.ensureReady();

      final db = DriftService.instance.db;
      final riddles = await db.getRiddlesForMap(widget.mapId);

      final currentMap = await (db.select(db.riddleMaps)
            ..where((t) => t.id.equals(widget.mapId)))
          .getSingleOrNull();
      final currentVersion = currentMap?.riddlesVersion ?? 0;

      var existing = await (db.select(db.playSessions)
            ..where((t) => t.mapId.equals(widget.mapId))
            ..orderBy([(t) => drift.OrderingTerm(
                  expression: t.startedAt,
                  mode: drift.OrderingMode.desc,
                )])
            ..limit(1))
          .get();

      if (existing.isNotEmpty &&
          existing.first.riddlesVersion != currentVersion) {
        debugPrint(
            "riddlesVersion mismatch (session=${existing.first.riddlesVersion} "
            "map=$currentVersion) — wiping sessions for ${widget.mapId}");
        await (db.delete(db.playSessions)
              ..where((t) => t.mapId.equals(widget.mapId)))
            .go();
        ref.invalidate(latestSessionProvider(widget.mapId));
        existing = [];
      }

      final int sessionId;
      final int lastCompleted;
      final int correctAnswers;
      final List<int> riddleStars;
      bool isCompleted = false;

      if (existing.isNotEmpty && existing.first.completedAt == null) {
        sessionId = existing.first.id;
        lastCompleted = existing.first.lastCompletedIndex;
        correctAnswers = existing.first.correctAnswers;
        final raw = existing.first.riddleStarsJson;
        List<int> tempStars = [];
        try {
          if (raw != null)
            tempStars = (jsonDecode(raw) as List).cast<int>();
        } catch (e) {
          debugPrint("JSON Decode error: $e");
        }
        riddleStars = tempStars;
      } else if (existing.isNotEmpty &&
          existing.first.completedAt != null) {
        isCompleted = true;
        sessionId = existing.first.id;
        lastCompleted = existing.first.lastCompletedIndex;
        correctAnswers = existing.first.correctAnswers;
        final raw = existing.first.riddleStarsJson;
        List<int> tempStars = [];
        try {
          if (raw != null)
            tempStars = (jsonDecode(raw) as List).cast<int>();
        } catch (e) {
          debugPrint("JSON Decode error: $e");
        }
        riddleStars = tempStars;
      } else {
        sessionId = await DriftService.instance.startSession(
          widget.mapId,
          riddles.length,
        );
        lastCompleted = -1;
        correctAnswers = 0;
        riddleStars = [];
      }

      ref.read(playStateProvider.notifier).init(
          sessionId, lastCompleted, correctAnswers, riddleStars);

      if (mounted) setState(() => _isCompleted = isCompleted);
    } catch (e, stackTrace) {
      debugPrint("CAUGHT ERROR: $e");
      debugPrint("$stackTrace");
      if (mounted) {
        setState(() {
          _initError = 'CAUGHT: $e\n\n$stackTrace';
          _initialising = false;
        });
        return;
      }
    }

    if (mounted) setState(() => _initialising = false);
  }

  // ── Node taps ──────────────────────────────────────────────────────────────

  void _onNodeTap(int riddleIndex) {
    setState(() {
      _activeRiddleIndex = riddleIndex;
      _activeRiddleReadOnly = false;
      _activeRiddleTraining = false;
      _activeRiddleId = null;
    });
  }

  void _onCompletedNodeTap(int riddleIndex) {
    setState(() {
      _activeRiddleIndex = riddleIndex;
      _activeRiddleReadOnly = true;
      _activeRiddleTraining = false;
      _activeRiddleId = null;
    });
  }

  void _dismissRiddle() {
    setState(() {
      _activeRiddleIndex = null;
      _activeRiddleTraining = false;
      _activeRiddleId = null;
    });
  }

  // ── Riddle complete ────────────────────────────────────────────────────────

  Future<void> _onRiddleComplete(
      List<Riddle> riddles, int riddleIndex, int errorCount) async {
    if (_activeRiddleTraining && _activeRiddleId != null) {
      final correct = errorCount == 0;
      await TrainingService.instance.onRiddleAnswered(
        mapId: widget.mapId,
        riddleId: _activeRiddleId!,
        correct: correct,
        riddles: riddles,
      );
      _dismissRiddle();
      return;
    }

    final earnedStars = starsForErrors(errorCount);
    final baseStars = ref.read(playStateProvider)?.totalStars ?? 0;

    if (earnedStars > 0 && riddleIndex < riddles.length - 1) {
      setState(() {
        _activeRiddleIndex = null;
        _animatedStars = baseStars;
      });
    }

    await ref
        .read(playStateProvider.notifier)
        .completeRiddle(riddleIndex, errorCount);

    ref.invalidate(latestSessionProvider(widget.mapId));

    if (riddleIndex == riddles.length - 1) {
      final totalStars = ref.read(playStateProvider)?.totalStars ?? 0;
      final maxStars = riddles.length * 3;
      await ref.read(playStateProvider.notifier).finish();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              mapId: widget.mapId,
              correct: riddles.length,
              total: riddles.length,
              totalStars: totalStars,
              maxStars: maxStars,
            ),
          ),
        );
      }
    } else {
      if (earnedStars > 0) {
        _scheduleStarAnimation(riddleIndex, earnedStars, baseStars);
      } else {
        setState(() => _activeRiddleIndex = null);
      }
    }
  }

  // ── Star animation ─────────────────────────────────────────────────────────

  void _scheduleStarAnimation(
      int riddleIndex, int starCount, int baseStars) {
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      _runStarAnimation(riddleIndex, starCount, baseStars);
    });
  }

  void _runStarAnimation(
      int riddleIndex, int starCount, int baseStars) {
    if (!mounted) return;

    final nodeKey = _nodeKeys[riddleIndex];
    if (nodeKey == null) return;

    final nodeBox =
        nodeKey.currentContext?.findRenderObject() as RenderBox?;
    final headerBox =
        _headerStarKey.currentContext?.findRenderObject() as RenderBox?;
    if (nodeBox == null || headerBox == null) return;

    final nodePos = nodeBox.localToGlobal(
      Offset(nodeBox.size.width / 2, nodeBox.size.height / 2),
    );
    final headerPos = headerBox.localToGlobal(
      Offset(headerBox.size.width / 2, headerBox.size.height / 2),
    );

    _starOverlay?.remove();
    _starOverlay = OverlayEntry(
      builder: (_) => _FlyingStarsOverlay(
        from: nodePos,
        to: headerPos,
        starCount: starCount,
        onStarLanded: (landedCount) {
          if (mounted)
            setState(() => _animatedStars = baseStars + landedCount);
        },
        onComplete: () {
          _starOverlay?.remove();
          _starOverlay = null;
          if (mounted) setState(() => _animatedStars = null);
        },
      ),
    );

    Overlay.of(context).insert(_starOverlay!);
  }

  // ── Play again ─────────────────────────────────────────────────────────────

  Future<void> _playAgain() async {
    final db = DriftService.instance.db;
    await (db.delete(db.playSessions)
          ..where((t) => t.mapId.equals(widget.mapId)))
        .go();
    ref.invalidate(latestSessionProvider(widget.mapId));
    await _loadSession();
  }

  // ── Edit map ───────────────────────────────────────────────────────────────

  void _onEditMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMapScreen(existingMapId: widget.mapId),
      ),
    );
  }

  // ── Delete map ─────────────────────────────────────────────────────────────

  Future<void> _onDeleteMap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Map?'),
        content: const Text(
            'This will permanently delete the map and all its riddles and progress. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = DriftService.instance.db;
    await (db.delete(db.riddles)
          ..where((t) => t.mapId.equals(widget.mapId)))
        .go();
    await (db.delete(db.playSessions)
          ..where((t) => t.mapId.equals(widget.mapId)))
        .go();
    await (db.delete(db.riddleMaps)
          ..where((t) => t.id.equals(widget.mapId)))
        .go();
    ref.invalidate(allMapsProvider);

    if (mounted) Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapProvider(widget.mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(widget.mapId));
    final playState = ref.watch(playStateProvider);

    if (_initError != null) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _initError!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ),
        ),
      );
    }

    final map = mapAsync.valueOrNull;
    final riddles = riddlesAsync.valueOrNull;

    final title = map?.title ?? '';
    final maxStars = (riddles?.length ?? 0) * 3;
    final realAchievedStars = playState?.totalStars ?? 0;
    final achievedStars = _animatedStars ?? realAchievedStars;
    final hasBeenPlayed = (playState?.lastCompletedIndex ?? -1) >= 0;
    final bool showingLoader = _initialising || playState == null;
    final bool riddleActive = _activeRiddleIndex != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: riddleActive
          ? null
          : _isCompleted
              ? _PlayAgainFab(
                  onPlayAgain: _playAgain,
                  onBack: () => Navigator.pop(context),
                )
              : _BackFab(onTap: () => Navigator.pop(context)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: riddleActive
                      ? kPlayHeaderCompact
                      : kPlayHeaderHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: showingLoader
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: EnolaTheme.accent))
                      : mapAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: EnolaTheme.accent)),
                          error: (e, _) => Center(child: Text('$e')),
                          data: (map) => riddlesAsync.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: EnolaTheme.accent)),
                            error: (e, _) =>
                                Center(child: Text('$e')),
                            data: (riddles) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                alignment: Alignment.topCenter, // <--- Fix 1: Align transition to top
                                child: riddleActive
                                    ? RiddleScreen(
                                        key: ValueKey(
                                            'riddle-$_activeRiddleIndex'),
                                        riddle: riddles[
                                            _activeRiddleIndex!],
                                        riddleIndex:
                                            _activeRiddleIndex!,
                                        readOnly: _activeRiddleReadOnly,
                                        trainingMode:
                                            _activeRiddleTraining,
                                        onDismiss: _dismissRiddle,
                                        onComplete: (errorCount) =>
                                            _onRiddleComplete(
                                                riddles,
                                                _activeRiddleIndex!,
                                                errorCount),
                                        onSkip: () => _onRiddleComplete(
                                            riddles,
                                            _activeRiddleIndex!,
                                            3),
                                      )
                                    : _MapView(
                                        key: const ValueKey('map'),
                                        riddles: riddles,
                                        mapId: widget.mapId,
                                        playState: playState,
                                        isCompleted: _isCompleted,
                                        imageBytes: map?.imageBytes,
                                        nodeKeys: _nodeKeys,
                                        trainingActive: _trainingActive,
                                        onNodeTap: _onNodeTap,
                                        onCompletedNodeTap:
                                            _onCompletedNodeTap,
                                        onToggleTraining: () =>
                                            _onToggleTraining(riddles),
                                      ),
                              );
                            },
                          ),
                        ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _PlayHeader(
                    mapId: widget.mapId,
                    title: title,
                    achievedStars: achievedStars,
                    maxStars: maxStars,
                    hasBeenPlayed: hasBeenPlayed,
                    compact: riddleActive,
                    starKey: _headerStarKey,
                    onEdit: _onEditMap,
                    onDelete: _onDeleteMap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Map view ──────────────────────────────────────────────────────────────────

class _MapView extends StatefulWidget {
  final List<Riddle> riddles;
  final String mapId;
  final dynamic playState;
  final bool isCompleted;
  final dynamic imageBytes;
  final Map<int, GlobalKey> nodeKeys;
  final bool trainingActive;
  final void Function(int) onNodeTap;
  final void Function(int) onCompletedNodeTap;
  final VoidCallback onToggleTraining;

  const _MapView({
    super.key,
    required this.riddles,
    required this.mapId,
    required this.playState,
    required this.isCompleted,
    required this.imageBytes,
    required this.nodeKeys,
    required this.trainingActive,
    required this.onNodeTap,
    required this.onCompletedNodeTap,
    required this.onToggleTraining,
  });

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToActiveNode(immediate: true));
  }

  @override
  void didUpdateWidget(covariant _MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playState.lastCompletedIndex !=
        widget.playState.lastCompletedIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToActiveNode(immediate: false));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveNode({bool immediate = false}) {
    if (!mounted || !_scrollController.hasClients) return;

    int targetIndex = widget.playState.lastCompletedIndex + 1;
    if (targetIndex >= widget.riddles.length || widget.isCompleted) {
      targetIndex = widget.riddles.length - 1;
    }
    if (targetIndex < 0) targetIndex = 0;

    final nodeKey = widget.nodeKeys[targetIndex];
    if (nodeKey == null) return;

    final nodeBox =
        nodeKey.currentContext?.findRenderObject() as RenderBox?;
    final scrollBox = context.findRenderObject() as RenderBox?;
    if (nodeBox == null || scrollBox == null) return;

    final nodeOffset =
        nodeBox.localToGlobal(Offset.zero, ancestor: scrollBox);
    final nodeCenterY = nodeOffset.dy + (nodeBox.size.height / 2);
    final viewportCenterY = scrollBox.size.height / 2;
    final targetScrollOffset =
        _scrollController.offset + (nodeCenterY - viewportCenterY);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;
    final clampedOffset =
        targetScrollOffset.clamp(minScroll, maxScroll);

    if (immediate) {
      _scrollController.jumpTo(clampedOffset);
    } else {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Helper method to get the active milestone index based on ranking logic
  int _getActiveMilestoneIndex(double starRatio) {
    final score = (starRatio * 10).round();
    if (score < 5) return 0;
    if (score <= 6) return 1;
    if (score <= 9) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate real-time star metrics
    final int maxStars = widget.riddles.length * 3;
    final int achievedStars = widget.playState?.totalStars ?? 0;
    final double starRatio = maxStars > 0 ? achievedStars / maxStars : 0.0;
    final int activeMilestoneIndex = _getActiveMilestoneIndex(starRatio);

    const double rankingBarHeight = 72.0;
    const double stickyHeight = rankingBarHeight;

    // Fix 2: Wrap with SizedBox.expand so it claims the full available height
    return SizedBox.expand(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding:
                EdgeInsets.fromLTRB(24, stickyHeight + 16, 24, 100),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TreasureMapPath(
                  riddles: widget.riddles,
                  mapId: widget.mapId,
                  lastCompletedIndex:
                      widget.playState.lastCompletedIndex,
                  riddleStars: widget.playState.riddleStars,
                  imageBytes: widget.imageBytes,
                  nodeKeys: widget.nodeKeys,
                  immediateActivation:
                      widget.playState.lastCompletedIndex == -1,
                  onCurrentNodeTap: widget.isCompleted
                      ? null
                      : widget.playState.lastCompletedIndex <
                              widget.riddles.length - 1
                          ? () => widget.onNodeTap(
                              widget.playState.lastCompletedIndex + 1)
                          : null,
                  onCompletedNodeTap: widget.onCompletedNodeTap,
                ),
              ),
            ),
          ),

          // Fixed Top Progress/Milestone Panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── NEW: Dynamic Ranking Milestone Progress Row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EnolaTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final bool isActive = index == activeMilestoneIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? EnolaTheme.accent : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: EnolaTheme.accent.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Opacity(
                            opacity: isActive ? 1.0 : 0.35,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: Image.asset(
                                'assets/images/ranking/$index.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: isActive ? Colors.amber : Colors.grey[400],
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // ── HIDDEN (NOT REMOVED): Original Training panel & Hint texts ──
                Visibility(
                  visible: false,
                  maintainState: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: GestureDetector(
                          onTap: widget.onToggleTraining,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: widget.trainingActive
                                  ? EnolaTheme.secondary.withAlpha(20)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: widget.trainingActive
                                    ? EnolaTheme.secondary
                                    : EnolaTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.trainingActive
                                      ? Icons.school_rounded
                                      : Icons.school_outlined,
                                  size: 18,
                                  color: widget.trainingActive
                                      ? EnolaTheme.secondary
                                      : EnolaTheme.textSecond,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.trainingActive
                                        ? 'Training mode is ON'
                                        : 'Training mode is OFF',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: widget.trainingActive
                                          ? EnolaTheme.secondary
                                          : EnolaTheme.textSecond,
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    key: ValueKey(widget.trainingActive),
                                    widget.trainingActive
                                        ? Icons.toggle_on_rounded
                                        : Icons.toggle_off_rounded,
                                    size: 32,
                                    color: widget.trainingActive
                                        ? EnolaTheme.secondary
                                        : EnolaTheme.textSecond,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.isCompleted)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            'Quest complete! All riddles solved.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: EnolaTheme.accent.withAlpha(200),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        )
                      else if (widget.playState.lastCompletedIndex <
                          widget.riddles.length - 1)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            'Tap the glowing node to answer the next riddle',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: EnolaTheme.textSecond.withAlpha(180),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Progress Bar ───────────────────────────────────────────────────────

class _StarProgressBar extends StatelessWidget {
  final double progress;
  final Key? starKey;

  const _StarProgressBar({required this.progress, this.starKey});

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
                  child: Icon(
                    key: starKey,
                    Icons.star_rounded,
                    size: starSize,
                    color: const Color(0xFFF1C40F),
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

// ── Play Header ───────────────────────────────────────────────────────────────

class _PlayHeader extends StatelessWidget {
  final String mapId;
  final String title;
  final int achievedStars;
  final int maxStars;
  final bool hasBeenPlayed;
  final bool compact;
  final GlobalKey starKey;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PlayHeader({
    required this.mapId,
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
    required this.starKey,
    this.compact = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'map-card-$mapId',
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: compact ? kPlayHeaderCompact : kPlayHeaderHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title row — collapses to 0 in compact mode ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: compact ? 0 : 38,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(
                          top: BorderSide(
                              color: Color(0xFFE5E7EB), width: 1),
                          bottom: BorderSide(
                              color: Color(0xFFE5E7EB), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // ── Edit Button ──
                          GestureDetector(
                            onTap: onEdit,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: EnolaTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          // ── Title ──
                          Expanded(
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
                          // ── Delete Button ──
                          GestureDetector(
                            onTap: onDelete,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Star row — always 38px ──
                SizedBox(
                  height: 38,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
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
                            starKey: starKey,
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
          ),
        ),
      ),
    );
  }
}

// ── Flying stars overlay ──────────────────────────────────────────────────────

class _FlyingStarsOverlay extends StatefulWidget {
  final Offset from;
  final Offset to;
  final int starCount;
  final void Function(int landedCount) onStarLanded;
  final VoidCallback onComplete;

  const _FlyingStarsOverlay({
    required this.from,
    required this.to,
    required this.starCount,
    required this.onStarLanded,
    required this.onComplete,
  });

  @override
  State<_FlyingStarsOverlay> createState() => _FlyingStarsOverlayState();
}

class _FlyingStarsOverlayState extends State<_FlyingStarsOverlay>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _positions = [];
  final List<Animation<double>> _scales = [];
  final List<Animation<double>> _opacities = [];
  int _landed = 0;

  static const _staggerMs = 180;
  static const _flightMs = 500;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < widget.starCount; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _flightMs),
      );

      _positions.add(
        Tween<Offset>(begin: widget.from, end: widget.to).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeInCubic),
        ),
      );

      _scales.add(
        TweenSequence([
          TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 1.4), weight: 20),
          TweenSequenceItem(
              tween: Tween(begin: 1.4, end: 0.6), weight: 80),
        ]).animate(
            CurvedAnimation(parent: ctrl, curve: Curves.easeIn)),
      );

      _opacities.add(
        TweenSequence([
          TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 1.0), weight: 70),
          TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(ctrl),
      );

      ctrl.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _landed++;
          widget.onStarLanded(_landed);
          if (_landed == widget.starCount) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) widget.onComplete();
            });
          }
        }
      });

      _controllers.add(ctrl);

      Future.delayed(Duration(milliseconds: i * _staggerMs), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.starCount, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) {
            return Positioned(
              left: _positions[i].value.dx - 14,
              top: _positions[i].value.dy - 14,
              child: Opacity(
                opacity: _opacities[i].value,
                child: Transform.scale(
                  scale: _scales[i].value,
                  child: const Icon(
                    Icons.star_rounded,
                    size: 28,
                    color: Color(0xFFE8C840),
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Back FAB ──────────────────────────────────────────────────────────────────

class _BackFab extends StatelessWidget {
  final VoidCallback onTap;
  const _BackFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
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
          children: const [
            Icon(Icons.chevron_left_rounded,
                size: 22, color: EnolaTheme.textPrimary),
            SizedBox(width: 4),
            Text(
              'My Maps',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: EnolaTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Play Again FAB ────────────────────────────────────────────────────────────

class _PlayAgainFab extends StatelessWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  const _PlayAgainFab(
      {required this.onPlayAgain, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
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
              children: const [
                Icon(Icons.chevron_left_rounded,
                    size: 22, color: EnolaTheme.textPrimary),
                SizedBox(width: 4),
                Text(
                  'My Maps',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: EnolaTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onPlayAgain,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: EnolaTheme.accent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: EnolaTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.replay_rounded,
                    size: 20, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Play Again',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _rankImage(double starRatio) {
  final score = (starRatio * 10).round();
  if (score < 5) return 'assets/images/ranking/0.jpg';
  if (score <= 6) return 'assets/images/ranking/1.jpg';
  if (score <= 9) return 'assets/images/ranking/2.jpg';
  return 'assets/images/ranking/3.jpg';
}
