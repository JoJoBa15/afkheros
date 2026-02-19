import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/my_path_background.dart';
import '../../../state/settings_state.dart';
import 'focus_session_screen.dart';

class MyPathScreen extends StatelessWidget {
  const MyPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // Sfondo dinamico che deve coprire tutta l’area (anche dietro l’header).
        MyPathBackground(),

        // Pulsante principale
        Align(
          alignment: Alignment.center,
          child: _FocusButton(),
        ),
      ],
    );
  }
}

/// Pulsante "Concentrati!" con sfondo sfocato.
class _FocusButton extends StatelessWidget {
  const _FocusButton();

  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DurationPicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: () => _showDurationPicker(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Concentrati!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pannello modale per la selezione della durata della sessione.
class _DurationPicker extends StatelessWidget {
  const _DurationPicker();

  void _startSession(BuildContext context, Duration duration) {
    final settings = context.read<SettingsState>();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(
          duration: duration,
          displayMode: settings.focusDisplayMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const durations = [
      Duration(minutes: 15),
      Duration(minutes: 25),
      Duration(minutes: 45),
      Duration(minutes: 60),
    ];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Per quanto tempo?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: durations.map((d) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _startSession(context, d),
                  child: Text('${d.inMinutes} minuti',
                      style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
