import 'package:flutter/material.dart';
import 'package:enola/theme/enola_theme.dart';

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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: EnolaTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class ParchmentCard extends StatelessWidget {
  final Widget child;
  final bool glowing;
  const ParchmentCard({super.key, required this.child, this.glowing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowing ? EnolaTheme.accent : EnolaTheme.border),
        boxShadow: [
          BoxShadow(
            color: EnolaTheme.accent.withValues(alpha: glowing ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
