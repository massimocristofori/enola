// ── treasure_map_path.dart ────────────────────────────────────────────────────

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enola/database/database.dart';
import 'package:enola/theme/enola_theme.dart';

import 'package:enola/providers/map_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum NodeStatus { completed, current, locked }

// ── Treasure map path ─────────────────────────────────────────────────────────

class TreasureMapPath extends ConsumerStatefulWidget {
  final List<Riddle> riddles;
  final String mapId;
  final VoidCallback? onCurrentNodeTap;
  final void Function(int riddleIndex)? onCompletedNodeTap;
  final int? lastCompletedIndex;
  final List<int> riddleStars;
  final Uint8List? imageBytes;
  final bool immediateActivation;
  final Map<int, GlobalKey> nodeKeys;

  const TreasureMapPath({
    super.key,
    required this.riddles,
    required this.mapId,
    required this.nodeKeys,
    this.onCurrentNodeTap,
    this.onCompletedNodeTap,
    this.lastCompletedIndex,
    this.riddleStars = const [],
    this.imageBytes,
    this.immediateActivation = false,
  });

  @override
  ConsumerState<TreasureMapPath> createState() => _TreasureMapPathState();
}

class _TreasureMapPathState extends ConsumerState<TreasureMapPath>
    with SingleTickerProviderStateMixin {

  late AnimationController _fogSlideController;
  late Animation<double> _fogSlideAnimation;

  double _fogFromFraction = 0.0;
  double _fogToFraction   = 0.0;

  double get _fogFraction =>
      _fogFromFraction +
      (_fogToFraction - _fogFromFraction) * _fogSlideAnimation.value;

  @override
  void initState() {
    super.initState();

    _fogSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fogSlideAnimation = CurvedAnimation(
      parent: _fogSlideController,
      curve: Curves.easeInOutCubic,
    )..addListener(() => setState(() {}));

    // Initialise without animation
    final lastCompleted = widget.lastCompletedIndex ?? -1;
    final initial = _computeFogFraction(lastCompleted, widget.riddles.length);
    _fogFromFraction = initial;
    _fogToFraction   = initial;
    _fogSlideController.value = 1.0;
  }

  @override
  void didUpdateWidget(TreasureMapPath old) {
    super.didUpdateWidget(old);

    final newLast = widget.lastCompletedIndex ?? -1;
    final oldLast = old.lastCompletedIndex    ?? -1;

    if (newLast != oldLast) {
      final target = _computeFogFraction(newLast, widget.riddles.length);
      _fogFromFraction = _fogFraction;
      _fogToFraction   = target;
      _fogSlideController.value = 0.0;

      // THIRD: fog slides after stars (FIRST ~700ms) + dots (SECOND ~500ms)
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _fogSlideController.forward();
      });
    }
  }

  @override
  void dispose() {
    _fogSlideController.dispose();
    super.dispose();
  }

  double _computeFogFraction(int lastCompleted, int total) {
    if (total == 0) return 1.0;
    if (lastCompleted >= total - 1) return 1.0;
    const double visibleAhead = 2.5;
    final double revealedRows =
        (lastCompleted + visibleAhead).clamp(0.0, total.toDouble());
    return revealedRows / total;
  }

  @override
  Widget build(BuildContext context) {
    final int lastCompleted;
    if (widget.lastCompletedIndex != null) {
      lastCompleted = widget.lastCompletedIndex!;
    } else {
      final sessionAsync = ref.watch(latestSessionProvider(widget.mapId));
      lastCompleted = sessionAsync.valueOrNull?.lastCompletedIndex ?? -1;
    }

    final nodeColumn = Column(
      children: List.generate(widget.riddles.length, (index) {
        final isEvenRow   = index % 2 == 0;
        final isLast      = index == widget.riddles.length - 1;
        final isCompleted = index <= lastCompleted;
        final isCurrent   = index == lastCompleted + 1;

        final status = isCompleted
            ? NodeStatus.completed
            : isCurrent
                ? NodeStatus.current
                : NodeStatus.locked;

        final stars =
            index < widget.riddleStars.length ? widget.riddleStars[index] : 0;

        widget.nodeKeys.putIfAbsent(index, () => GlobalKey());

        final nodeWidget = _RiddleNode(
          key: widget.nodeKeys[index],
          riddleIndex: index,
          index: index + 1,
          status: status,
          stars: stars,
          imageBytes: widget.imageBytes,
          immediateActivation: widget.immediateActivation,
          onTap: isCurrent && widget.onCurrentNodeTap != null
              ? widget.onCurrentNodeTap
              : null,
          onCompletedTap: isCompleted && widget.onCompletedNodeTap != null
              ? () => widget.onCompletedNodeTap!(index)
              : null,
        );

        // Dot at position `index` connects row `index` → row `index+1`.
        // It should be filled once row `index` is completed.
        final dotsWidget = isLast
            ? const SizedBox.shrink()
            : _DotConnector(
                key: ValueKey('dot-$index'),
                isUnlocked: isCompleted,
                isEvenRow: isEvenRow,
                seed: index,
                // Pass whether this dot was JUST unlocked (i.e. it's the
                // connector immediately after the node just completed).
                // That triggers the sequential fill animation with correct delay.
                animateUnlock: isCompleted && index == lastCompleted,
              );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 110,
                child: isEvenRow
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 30.0),
                          child: nodeWidget,
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: dotsWidget,
                      ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 110,
                child: isEvenRow
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: dotsWidget,
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30.0),
                          child: nodeWidget,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalHeight = widget.riddles.length * 110.0;
        final double fogTopY     = totalHeight * _fogFraction;

        return Stack(
          children: [
            nodeColumn,
            if (_fogFraction < 1.0)
              Positioned(
                top: fogTopY,
                left: 0,
                right: 0,
                bottom: -400,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: const _FogBankPainter(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Fog bank painter ──────────────────────────────────────────────────────────

class _FogBankPainter extends CustomPainter {
  const _FogBankPainter();

  static const Color _fogTop     = Color(0xFFFFFFFF);
  static const Color _fogBottom  = Color(0xFFE2E8EF);
  static const Color _puffFill   = Color(0xFFFFFFFF);
  static const Color _puffShadow = Color(0xFFDDE8F0);
  static const Color _puffStroke = Color(0xFFCCDAE5);

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Gradient fade: transparent → white (top ~38%) ─────────────────────
    final fadePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.38));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.38),
      fadePaint,
    );

    // ── 2. White → light grey gradient body ───────────────────────────────────
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_fogTop, _fogBottom],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.32, size.width, size.height * 0.68),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.32, size.width, size.height * 0.68),
      bodyPaint,
    );

    // ── 3. Cloud puff row ─────────────────────────────────────────────────────
    _drawCloudRow(canvas, size);
  }

  void _drawCloudRow(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = _puffShadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fillPaint   = Paint()..color = _puffFill..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = _puffStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawRow(canvas, size,
        rng: math.Random(77),
        yBase: 10.0, radiusMin: 26.0, radiusMax: 20.0,
        shadowPaint: shadowPaint, fillPaint: fillPaint, strokePaint: strokePaint);

    _drawRow(canvas, size,
        rng: math.Random(42),
        yBase: -2.0, radiusMin: 20.0, radiusMax: 16.0,
        shadowPaint: shadowPaint, fillPaint: fillPaint, strokePaint: strokePaint);
  }

  void _drawRow(
    Canvas canvas,
    Size size, {
    required math.Random rng,
    required double yBase,
    required double radiusMin,
    required double radiusMax,
    required Paint shadowPaint,
    required Paint fillPaint,
    required Paint strokePaint,
  }) {
    double x = -60.0;
    while (x < size.width + 80) {
      final clusterW = 58.0 + rng.nextDouble() * 58.0;
      final baseR    = radiusMin + rng.nextDouble() * radiusMax;
      final cy       = yBase + rng.nextDouble() * 8.0;

      _drawCluster(
        canvas,
        center: Offset(x + clusterW / 2, cy),
        baseRadius: baseR,
        shadowPaint: shadowPaint,
        fillPaint: fillPaint,
        strokePaint: strokePaint,
      );

      x += clusterW * 0.74;
    }
  }

  void _drawCluster(
    Canvas canvas, {
    required Offset center,
    required double baseRadius,
    required Paint shadowPaint,
    required Paint fillPaint,
    required Paint strokePaint,
  }) {
    final puffs = [
      Offset.zero,
      Offset(-baseRadius * 0.60,  baseRadius * 0.22),
      Offset( baseRadius * 0.60,  baseRadius * 0.22),
      Offset(-baseRadius * 0.30, -baseRadius * 0.40),
      Offset( baseRadius * 0.30, -baseRadius * 0.40),
      Offset(0,                  -baseRadius * 0.58),
    ];
    final radii = [1.0, 0.70, 0.70, 0.55, 0.55, 0.46];

    for (int i = 0; i < puffs.length; i++) {
      canvas.drawCircle(center + puffs[i], baseRadius * radii[i], shadowPaint);
    }
    for (int i = 0; i < puffs.length; i++) {
      canvas.drawCircle(center + puffs[i], baseRadius * radii[i], fillPaint);
    }
    for (int i = 0; i < puffs.length; i++) {
      canvas.drawCircle(center + puffs[i], baseRadius * radii[i], strokePaint);
    }
  }

  @override
  bool shouldRepaint(_FogBankPainter old) => false;
}

