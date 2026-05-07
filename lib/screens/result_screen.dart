import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:enola/theme/enola_theme.dart';
import 'package:enola/widgets/fantasy_widgets.dart';
import 'package:enola/screens/home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String mapId; // ✅ Changed from int to String
  final int correct;
  final int total;

  const ResultScreen({
    super.key,
    required this.mapId,
    required this.correct,
    required this.total,
  });

  double get _score => total == 0 ? 0 : correct / total;

  String get _rank {
    if (_score >= 0.9) return 'Grand Sage';
    if (_score >= 0.7) return 'Scholar';
    if (_score >= 0.5) return 'Apprentice';
    return 'Novice';
  }

  String get _rankEmoji {
    if (_score >= 0.9) return '👑';
    if (_score >= 0.7) return '🏆';
    if (_score >= 0.5) return '⚔️';
    return '📜';
  }

  String get _message {
    if (_score >= 0.9) return 'The oracle bows before your wisdom.';
    if (_score >= 0.7) return 'A worthy scholar walks these halls.';
    if (_score >= 0.5) return 'Your knowledge grows with each quest.';
    return 'The path to mastery begins with a single step.';
  }

  Color get _scoreColor {
    if (_score >= 0.7) return EnolaTheme.correct;
    if (_score >= 0.5) return EnolaTheme.accent;
    return EnolaTheme.wrong;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FantasyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                _buildCrest(),
                const SizedBox(height: 32),
                _buildScore(),
                const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildCrest() {
    return Column(
      children: [
        Text(
          _rankEmoji,
          style: const TextStyle(fontSize: 72),
        )
            .animate()
            .scale(
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
                color: _scoreColor.withValues(alpha: 0.2),
                blurRadius: 20,
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

  Widget _buildScore() {
    final percent = (_score * 100).round();
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: _score,
            strokeWidth: 10,
            backgroundColor: EnolaTheme.surfaceHigh, // Updated for Light Theme
            valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
            strokeCap: StrokeCap.round,
          ),
        )
            .animate()
            .custom(
              delay: 800.ms,
              duration: 1200.ms,
              curve: Curves.easeInOut,
              builder: (context, value, child) => SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: _score * value,
                  strokeWidth: 10,
                  backgroundColor: EnolaTheme.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _scoreColor,
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
            Text(
              '$correct / $total',
              style: const TextStyle(
                fontSize: 14,
                color: EnolaTheme.textSecond,
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatBox(
          icon: Icons.check_circle_rounded,
          value: '$correct',
          label: 'Correct',
          color: EnolaTheme.correct,
        ),
        const SizedBox(width: 16),
        _StatBox(
          icon: Icons.cancel_rounded,
          value: '${total - correct}',
          label: 'Wrong',
          color: EnolaTheme.wrong,
        ),
        const SizedBox(width: 16),
        _StatBox(
          icon: Icons.menu_book_rounded,
          value: '$total',
          label: 'Total',
          color: EnolaTheme.accent,
        ),
      ],
    ).animate().fadeIn(delay: 1100.ms, duration: 400.ms);
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Pop back to the PlayScreen/Detail
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play Again'),
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
            icon: const Icon(Icons.home_rounded, color: EnolaTheme.accent),
            label: const Text('Back to Maps',
                style: TextStyle(color: EnolaTheme.accent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: EnolaTheme.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
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
