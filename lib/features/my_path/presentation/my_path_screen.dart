
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
    // Scaffold funge da contenitore radice per la schermata.
    // L'uso di `extendBodyBehindAppBar` e `appBar` trasparente
    // permette al body (lo Stack) di occupare l'intera area dello schermo.
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Inseriamo l'header personalizzato qui per allinearlo correttamente
        // con la safe area superiore e lasciare il corpo dello Stack sotto.
        title: const _Header(),
      ),
      body: const Stack(
        children: [
          // 1. Sfondo dinamico che copre l'intera area.
          MyPathBackground(),
          // 2. Pulsante principale posizionato in basso al centro.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 48.0),
              child: _FocusButton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header della schermata, contiene avatar (con menu) e valute.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    // Usiamo una Row per disporre gli elementi orizzontalmente.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pulsante Popup per il menu utente.
        PopupMenuButton<int>(
          onSelected: (value) {
            // Gestisce la selezione dal menu.
            if (value == 0) {
              // Inverte la modalità OLED-safe.
              settings.setFocusDisplayMode(
                settings.isOledSafe
                    ? FocusDisplayMode.normal
                    : FocusDisplayMode.oledSafe,
              );
            }
          },
          // Stile del pulsante Popup: avatar più grande e personalizzato.
          child: const CircleAvatar(
            radius: 28, // Raggio più grande
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_outline, size: 32, color: Colors.white),
          ),
          // Costruttore degli item del menu.
          itemBuilder: (context) => [
            CheckedPopupMenuItem<int>(
              value: 0,
              checked: settings.isOledSafe,
              child: const Text('Modalità OLED-safe'),
            ),
            // Qui si possono aggiungere altri item in futuro.
            const PopupMenuDivider(),
            const PopupMenuItem<int>(
              value: 1,
              child: Text('Impostazioni'), // Esempio
            ),
          ],
        ),

        // Placeholder per le valute del giocatore.
        // TODO: Collegare ai dati reali dello stato del gioco.
        const Row(
          children: [
            Icon(Icons.shield, color: Colors.orange, size: 18),
            SizedBox(width: 4),
            Text('100', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
            Icon(Icons.star, color: Colors.yellow, size: 18),
            SizedBox(width: 4),
            Text('50', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

/// Pulsante "Concentrati!" con sfondo sfocato.
class _FocusButton extends StatelessWidget {
  const _FocusButton();

  // Mostra il selettore di durata in un pannello modale.
  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Sfondo trasparente per il blur
      builder: (_) => const _DurationPicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `ClipRRect` è necessario per applicare l'arrotondamento dei bordi
    // al `BackdropFilter`.
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          // Utilizziamo InkWell per l'effetto ripple al tocco.
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

  // Funzione per avviare la sessione di focus e chiudere il pannello.
  void _startSession(BuildContext context, Duration duration) {
    final settings = context.read<SettingsState>();
    Navigator.of(context).pop(); // Chiude il bottom sheet
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
    // Lista delle durate predefinite.
    const durations = [
      Duration(minutes: 15),
      Duration(minutes: 25),
      Duration(minutes: 45),
      Duration(minutes: 60),
    ];

    // Utilizziamo anche qui il BackdropFilter per coerenza stilistica.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
            // Griglia di pulsanti per la selezione della durata.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5, // Rapporto per pulsanti più larghi
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
                  child: Text('${d.inMinutes} minuti', style: const TextStyle(fontSize: 16)),
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