// ── Node ──────────────────────────────────────────────────────────────────────

class _RiddleNode extends StatefulWidget {
  final int riddleIndex;
  final int index;
  final NodeStatus status;
  final int stars;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;
  final VoidCallback? onCompletedTap;
  final bool immediateActivation;

  const _RiddleNode({
    super.key,
    required this.riddleIndex,
    required this.index,
    required this.status,
    required this.stars,
    this.imageBytes,
    this.onTap,
    this.onCompletedTap,
    this.immediateActivation = false,
  });

  @override
  State<_RiddleNode> createState() => _RiddleNodeState();
}

class _RiddleNodeState extends State<_RiddleNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _isReached = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.92,
      upperBound: 1.08,
    );
    _checkActivation();
  }

  void _checkActivation() {
    if (widget.status == NodeStatus.current) {
      if (widget.immediateActivation) {
        if (mounted) {
          setState(() => _isReached = true);
          _pulse.repeat(reverse: true);
        }
      } else {
        // THIRD: activate after FIRST (~700ms) + SECOND dots (~500ms)
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() => _isReached = true);
            _pulse.repeat(reverse: true);
          }
        });
      }
    } else if (widget.status == NodeStatus.completed) {
      _isReached = true;
    }
  }

  @override
  void didUpdateWidget(_RiddleNode old) {
    super.didUpdateWidget(old);
    if (widget.status != old.status) {
      _checkActivation();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.status == NodeStatus.locked ||
        (widget.status == NodeStatus.current && !_isReached);
    final isCompleted = widget.status == NodeStatus.completed;
    final isCurrentReached =
        widget.status == NodeStatus.current && _isReached;

    return GestureDetector(
      onTap: isCurrentReached
          ? widget.onTap
          : isCompleted
              ? widget.onCompletedTap
              : null,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ScaleTransition(
          scale: isCurrentReached
              ? _pulse
              : const AlwaysStoppedAnimation(1.0),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: _buildBox(isCompleted, isCurrentReached, isLocked),
              ),
              if (isCompleted)
                Positioned(top: 0, child: _StarsRow(stars: widget.stars)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox(bool isCompleted, bool isCurrent, bool isLocked) {
    const double size = 60;
    const radius = BorderRadius.all(Radius.circular(18));

    if (isCurrent) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EnolaTheme.accent,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
                color: EnolaTheme.accent.withValues(alpha: 0.4),
                blurRadius: 12)
          ],
        ),
        child: const Icon(Icons.star_rounded, color: Colors.white, size: 40),
      );
    }

    if (isLocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(
              color: EnolaTheme.accent.withValues(alpha: 0.3), width: 2),
        ),
      );
    }

    // completed
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: radius,
        border: Border.all(
          color: const Color(0xFFE8C840).withValues(alpha: 0.6),
          width: 3.0,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 2.0)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(13)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.imageBytes != null)
                Image.memory(widget.imageBytes!, fit: BoxFit.cover)
              else
                Image.asset('assets/images/0.jpeg', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.3),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stars row ─────────────────────────────────────────────────────────────────

