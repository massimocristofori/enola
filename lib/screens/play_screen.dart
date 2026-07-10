// ── play_screen.dart ──────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import 'package:enola/utils/rank_image.dart';
import 'package:drift/drift.dart' as drift;

// Maintained to ensure external screens like pack_screen can reference it
const double kPlayHeaderHeight = 38.0;
const double kPlayHeaderCompact = 0.0;

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
  final GlobalKey _progressBarStarKey = GlobalKey();
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
    final active = await TrainingService.instance.isTrainingActive(widget.mapId);
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
      await TrainingService.instance.startTraining(
        mapId: widget.mapId,
        riddles: riddles,
        durationMinutes: minutes,
      );
      if (mounted) setState(() => _trainingActive = true);
    }
  }

  Future<int?> _showStartTrainingDialog() async {
    final List<MapEntry<String, int>> choices = [
      const MapEntry('1 hour', 60),
      const MapEntry('3 hours', 180),
      const MapEntry('6 hours', 360),
      const MapEntry('12 hours', 720),
      const MapEntry('24 hours', 1440),
      const MapEntry('48 hours', 2880),
    ];

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Training Mode'),
        content: const Text('How often would you like to be quizzed on forgotten or weak items?'),
        actions: choices.map((c) => TextButton(
          onPressed: () => Navigator.pop(context, c.value),
          child: Text(c.key),
        )).toList(),
      ),
    );
  }

  Future<bool> _showStopTrainingDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Training?'),
        content: const Text('This will cancel all scheduled training notifications for this map.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ── Session loading ────────────────────────────────────────────────────────
  Future<void> _loadSession() async {
    try {
      final session = await ref.read(latestSessionProvider(widget.mapId).future);
      if (!mounted) return;
      setState(() {
        _initialising = false;
        _initError = null;
        if (session == null) {
          _isCompleted = false;
          _activeRiddleIndex = 0;
        } else {
          _isCompleted = session.completedAt != null;
          if (_isCompleted) {
            _activeRiddleIndex = null;
          } else {
            _activeRiddleIndex = session.lastCompletedIndex == null ? 0 : session.lastCompletedIndex! + 1;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialising = false;
        _initError = e.toString();
      });
    }
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
  Future<void> _onRiddleComplete(List<Riddle> riddles, int riddleIndex, int errorCount) async {
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

    final db = DriftService.instance.db;
    final session = await ref.read(latestSessionProvider(widget.mapId).future);
    final now = DateTime.now();

    int calculatedStars = 3 - errorCount;
    if (calculatedStars < 1) calculatedStars = 1;

    int baseStars = 0;
    if (session != null && session.starsJson != null) {
      try {
        final Map<String, dynamic> currentStars = jsonDecode(session.starsJson!);
        baseStars = currentStars.values.fold(0, (sum, val) => sum + (val as int));
      } catch (_) {}
    }

    if (session == null) {
      final starsMap = {riddles[riddleIndex].id.toString(): calculatedStars};
      await db.into(db.playSessions).insert(
        PlaySessionsCompanion.insert(
          mapId: widget.mapId,
          lastCompletedIndex: drift.Value(riddleIndex),
          starsJson: drift.Value(jsonEncode(starsMap)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      _scheduleStarAnimation(riddleIndex, calculatedStars, baseStars);
    } else {
      Map<String, dynamic> starsMap = {};
      if (session.starsJson != null) {
        try {
          starsMap = jsonDecode(session.starsJson!);
        } catch (_) {}
      }
      final riddleIdStr = riddles[riddleIndex].id.toString();
      final int oldStars = starsMap[riddleIdStr] ?? 0;
      if (calculatedStars > oldStars) {
        starsMap[riddleIdStr] = calculatedStars;
      }

      final isMapCompleted = riddleIndex >= riddles.length - 1;
      await (db.update(db.playSessions)..where((t) => t.id.equals(session.id))).write(
        PlaySessionsCompanion(
          lastCompletedIndex: drift.Value(riddleIndex),
          starsJson: drift.Value(jsonEncode(starsMap)),
          completedAt: isMapCompleted ? drift.Value(now) : const drift.Value.absent(),
          updatedAt: drift.Value(now),
        ),
      );

      if (calculatedStars > oldStars) {
        _scheduleStarAnimation(riddleIndex, calculatedStars - oldStars, baseStars);
      }
    }

    ref.invalidate(latestSessionProvider(widget.mapId));
    final updatedSession = await ref.read(latestSessionProvider(widget.mapId).future);

    setState(() {
      if (updatedSession != null && updatedSession.completedAt != null) {
        _isCompleted = true;
        _activeRiddleIndex = null;
      } else {
        _activeRiddleIndex = riddleIndex + 1;
      }
    });
  }

  // ── Star animation ─────────────────────────────────────────────────────────
  void _scheduleStarAnimation(int riddleIndex, int starCount, int baseStars) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _runStarAnimation(riddleIndex, starCount, baseStars);
    });
  }

  void _runStarAnimation(int riddleIndex, int starCount, int baseStars) {
    if (!mounted) return;
    final nodeKey = _nodeKeys[riddleIndex];
    if (nodeKey == null) return;

    final RenderBox? nodeBox = nodeKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? barBox = _progressBarStarKey.currentContext?.findRenderObject() as RenderBox?;

    if (nodeBox == null || barBox == null) return;

    final nodePos = nodeBox.localToGlobal(Offset.zero) + Offset(nodeBox.size.width / 2, nodeBox.size.height / 2);
    final barPos = barBox.localToGlobal(Offset.zero) + Offset(barBox.size.width, barBox.size.height / 2);

    _starOverlay?.remove();
    _starOverlay = OverlayEntry(
      builder: (context) => _FlyingStarsOverlay(
        from: nodePos,
        to: barPos,
        starCount: starCount,
        onStarLanded: (landed) {
          setState(() {
            _animatedStars = baseStars + landed;
          });
        },
        onComplete: () {
          _starOverlay?.remove();
          _starOverlay = null;
          setState(() {
            _animatedStars = null;
          });
        },
      ),
    );

    Overlay.of(context).insert(_starOverlay!);
  }

  // ── Play again ─────────────────────────────────────────────────────────────
  Future<void> _playAgain() async {
    final db = DriftService.instance.db;
    await (db.delete(db.playSessions)..where((t) => t.mapId.equals(widget.mapId))).go();
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
          'This will permanently delete this map, its riddles, and all play history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: EnolaTheme.textSecond)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = DriftService.instance.db;
      await NotificationService.instance.cancelMapTrainingNotifications(widget.mapId);
      await (db.delete(db.playSessions)..where((t) => t.mapId.equals(widget.mapId))).go();
      await (db.delete(db.riddles)..where((t) => t.mapId.equals(widget.mapId))).go();
      await (db.delete(db.maps)..where((t) => t.id.equals(widget.mapId))).go();
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapProvider(widget.mapId));
    final riddlesAsync = ref.watch(riddlesForMapProvider(widget.mapId));
    final sessionAsync = ref.watch(latestSessionProvider(widget.mapId));

    if (_initialising || mapAsync.isLoading || riddlesAsync.isLoading || sessionAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: EnolaTheme.accent)),
      );
    }

    if (_initError != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_initError')),
      );
    }

    final map = mapAsync.value;
    final riddles = riddlesAsync.value ?? [];
    final session = sessionAsync.value;

    if (map == null) {
      return const Scaffold(body: Center(child: Text('Map not found.')));
    }

    int achievedStars = 0;
    if (session?.starsJson != null) {
      try {
        final Map<String, dynamic> starsMap = jsonDecode(session!.starsJson!);
        achievedStars = starsMap.values.fold(0, (sum, val) => sum + (val as int));
      } catch (_) {}
    }

    if (_animatedStars != null) {
      achievedStars = _animatedStars!;
    }

    if (_activeRiddleIndex != null && _activeRiddleIndex! < riddles.length) {
      final activeRiddle = riddles[_activeRiddleIndex!];
      return RiddleScreen(
        riddle: activeRiddle,
        isReadOnly: _activeRiddleReadOnly,
        isTraining: _activeRiddleTraining,
        onComplete: (errorCount) => _onRiddleComplete(riddles, _activeRiddleIndex!, errorCount),
        onDismiss: _dismissRiddle,
      );
    }

    if (_isCompleted && _activeRiddleIndex == null && !_activeRiddleReadOnly) {
      return ResultScreen(
        mapId: widget.mapId,
        onPlayAgain: _playAgain,
        onBack: () => Navigator.pop(context),
      );
    }

    final Uint8List? imageBytes = map.imageBytes;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _MapView(
            riddles: riddles,
            mapId: widget.mapId,
            mapTitle: map.title,
            playSession: session,
            achievedStars: achievedStars,
            hasBeenPlayed: session != null,
            isCompleted: _isCompleted,
            imageBytes: imageBytes,
            nodeKeys: _nodeKeys,
            trainingActive: _trainingActive,
            onNodeTap: _onNodeTap,
            onCompletedNodeTap: _onCompletedNodeTap,
            onToggleTraining: () => _onToggleTraining(riddles),
            progressBarStarKey: _progressBarStarKey,
          ),

          // Bottom FAB bar
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: _PlayActionFabs(
                onBack: () => Navigator.pop(context),
                onEdit: _onEditMap,
                onDelete: _onDeleteMap,
                onPlayAgain: _isCompleted ? _playAgain : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map view ──────────────────────────────────────────────────────────────────
class _MapView extends StatefulWidget {
  final List<Riddle> riddles;
  final String mapId;
  final String mapTitle;
  final PlaySession? playSession;
  final int achievedStars;
  final bool hasBeenPlayed;
  final bool isCompleted;
  final Uint8List? imageBytes;
  final Map<int, GlobalKey> nodeKeys;
  final bool trainingActive;

  final void Function(int) onNodeTap;
  final void Function(int) onCompletedNodeTap;
  final VoidCallback onToggleTraining;
  final GlobalKey progressBarStarKey;

  const _MapView({
    super.key,
    required this.riddles,
    required this.mapId,
    required this.mapTitle,
    required this.playSession,
    required this.achievedStars,
    required this.hasBeenPlayed,
    required this.isCompleted,
    required this.imageBytes,
    required this.nodeKeys,
    required this.trainingActive,
    required this.onNodeTap,
    required this.onCompletedNodeTap,
    required this.onToggleTraining,
    required this.progressBarStarKey,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveNode(immediate: true));
  }

  @override
  void didUpdateWidget(covariant _MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playSession?.lastCompletedIndex != widget.playSession?.lastCompletedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveNode(immediate: false));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveNode({bool immediate = false}) {
    if (!mounted || !_scrollController.hasClients) return;
    
    int? activeIndex;
    if (widget.isCompleted) {
      activeIndex = widget.riddles.length - 1;
    } else {
      activeIndex = widget.playSession?.lastCompletedIndex == null ? 0 : widget.playSession!.lastCompletedIndex! + 1;
    }

    if (activeIndex == null || activeIndex >= widget.riddles.length) return;

    final key = widget.nodeKeys[activeIndex];
    if (key == null) return;

    final context = key.currentContext;
    if (context == null) return;

    if (immediate) {
      Scrollable.ensureVisible(context, alignment: 0.5);
    } else {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getActiveMilestoneIndex(double starRatio) {
    final score = (starRatio * 10).round();
    if (score < 5) return 0;
    if (score <= 6) return 1;
    if (score <= 9) return 2;
    return 3;
  }

  String _rankImageFromIndex(int index) => 'assets/images/$index.jpg';

  @override
  Widget build(BuildContext context) {
    final int maxStars = widget.riddles.length * 3;
    final int achievedStars = widget.achievedStars;
    final double starRatio = maxStars > 0 && widget.hasBeenPlayed ? achievedStars / maxStars : 0.0;
    final activeMilestoneIndex = _getActiveMilestoneIndex(starRatio);
    
    const double milestoneSize = 34.0; // 40.0 - 6px = 34.0

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 54),
          
          // Progress Panel with embedded Map Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.mapTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: EnolaTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _StarProgressBar(
                    progress: starRatio,
                    starKey: widget.progressBarStarKey,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      final isActive = index <= activeMilestoneIndex;
                      return Container(
                        width: milestoneSize,
                        height: milestoneSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? EnolaTheme.accent : const Color(0xFFE5E7EB),
                            width: isActive ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: AssetImage(_rankImageFromIndex(index)),
                            fit: BoxFit.cover,
                            colorFilter: isActive 
                                ? null 
                                : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fully Restored Map Path logic
          TreasureMapPath(
            riddles: widget.riddles,
            lastCompletedIndex: widget.playSession?.lastCompletedIndex,
            isCompleted: widget.isCompleted,
            imageBytes: widget.imageBytes,
            nodeKeys: widget.nodeKeys,
            onNodeTap: widget.onNodeTap,
            onCompletedNodeTap: widget.onCompletedNodeTap,
          ),
          
          const SizedBox(height: 120), // Bottom scroll padding for FAB bar overlay
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
        const double barHeight = 8.0;
        
        return Container(
          height: barHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                key: starKey,
                width: (width * progress.clamp(0.0, 1.0)),
                height: barHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C840),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// ── Play Screen Integrated Pill FAB Bar ───────────────────────────────────────
class _PlayActionFabs extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onPlayAgain;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlayActionFabs({
    required this.onBack,
    this.onPlayAgain,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        children: [
          _IconButton(
            icon: Icons.chevron_left_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.edit_rounded,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.red,
            onTap: onDelete,
          ),
          if (onPlayAgain != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: const Color(0xFFE5E7EB),
            ),
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.replay_rounded,
              iconColor: Colors.white,
              backgroundColor: EnolaTheme.accent,
              onTap: onPlayAgain!,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color backgroundColor;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = EnolaTheme.textPrimary,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: iconColor),
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

class _FlyingStarsOverlayState extends State<_FlyingStarsOverlay> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _positions = [];
  final List<Animation<double>> _scales = [];
  final List<Animation<double>> _opacities = [];
  int _landed = 0;

  static const int _staggerMs = 180;
  static const int _flightMs = 500;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.starCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _flightMs),
      );

      final positionAnim = Tween<Offset>(
        begin: widget.from,
        end: widget.to,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInCubic));

      final scaleAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.6), weight: 30),
        TweenSequenceItem(tween: Tween<double>(begin: 1.6, end: 0.8), weight: 70),
      ]).animate(controller);

      final opacityAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
      ]).animate(controller);

      _controllers.add(controller);
      _positions.add(positionAnim);
      _scales.add(scaleAnim);
      _opacities.add(opacityAnim);

      Future.delayed(Duration(milliseconds: i * _staggerMs), () {
        if (!mounted) return;
        controller.forward().then((_) {
          _landed++;
          widget.onStarLanded(_landed);
          if (_landed == widget.starCount) {
            widget.onComplete();
          }
        });
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
        if (_controllers.length <= i) return const SizedBox.shrink();
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
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
