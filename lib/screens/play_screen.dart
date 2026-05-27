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
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/training_service.dart';
import 'package:enola/services/notification_service.dart';

import 'package:drift/drift.dart' as drift;

const double kPlayHeaderHeight = 90.0;
const double kPlayHeaderCompact = 58.0;

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
      _registerTrainingTapHandler();
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

  void _registerTrainingTapHandler() {
    TrainingService.instance.onTrainingNotificationTap = (mapId, riddleId) {
      if (mapId != widget.mapId) return;
      final riddles = ref.read(riddlesForMapProvider(widget.mapId)).valueOrNull;
      if (riddles == null) return;
      final index = riddles.indexWhere((r) => r.id == riddleId);
      if (index == -1) return;
      if (mounted) {
        setState(() {
          _activeRiddleIndex = index;
          _activeRiddleReadOnly = false;
          _activeRiddleTraining = true;
          _activeRiddleId = riddleId;
        });
      }
    };
  }

  Future<void> _onToggleTraining(List<Riddle> riddles) async {
    if (_trainingActive) {
      // Stop training
      final confirm = await _showStopTrainingDialog();
      if (!confirm) return;
      await TrainingService.instance.stopTraining(widget.mapId);
      if (mounted) setState(() => _trainingActive = false);
    } else {
      // Start training
      final hours = await _showStartTrainingDialog();
      if (hours == null) return;

      final granted = await NotificationService.instance.requestPermissions();
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
        durationHours: hours,
      );
      if (mounted) setState(() => _trainingActive = true);
    }
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
                child: const Text(
                  'Stop',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<int?> _showStartTrainingDialog() async {
    int selectedHours = 24;
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
                'The app will send you riddle notifications over the chosen period to help you study.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Training duration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [6, 12, 24, 48, 72].map((h) {
                  final selected = selectedHours == h;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedHours = h),
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
                        '${h}h',
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
              onPressed: () => Navigator.pop(context, selectedHours),
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
          if (raw != null) {
            tempStars = (jsonDecode(raw) as List).cast<int>();
          }
        } catch (e) {
          debugPrint("JSON Decode error: $e");
        }
        riddleStars = tempStars;
      } else if (existing.isNotEmpty && existing.first.completedAt != null) {
        isCompleted = true;
        sessionId = existing.first.id;
        lastCompleted = existing.first.lastCompletedIndex;
        correctAnswers = existing.first.correctAnswers;
        final raw = existing.first.riddleStarsJson;
        List<int> tempStars = [];
        try {
          if (raw != null) {
            tempStars = (jsonDecode(raw) as List).cast<int>();
          }
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
    // Training mode: notify service and dismiss — no stars, no session update
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

    // Normal play mode
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

  void _runStarAnimation(int riddleIndex, int starCount, int baseStars) {
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
          if (mounted) setState(() => _animatedStars = baseStars + landedCount);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                  top: riddleActive ? kPlayHeaderCompact : kPlayHeaderHeight,
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
                            error: (e, _) => Center(child: Text('$e')),
                            data: (riddles) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: riddleActive
                                    ? RiddleScreen(
                                        key: ValueKey(
                                            'riddle-$_activeRiddleIndex'),
                                        riddle:
                                            riddles[_activeRiddleIndex!],
                                        riddleIndex: _activeRiddleIndex!,
                                        readOnly: _activeRiddleReadOnly,
                                        trainingMode: _activeRiddleTraining,
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

class _MapView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Training toggle bar ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: GestureDetector(
            onTap: onToggleTraining,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: trainingActive
                    ? EnolaTheme.accent.withAlpha(20)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: trainingActive
                      ? EnolaTheme.accent
                      : EnolaTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    trainingActive
                        ? Icons.school_rounded
                        : Icons.school_outlined,
                    size: 18,
                    color: trainingActive
                        ? EnolaTheme.accent
                        : EnolaTheme.textSecond,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trainingActive
                          ? 'Training mode is ON'
                          : 'Training mode is OFF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: trainingActive
                            ? EnolaTheme.accent
                            : EnolaTheme.textSecond,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      key: ValueKey(trainingActive),
                      trainingActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 32,
                      color: trainingActive
                          ? EnolaTheme.accent
                          : EnolaTheme.textSecond,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Quest complete! All riddles solved.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: EnolaTheme.accent.withAlpha(200),
              ),
            ).animate().fadeIn(delay: 400.ms),
          )
        else if (playState.lastCompletedIndex < riddles.length - 1)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Tap the glowing node to answer the next riddle',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: EnolaTheme.textSecond.withAlpha(180),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TreasureMapPath(
                  riddles: riddles,
                  mapId: mapId,
                  lastCompletedIndex: playState.lastCompletedIndex,
                  riddleStars: playState.riddleStars,
                  imageBytes: imageBytes,
                  nodeKeys: nodeKeys,
                  immediateActivation: playState.lastCompletedIndex == -1,
                  onCurrentNodeTap: isCompleted
                      ? null
                      : playState.lastCompletedIndex < riddles.length - 1
                          ? () =>
                              onNodeTap(playState.lastCompletedIndex + 1)
                          : null,
                  onCompletedNodeTap: onCompletedNodeTap,
                ),
              ),
            ),
          ),
        ),
      ],
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

  const _PlayHeader({
    required this.mapId,
    required this.title,
    required this.achievedStars,
    required this.maxStars,
    required this.hasBeenPlayed,
    required this.starKey,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Hero(
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
                  BorderRadius.vertical(bottom: Radius.circular(20)),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: compact ? 0 : 32,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: Text(
                          title,
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              key: starKey,
                              Icons.star_rounded,
                              size: 17,
                              color: const Color(0xFFf59e0b),
                            ),
                            const SizedBox(width: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text(
                                key: ValueKey(achievedStars),
                                hasBeenPlayed
                                    ? '$achievedStars / $maxStars'
                                    : '$maxStars',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxStars > 0 && hasBeenPlayed
                                ? achievedStars / maxStars
                                : 0,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFf59e0b)),
                          ),
                        ),
                      ],
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
        ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn)),
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
                      Shadow(
                        color: Colors.white,
                        blurRadius: 6,
                      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
  const _PlayAgainFab({required this.onPlayAgain, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onBack,
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
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onPlayAgain,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                Icon(Icons.replay_rounded, size: 20, color: Colors.white),
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
