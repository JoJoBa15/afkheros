import 'package:flutter/material.dart';

class PixelPanel extends StatelessWidget {
  final Widget child;

  /// Permette di “scurire” il pannello in OLED-safe, o riusarlo altrove.
  final Color? backgroundColor;
  final Color? borderColor;

  const PixelPanel({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Usa il nero assoluto di base
        color: backgroundColor ?? Colors.black, 
        borderRadius: BorderRadius.circular(16),
        // Scurisci anche i bordi per non creare stacchi netti
        border: Border.all(color: borderColor ?? const Color(0xFF1A1A1A)),
      ),
      child: child,
    );
  }
}