class _StarsRow extends StatelessWidget {
  final int stars;
  const _StarsRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 42,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(3, (i) {
          final isFilled = i < stars;
          double horizontalOffset = (i - 1) * 22.0;
          double verticalOffset   = (i == 1) ? -3.0 : 0.0;

          return Transform.translate(
            offset: Offset(horizontalOffset, verticalOffset),
            child: Icon(
              Icons.star_rounded,
              size: 42,
              color: isFilled
                  ? const Color(0xFFE8C840)
                  : const Color(0xFFE8C840).withValues(alpha: 0.2),
              shadows: isFilled
                  ? [
                      const Shadow(
                          color: Colors.white,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ]
                  : null,
            )
                .animate()
                .scale(
                  begin: Offset.zero,
                  end: const Offset(1, 1),
                  duration: 800.ms,
                  delay: (400 + (i * 100)).ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(
                  duration: 200.ms,
                  delay: (400 + (i * 100)).ms,
                ),
          );
        }),
      ),
    );
  }
}

// ── Dot connector ─────────────────────────────────────────────────────────────

class _DotConnector extends StatefulWidget {
  final bool isUnlocked;
  final bool isEvenRow;
  final int seed;
  final bool animateUnlock;

  const _DotConnector({
    super.key,
    required this.isUnlocked,
    required this.isEvenRow,
    required this.seed,
    this.animateUnlock = false,
  });

