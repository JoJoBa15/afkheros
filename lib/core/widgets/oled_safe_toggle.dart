import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Toggle “figo” (animato) per attivare/disattivare la modalità OLED-safe.
/// È volutamente semplice da usare: value + onChanged.
class OledSafeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const OledSafeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: value
                    ? const _ToggleText(
                        key: ValueKey('oled_on'),
                        title: 'Timer protetto (OLED)',
                        subtitle:
                            'Schermo quasi nero + anti burn-in mentre il timer resta visibile.',
                      )
                    : const _ToggleText(
                        key: ValueKey('oled_off'),
                        title: 'Timer normale',
                        subtitle: 'Timer visibile con interfaccia standard.',
                      ),
              ),
            ),

            const SizedBox(width: 10),

            // Track + knob animati (stile “smooth”)
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 62,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? primary.withAlpha(230) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF3A3A3A)),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: primary.withAlpha(64),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : const [],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value ? Colors.black : const Color(0xFF3A3A3A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4A4A4A)),
                  ),
                  child: Icon(
                    value ? Icons.nightlight_round : Icons.wb_sunny,
                    size: 16,
                    color: value ? primary : Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ToggleText({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.2),
        ),
      ],
    );
  }
}
