import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String mapId;
  final int correct;
  final int total;
  final int totalStars;
  final int maxStars;

  const ResultScreen({
    super.key,
    required this.mapId,
    required this.correct,
    required this.total,
    required this.totalStars,
    required this.maxStars,
  });

  double get _starRatio => maxStars == 0 ? 0 : totalStars / maxStars;

  String get _rank {
    if (_starRatio >= 0.9) return 'Grand Sage';
    if (_starRatio >= 0.7) return 'Scholar';
    if (_starRatio >= 0.5) return 'Apprentice';
    return 'Novice';
  }

  String get _rankEmoji {
    if (_starRatio >= 0.9) return '👑';
    if (_starRatio >= 0.7) return '🏆';
    if (_starRatio >= 0.5) return '⚔️';
    return '📜';
  }

  String get _message {
    if (_starRatio >= 0.9) return 'The oracle bows before your wisdom.';
    if (_starRatio >= 0.7) return 'A worthy scholar walks these halls.';
    if (_starRatio >= 0.5) return 'Your knowledge grows with each quest.';
    return 'The path to mastery begins with a single step.';
  }

  Color get _scoreColor {
    if (_starRatio >= 0.9) return const Color(0xFFFFD700); 
    if (_starRatio >= 0.7) return const Color(0xFF00E676); 
    if (_starRatio >= 0.5) return const Color(0xFF00E5FF); 
    return const Color(0xFFFF9100); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FantasyBackground(
        child: Stack(
          children: [
            // Full-screen ambient sunburst rays sitting behind the content
            Positioned.fill(
              child: CustomPaint(
                painter: _ResultSunburstPainter(
                  rayCount: 24, // High density full-screen distribution
                  alphas: [0.03, 0.07, 0.02, 0.05], // Ultra-soft elegant ambient glow values
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Spacer(),
                    _buildCrest(),
                    const SizedBox(height: 28),
                    const RuneDivider(),
                    const SizedBox(height: 24),
                    _buildStats(),
                    const Spacer(),
                    _buildActions(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrest() {
    return Column(
      children: [
        Text(
          _rankEmoji,
          style: const TextStyle(fontSize: 72),
        ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 16),
        const Text(
          'Quest Complete',
          style: TextStyle(
            fontSize: 13,
            color: EnolaTheme.textSecond,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          _rank,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: _scoreColor,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: _scoreColor.withValues(alpha: 0.4), 
                blurRadius: 25,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.3, end: 0),
        const SizedBox(height: 12),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: EnolaTheme.textSecond,
            fontSize: 15,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatBox(
          icon: Icons.menu_book_rounded,
          value: '$total',
          label: 'Riddles',
          color: const Color(0xFFFF7043), 
        ),
        const SizedBox(width: 16),
        _StatBox(
          icon: Icons.star_rounded,
          value: '$totalStars',
          label: 'Stars',
          color: const Color(0xFFFFCA28), 
        ),
        const SizedBox(width: 16),
        _StatBox(
          icon: Icons.emoji_events_rounded,
          value: '${((_starRatio) * 100).round()}%',
          label: 'Score',
          color: _scoreColor, 
        ),
      ],
    ).animate().fadeIn(delay: 1000.ms, duration: 400.ms);
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _scoreColor,
              foregroundColor: Colors.black87, 
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            icon: Icon(Icons.home_rounded, color: _scoreColor),
            label: Text('Back to Maps',
                style: TextStyle(color: _scoreColor, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _scoreColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5), 
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24), 
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: EnolaTheme.textSecond,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-Screen Custom Painter ────────────────────────────────────────────────

class _ResultSunburstPainter extends CustomPainter {
  final int rayCount;
  final List<double> alphas;

  _ResultSunburstPainter({this.rayCount = 24, required this.alphas});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.sqrt(size.width * size.width + size.height * size.height);
    
    final angleStep = (2 * math.pi) / rayCount;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < rayCount; i++) {
      final alpha = alphas[i % alphas.length];
      paint.color = Colors.white.withValues(alpha: alpha);

      final startAngle = i * angleStep;
      final endAngle = startAngle + (angleStep * 0.65); 

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        )
        ..lineTo(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ResultSunburstPainter oldDelegate) {
    return oldDelegate.rayCount != rayCount || oldDelegate.alphas != alphas;
  }
}
