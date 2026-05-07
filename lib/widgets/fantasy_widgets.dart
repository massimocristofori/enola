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
          child: Icon(Icons.auto_awesome_sharp, 
            size: 12, 
            color: EnolaTheme.accent.withValues(alpha: 0.5)
          ),
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
        fontFamily: 'Serif', 
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

/// ✅ ADDED: The card used for Map tiles and Riddle items
class ParchmentCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool glowing;

  const ParchmentCard({
    super.key, 
    required this.child, 
    this.onTap, 
    this.glowing = false
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: glowing ? 4 : 0,
      shadowColor: glowing ? EnolaTheme.accent.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: glowing ? EnolaTheme.accent : EnolaTheme.border,
          width: glowing ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// ✅ ADDED: The custom text field used in forms
class FantasyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const FantasyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: EnolaTheme.sectionHeader,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: EnolaTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: EnolaTheme.textSecond, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
