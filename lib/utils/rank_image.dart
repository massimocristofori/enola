// ── rank_image.dart ────────────────────────────────────────────────────────
// Shared helper for mapping a star-completion ratio (0.0–1.0) to the
// corresponding ranking illustration asset. Used across the app wherever a
// "rank" image needs to reflect how well a player has performed.

String rankImageForRatio(double ratio) {
  final score = (ratio * 10).round();
  if (score < 5) return 'assets/images/ranking/0.jpg';
  if (score <= 6) return 'assets/images/ranking/1.jpg';
  if (score <= 9) return 'assets/images/ranking/2.jpg';
  return 'assets/images/ranking/3.jpg';
}

String rankTitleForRatio(double ratio) {
  final score = (ratio * 10).round();
  if (score < 5) return 'Novice';
  if (score <= 6) return 'Apprentice';
  if (score <= 9) return 'Scholar';
  return 'Grand Sage';
}

String rankMessageForRatio(double ratio) {
  final score = (ratio * 10).round();
  if (score < 5) return 'The path to mastery begins with a single step.';
  if (score <= 6) return 'Your knowledge grows with each quest.';
  if (score <= 9) return 'A worthy scholar walks these halls.';
  return 'The oracle bows before your wisdom.';
}

Color rankColorForRatio(double ratio) {
  final score = (ratio * 10).round();
  if (score < 5) return const Color(0xFFFF9100);
  if (score <= 6) return const Color(0xFF00E5FF);
  if (score <= 9) return const Color(0xFF00E676);
  return const Color(0xFFFFD700);
}