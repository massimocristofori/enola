import 'package:flutter/material.dart';
import 'package:enola/theme/enola_theme.dart';

/// The standard background for all screens in the app
class FantasyBackground extends StatelessWidget {
  final Widget child;
  const FantasyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: EnolaTheme.background,
      child: child,
    );
  }
}

/// A decorative divider with a "rune" or ancient feel
class RuneDivider extends StatelessWidget {
  const RuneDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: EnolaTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.auto_awesome_sharp, size: 12, color: EnolaTheme.accent.withValues(alpha: 0.5)),
        ),
        const Expanded(child: Divider(color: EnolaTheme.border)),
      ],
    );
  }
}

/// The Enola logo text style
class EnolaLogo extends StatelessWidget {
  final double fontSize;
  const EnolaLogo({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Text(
      'ENOLA',
      style: TextStyle(
        fontFamily: 'Serif', // Use your serif font here
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        color: EnolaTheme.textPrimary,
      ),
    );
  }
}

/// A simple animated-ready flame/torch icon for empty states
class TorchFlame extends StatelessWidget {
  final double size;
  const TorchFlame({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.local_fire_department_rounded,
      size: size,
      color: EnolaTheme.accent,
    );
  }
}