  @override
  State<_DotConnector> createState() => _DotConnectorState();
}

class _DotConnectorState extends State<_DotConnector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      // If already unlocked AND not the one being freshly animated,
      // start fully filled. If animateUnlock is true, start at 0
      // and fire the sequence immediately on first frame.
      value: (widget.isUnlocked && !widget.animateUnlock) ? 1.0 : 0.0,
    );
    _progress = CurvedAnimation(parent: _fill, curve: Curves.easeInOut);

    // SECOND: dots that were JUST unlocked animate after FIRST (~700ms)
    if (widget.isUnlocked && widget.animateUnlock) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _fill.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_DotConnector old) {
    super.didUpdateWidget(old);
    if (widget.isUnlocked && !old.isUnlocked) {
      // Newly unlocked mid-session (shouldn't normally happen but kept as fallback)
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _fill.forward();
      });
    } else if (!widget.isUnlocked && old.isUnlocked) {
      _fill.reverse();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, __) => CustomPaint(
          painter: _GridDotPainter(
            isEvenRow: widget.isEvenRow,
            baseColor: EnolaTheme.accent,
            lockedColor: EnolaTheme.accent.withValues(alpha: 0.1),
            progress: _progress.value,
            seed: widget.seed,
          ),
        ),
      ),
    );
  }
}

class _GridDotPainter extends CustomPainter {
  final bool isEvenRow;
  final Color baseColor;
  final Color lockedColor;
  final double progress;
  final int seed;

  const _GridDotPainter({
    required this.isEvenRow,
    required this.baseColor,
    required this.lockedColor,
    required this.progress,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset dot1;
    final Offset dot2;

    if (isEvenRow) {
      dot1 = Offset(size.width * 0,    size.height * 0.80);
      dot2 = Offset(size.width * 0.20, size.height * 1.0);
    } else {
      dot1 = Offset(size.width * 1.0,  size.height * 0.80);
      dot2 = Offset(size.width * 0.80, size.height * 1.0);
    }

    final random = math.Random(seed);
    double randomOpacity = 0.4 + (random.nextDouble() * 0.4);

    final paint1 = Paint()
      ..color = (progress >= 0.5)
          ? baseColor.withValues(alpha: randomOpacity)
          : lockedColor
      ..style = PaintingStyle.fill;

    randomOpacity = 0.4 + (random.nextDouble() * 0.4);
    final paint2 = Paint()
      ..color = (progress >= 1.0)
          ? baseColor.withValues(alpha: randomOpacity)
          : lockedColor
      ..style = PaintingStyle.fill;

    const double dotRadius = 8.0;
    canvas.drawCircle(dot1, dotRadius, paint1);
    canvas.drawCircle(dot2, dotRadius, paint2);
  }

  @override
  bool shouldRepaint(_GridDotPainter old) =>
      old.progress != progress || old.isEvenRow != isEvenRow;
}
