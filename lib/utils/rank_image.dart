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
