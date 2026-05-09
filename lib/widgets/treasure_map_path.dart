import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enola/database/database.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/providers/map_providers.dart';

enum NodeStatus { completed, current, locked }

class TreasureMapPath extends ConsumerWidget {
  final List<Riddle> riddles;
  final String mapId;

  /// When provided the path is interactive — tapping the current node
  /// calls this callback. When null the path is in preview/read-only mode.
  final VoidCallback? onCurrentNodeTap;

  /// Override the progress shown (used during an active play session).
  /// When null the widget reads from [latestSessionProvider].
  final int? lastCompletedIndex;

  const TreasureMapPath({
    super.key,
    required this.riddles,
    required this.mapId,
    this.onCurrentNodeTap,
    this.lastCompletedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int lastCompleted;
    if (lastCompletedIndex != null) {
      lastCompleted = lastCompletedIndex!;
    } else {
      final sessionAsync = ref.watch(latestSessionProvider(mapId));
      lastCompleted = sessionAsync.valueOrNull?.lastCompletedIndex ?? -1;
    }

    return Column(
      children: List.generate(riddles.length, (index) {
        final alignment = _getAlignment(index);
        final isLast = index == riddles.length - 1;
        final isCompleted = index <= lastCompleted;
        final isCurrent = index == lastCompleted + 1;

        final status = isCompleted
            ? NodeStatus.completed
            : isCurrent
                ? NodeStatus.current
                : NodeStatus.locked;

        return Column(
          children: [
            Align(
              alignment: alignment,
              child: _RiddleNode(
                index: index + 1,
                status: status,
                onTap: isCurrent && onCurrentNodeTap != null
                    ? onCurrentNodeTap
                    : null,
              ),
            ),
            if (!isLast)
              _PathConnector(
                from: alignment,
                to: _getAlignment(index + 1),
                isUnlocked: isCompleted,
              ),
          ],
        );
      }),
    );
  }

  Alignment _getAlignment(int index) {
    const alignments = [
      Alignment.centerLeft,
      Alignment.center,
      Alignment.centerRight,
      Alignment.center,
    ];
    return alignments[index % 4];
  }
}

// ── Node ──────────────────────────────────────────────────────────────────────

class _RiddleNode extends StatefulWidget {
  final int index;
  final NodeStatus status;
  final VoidCallback? onTap;

  const _RiddleNode({required this.index, required this.status, this.onTap});

  @override
  State<_RiddleNode> createState() => _RiddleNodeState();
}

class _RiddleNodeState extends State<_RiddleNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.92,
      upperBound: 1.08,
    );
    if (widget.status == NodeStatus.current) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_RiddleNode old) {
    super.didUpdateWidget(old);
    if (widget.status == NodeStatus.current) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.status == NodeStatus.locked;
    final isCompleted = widget.status == NodeStatus.completed;
    final isCurrent = widget.status == NodeStatus.current;

    final color = isLocked ? Colors.grey.withAlpha(80) : EnolaTheme.accent;

    Widget node = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isCompleted
            ? EnolaTheme.accent
            : isLocked
                ? Colors.grey.shade200
                : EnolaTheme.background,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: isLocked
            ? []
            : [BoxShadow(color: color.withAlpha(100), blurRadius: 10)],
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '${widget.index}',
                style: TextStyle(
                  color: isLocked ? Colors.grey : EnolaTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );

    if (isCurrent) {
      node = ScaleTransition(scale: _pulse, child: node);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            if (isCurrent)
              const TorchFlame(size: 24)
            else
              const SizedBox(height: 0),
            node,
          ],
        ),
      ),
    );
  }
}

// ── Path connector ────────────────────────────────────────────────────────────

class _PathConnector extends StatefulWidget {
  final Alignment from;
  final Alignment to;
  final bool isUnlocked;

  const _PathConnector({
    required this.from,
    required this.to,
    required this.isUnlocked,
  });

  @override
  State<_PathConnector> createState() => _PathConnectorState();
}

class _PathConnectorState extends State<_PathConnector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isUnlocked ? 1.0 : 0.0,
    );
    _progress = CurvedAnimation(parent: _fill, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_PathConnector old) {
    super.didUpdateWidget(old);
    if (widget.isUnlocked && !old.isUnlocked) {
      _fill.forward();
    } else if (!widget.isUnlocked) {
      _fill.value = 0.0;
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
      height: 50,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, __) => CustomPaint(
          painter: _PathPainter(
            from: widget.from,
            to: widget.to,
            unlockedColor: EnolaTheme.accent,
            lockedColor: Colors.grey.withAlpha(50),
            progress: _progress.value,
          ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final Alignment from;
  final Alignment to;
  final Color unlockedColor;
  final Color lockedColor;
  final double progress; // 0.0 → 1.0

  _PathPainter({
    required this.from,
    required this.to,
    required this.unlockedColor,
    required this.lockedColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = ((from.x + 1) / 2 * size.width).clamp(50.0, size.width - 50.0);
    double endX = ((to.x + 1) / 2 * size.width).clamp(50.0, size.width - 50.0);

    // Draw grey base path
    final basePaint = Paint()
      ..color = lockedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final basePath = Path()
      ..moveTo(startX, 0)
      ..cubicTo(startX, size.height * 0.5, endX, size.height * 0.5, endX, size.height);

    canvas.drawPath(basePath, basePaint);

    // Draw colored fill on top, clipped to progress
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = unlockedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final metrics = basePath.computeMetrics().first;
      final filled = metrics.extractPath(0, metrics.length * progress);
      canvas.drawPath(filled, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.progress != progress;
}
