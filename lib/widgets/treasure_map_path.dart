import 'package:flutter/material.dart';
import 'package:enola/database/database.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ensure this is present!


class TreasureMapPath extends StatelessWidget {
  final List<Riddle> riddles;

  const TreasureMapPath({super.key, required this.riddles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(riddles.length, (index) {
        final riddle = riddles[index];
        // Alternate alignment: Left, Center, Right, Center...
        final alignment = _getAlignment(index);
        final isLast = index == riddles.length - 1;

        return Column(
          children: [
            // The Riddle Node
            Align(
              alignment: alignment,
              child: _RiddleNode(
                index: index + 1,
                riddle: riddle,
              ),
            ),
            // The Path Connector (don't show after the last riddle)
            if (!isLast)
              _PathConnector(
                currentIndex: index,
                currentAlignment: alignment,
                nextAlignment: _getAlignment(index + 1),
              ),
          ],
        );
      }),
    );
  }

  Alignment _getAlignment(int index) {
    // Creates a winding S-shape pattern
    final positions = [
      Alignment.centerLeft,
      Alignment.center,
      Alignment.centerRight,
      Alignment.center,
    ];
    return positions[index % 4];
  }
}

class _RiddleNode extends StatelessWidget {
  final int index;
  final Riddle riddle;

  const _RiddleNode({required this.index, required this.riddle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: EnolaTheme.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EnolaTheme.accent.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
              border: Border.all(color: Colors.white24, width: 3),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Quest $index",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  final int currentIndex;
  final Alignment currentAlignment;
  final Alignment nextAlignment;

  const _PathConnector({
    required this.currentIndex,
    required this.currentAlignment,
    required this.nextAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      child: CustomPaint(
        painter: _PathPainter(
          from: currentAlignment,
          to: nextAlignment,
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final Alignment from;
  final Alignment to;

  _PathPainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EnolaTheme.accent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Create a dashed path effect
    final path = Path();
    
    // Calculate start and end points based on alignment
    double startX = (from.x + 1) / 2 * size.width;
    double endX = (to.x + 1) / 2 * size.width;
    
    // Adjust points so they don't start from the very edge
    startX = startX.clamp(40.0, size.width - 40.0);
    endX = endX.clamp(40.0, size.width - 40.0);

    path.moveTo(startX, 0);
    path.cubicTo(
      startX, size.height * 0.5,
      endX, size.height * 0.5,
      endX, size.height,
    );

    // Simple dashing logic
    for (double i = 0; i < 1; i += 0.1) {
      final pathMetric = path.computeMetrics().first;
      final extract = pathMetric.extractPath(
        pathMetric.length * i,
        pathMetric.length * (i + 0.05),
      );
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
