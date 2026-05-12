import 'dart:typed_data';
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
  final VoidCallback? onCurrentNodeTap;
  final int? lastCompletedIndex;
  final List<int> riddleStars; 
  final Uint8List? imageBytes;

  const TreasureMapPath({
    super.key,
    required this.riddles,
    required this.mapId,
    this.onCurrentNodeTap,
    this.lastCompletedIndex,
    this.riddleStars = const [],
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Removed ref.watch logic here to keep code concise, 
    // but ensure your session logic remains in your local implementation.
    final int lastCompleted = lastCompletedIndex ?? -1;

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

        final stars = index < riddleStars.length ? riddleStars[index] : 0;

        return Column(
          children: [
            Align(
              alignment: alignment,
              child: _RiddleNode(
                index: index + 1,
                status: status,
                stars: stars,
                imageBytes: imageBytes,
                onTap: isCurrent && onCurrentNodeTap != null
                    ? onCurrentNodeTap
                    : null,
              ),
            ),
            if (!isLast)
              _DotConnector(
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
  final int stars;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;

  const _RiddleNode({
    required this.index,
    required this.status,
    required this.stars,
    this.imageBytes,
    this.onTap,
  });

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

    Widget node = GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 110, 
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 25.0), 
              child: _buildBox(isCompleted, isCurrent, isLocked),
            ),
            if (isCompleted)
              Positioned(
                top: 0,
                child: _StarsRow(stars: widget.stars),
              ),
          ],
        ),
      ),
    );

    if (isCurrent) {
      node = ScaleTransition(scale: _pulse, child: node);
    }

    return node;
  }

  Widget _buildBox(bool isCompleted, bool isCurrent, bool isLocked) {
    const double size = 60; // Increased back to 60
    const radius = BorderRadius.all(Radius.circular(18));

    if (isCurrent) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EnolaTheme.accent,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(color: EnolaTheme.accent.withAlpha(100), blurRadius: 12),
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
            color: EnolaTheme.accent.withAlpha(80),
            width: 2,
          ),
        ),
      );
    }

    // Completed: Bolder gold border + Image with Transparent White Layer
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: radius,
        border: Border.all(
          color: const Color(0xFFE8C840),
          width: 5.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(13)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.imageBytes != null)
              Image.memory(widget.imageBytes!, fit: BoxFit.cover)
            else
              Center(
                child: Icon(
                  Icons.map_rounded,
                  color: EnolaTheme.accent.withAlpha(120),
                  size: 32,
                ),
              ),
            // Transparent white layer over the image
            Container(color: Colors.white.withOpacity(0.3)),
          ],
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
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(3, (i) {
          final isFilled = i < stars;
          final bool isMiddle = i == 1;
          
          // Positioning stars closer (offsets: -22, 0, 22)
          double horizontalOffset = (i - 1) * 22.0; 
          // Move middle star up by 3 pixels
          double verticalOffset = isMiddle ? -3.0 : 0.0;

          return Transform.translate(
            offset: Offset(horizontalOffset, verticalOffset),
            child: Icon(
              Icons.star_rounded,
              size: 42,
              color: isFilled
                  ? const Color(0xFFE8C840)
                  : const Color(0xFFE8C840).withAlpha(55),
              shadows: isFilled ? [
                const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ] : null,
            ),
          );
        }),
      ),
    );
  }
}

// ── Dot connector ─────────────────────────────────────────────────────────────

class _DotConnector extends StatefulWidget {
  final Alignment from;
  final Alignment to;
  final bool isUnlocked;

  const _DotConnector({
    required this.from,
    required this.to,
    required this.isUnlocked,
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
      duration: const Duration(milliseconds: 1200),
      value: widget.isUnlocked ? 1.0 : 0.0,
    );
    _progress = CurvedAnimation(parent: _fill, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_DotConnector old) {
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
          painter: _DotPainter(
            from: widget.from,
            to: widget.to,
            unlockedColor: EnolaTheme.accent,
            lockedColor: EnolaTheme.accent.withAlpha(55),
            progress: _progress.value,
            dotCount: 3,
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final Alignment from;
  final Alignment to;
  final Color unlockedColor;
  final Color lockedColor;
  final double progress;
  final int dotCount;

  const _DotPainter({
    required this.from,
    required this.to,
    required this.unlockedColor,
    required this.lockedColor,
    required this.progress,
    required this.dotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startX = ((from.x + 1) / 2 * size.width).clamp(50.0, size.width - 50.0);
    final endX = ((to.x + 1) / 2 * size.width).clamp(50.0, size.width - 50.0);

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(startX, size.height * 0.5, endX, size.height * 0.5, endX, size.height);

    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    for (int i = 1; i <= dotCount; i++) {
      final t = i / (dotCount + 1);
      final tangent = metrics.getTangentForOffset(totalLength * t);
      if (tangent == null) continue;

      final isLit = t <= progress;
      final paint = Paint()
        ..color = isLit ? unlockedColor : lockedColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tangent.position, 7, paint);
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}
