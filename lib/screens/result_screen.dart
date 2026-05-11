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

  //double get _score => total == 0 ? 0 : correct / total;
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
    if (_starRatio >= 0.7) return EnolaTheme.correct;
    if (_starRatio >= 0.5) return EnolaTheme.accent;
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
                const SizedBox(height: 28),
                _buildStarSummary(),
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
            shadows: const [
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

  // ── Compact star summary ───────────────────────────────────────────────────

  Widget _buildStarSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: EnolaTheme.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated star icon
          const Icon(Icons.star_rounded, color: EnolaTheme.accent, size: 32)
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
                delay: 700.ms,
              ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big number
              Text(
                '$totalStars / $maxStars',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _scoreColor,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
              // Progress bar
              const SizedBox(height: 6),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _starRatio,
                    minHeight: 6,
                    backgroundColor: EnolaTheme.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_scoreColor),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms),
              const SizedBox(height: 4),
              Text(
                'stars collected',
                style: const TextStyle(
                  fontSize: 11,
                  color: EnolaTheme.textSecond,
                ),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
          delay: 700.ms,
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
          color: EnolaTheme.accent,
        ),
        const SizedBox(width: 16),
        _StatBox(
          icon: Icons.star_rounded,
          value: '$totalStars',
          label: 'Stars',
          color: EnolaTheme.correct,
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
