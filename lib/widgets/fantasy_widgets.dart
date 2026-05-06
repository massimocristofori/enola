import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:enola/theme/enola_theme.dart';

// ── Parchment Card ────────────────────────────────────────────────────────────

class ParchmentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool glowing;

  const ParchmentCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: glowing
                ? EnolaTheme.accent
                : const Color(0xFF4A3F22),
            width: glowing ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: glowing
                  ? EnolaTheme.accent.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: glowing ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Rune Divider ──────────────────────────────────────────────────────────────

class RuneDivider extends StatelessWidget {
  const RuneDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xFF4A3F22)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '✦',
            style: TextStyle(color: EnolaTheme.accent, fontSize: 12),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xFF4A3F22)),
        ),
      ],
    );
  }
}

// ── Torch Flame Painter ───────────────────────────────────────────────────────

class TorchFlame extends StatefulWidget {
  final double size;
  const TorchFlame({super.key, this.size = 24});

  @override
  State<TorchFlame> createState() => _TorchFlameState();
}

class _TorchFlameState extends State<TorchFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size * 1.4),
        painter: _FlamePainter(_ctrl.value),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double t;
  _FlamePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sway = math.sin(t * math.pi) * w * 0.15;

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFE8A020),
          const Color(0xFFE84020),
          const Color(0x00E84020),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFFE080),
          const Color(0xFFFFB020),
          const Color(0x00FFB020),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Outer flame
    final outer = Path()
      ..moveTo(w * 0.5, h)
      ..cubicTo(
        w * 0.1, h * 0.7,
        -sway, h * 0.3,
        w * 0.5 + sway * 0.5, 0,
      )
      ..cubicTo(
        w + sway, h * 0.3,
        w * 0.9, h * 0.7,
        w * 0.5, h,
      );
    canvas.drawPath(outer, outerPaint);

    // Inner flame (smaller, brighter)
    final inner = Path()
      ..moveTo(w * 0.5, h * 0.85)
      ..cubicTo(
        w * 0.25, h * 0.6,
        w * 0.3 - sway * 0.5, h * 0.35,
        w * 0.5 + sway * 0.3, h * 0.1,
      )
      ..cubicTo(
        w * 0.7 + sway * 0.3, h * 0.35,
        w * 0.75, h * 0.6,
        w * 0.5, h * 0.85,
      );
    canvas.drawPath(inner, innerPaint);
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.t != t;
}

// ── Quest Node (riddle stop on the path) ──────────────────────────────────────

enum NodeState { locked, current, completed }

class QuestNode extends StatefulWidget {
  final int index;
  final NodeState state;
  final String label;
  final RiddleNodeType type;
  final VoidCallback? onTap;

  const QuestNode({
    super.key,
    required this.index,
    required this.state,
    required this.label,
    required this.type,
    this.onTap,
  });

  @override
  State<QuestNode> createState() => _QuestNodeState();
}

enum RiddleNodeType { multipleChoice, ordering, unknown }

class _QuestNodeState extends State<QuestNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.state == NodeState.current) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QuestNode old) {
    super.didUpdateWidget(old);
    if (widget.state == NodeState.current && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.state != NodeState.current && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.state == NodeState.locked;
    final isCurrent = widget.state == NodeState.current;
    final isDone = widget.state == NodeState.completed;

    final nodeColor = isDone
        ? EnolaTheme.correct
        : isCurrent
            ? EnolaTheme.accent
            : const Color(0xFF2A2416);

    final borderColor = isDone
        ? EnolaTheme.correct
        : isCurrent
            ? EnolaTheme.accent
            : const Color(0xFF4A3F22);

    final icon = isDone
        ? Icons.check_rounded
        : isLocked
            ? Icons.lock_outline_rounded
            : _iconForType(widget.type);

    return GestureDetector(
      onTap: isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = isCurrent ? _pulse.value : 0.0;
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: EnolaTheme.accent.withValues(alpha: 0.15 + glow * 0.35),
                        blurRadius: 12 + glow * 20,
                        spreadRadius: glow * 4,
                      ),
                    ]
                  : isDone
                      ? [
                          BoxShadow(
                            color: EnolaTheme.correct.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
            ),
            child: Icon(
              icon,
              color: isLocked
                  ? const Color(0xFF4A3F22)
                  : isDone
                      ? Colors.white
                      : EnolaTheme.background,
              size: 26,
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(RiddleNodeType t) {
    return switch (t) {
      RiddleNodeType.multipleChoice => Icons.help_outline_rounded,
      RiddleNodeType.ordering => Icons.sort_rounded,
      RiddleNodeType.unknown => Icons.auto_fix_high_rounded,
    };
  }
}

// ── Path Connector (dashed line between nodes) ────────────────────────────────

class PathConnector extends StatelessWidget {
  final bool completed;
  final bool isLeft; // alternating layout

  const PathConnector({
    super.key,
    required this.completed,
    this.isLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 60),
      painter: _PathPainter(completed: completed, isLeft: isLeft),
    );
  }
}

class _PathPainter extends CustomPainter {
  final bool completed;
  final bool isLeft;
  _PathPainter({required this.completed, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = completed
          ? EnolaTheme.correct.withValues(alpha: 0.7)
          : const Color(0xFF4A3F22)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!completed) {
      paint.strokeWidth = 2;
      // Dashed
      final dashWidth = 6.0;
      final dashSpace = 5.0;
      double distance = 0;
      final path = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width / 2, size.height);
      final metric = path.computeMetrics().first;
      while (distance < metric.length) {
        final segment = metric.extractPath(
          distance,
          math.min(distance + dashWidth, metric.length),
        );
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    } else {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.completed != completed || old.isLeft != isLeft;
}

// ── Fantasy Background Painter ────────────────────────────────────────────────

class FantasyBackground extends StatelessWidget {
  final Widget child;
  const FantasyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark parchment
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                Color(0xFF1A1508),
                Color(0xFF0D0D08),
              ],
            ),
          ),
        ),
        // Subtle vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ── Enola Title Logo ──────────────────────────────────────────────────────────

class EnolaLogo extends StatelessWidget {
  final double fontSize;
  const EnolaLogo({super.key, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TorchFlame(size: 18),
        const SizedBox(width: 8),
        Text(
          'ENOLA',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: EnolaTheme.accent,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: EnolaTheme.accent.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const TorchFlame(size: 18),
      ],
    );
  }
}
