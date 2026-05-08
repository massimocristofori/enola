import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';

enum NodeStatus { completed, current, locked }

class TreasureMapPath extends ConsumerWidget {
  final List<Riddle> riddles;
  final String mapId;

  const TreasureMapPath({super.key, required this.riddles, required this.mapId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(latestSessionProvider(mapId));
    final lastCompleted = sessionAsync.valueOrNull?.lastCompletedIndex ?? -1;

    return Column(
      children: List.generate(riddles.length, (index) {
        final alignment = _getAlignment(index);
        final isLast = index == riddles.length - 1;

        final isCompleted = index <= lastCompleted;
        final isCurrent = index == lastCompleted + 1;
        final isLocked = index > lastCompleted + 1;

        return Column(
          children: [
            Align(
              alignment: alignment,
              child: _RiddleNode(
                index: index + 1,
                status: isCompleted ? NodeStatus.completed : (isCurrent ? NodeStatus.current : NodeStatus.locked),
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
    const alignments = [Alignment.centerLeft, Alignment.center, Alignment.centerRight, Alignment.center];
    return alignments[index % 4];
  }
}

class _RiddleNode extends StatelessWidget {
  final int index;
  final NodeStatus status;

  const _RiddleNode({required this.index, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == NodeStatus.locked ? Colors.grey.withOpacity(0.3) : EnolaTheme.accent;
    
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          if (status == NodeStatus.current) const TorchFlame(size: 24),
          Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
              color: status == NodeStatus.locked ? Colors.grey.shade900 : EnolaTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: status == NodeStatus.locked ? [] : [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
            ),
            child: Center(
              child: status == NodeStatus.completed 
                ? Icon(Icons.check, color: color, size: 20)
                : Text('$index', style: TextStyle(color: status == NodeStatus.locked ? Colors.grey : EnolaTheme.textPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  final Alignment from;
  final Alignment to;
  final bool isUnlocked;

  const _PathConnector({required this.from, required this.to, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: CustomPaint(painter: _PathPainter(from: from, to: to, color: isUnlocked ? EnolaTheme.accent : Colors.grey.withOpacity(0.2))),
    );
  }
}

class _PathPainter extends CustomPainter {
  final Alignment from; final Alignment to; final Color color;
  _PathPainter({required this.from, required this.to, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    final path = Path();
    double startX = (from.x + 1) / 2 * size.width;
    double endX = (to.x + 1) / 2 * size.width;
    startX = startX.clamp(50.0, size.width - 50.0);
    endX = endX.clamp(50.0, size.width - 50.0);
    path.moveTo(startX, 0);
    path.cubicTo(startX, size.height * 0.5, endX, size.height * 0.5, endX, size.height);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
