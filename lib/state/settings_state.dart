import 'package:flutter/foundation.dart';

/// Come mostriamo il timer durante la sessione di focus.
enum FocusDisplayMode {
  normal,
  oledSafe,
}

/// Stato delle impostazioni utente (MVP).
/// Per ora sta solo in memoria: poi lo persistiamo (SharedPreferences) senza cambiare API.
class SettingsState extends ChangeNotifier {
  FocusDisplayMode focusDisplayMode = FocusDisplayMode.normal;

  void setFocusDisplayMode(FocusDisplayMode mode) {
    if (mode == focusDisplayMode) return;
    focusDisplayMode = mode;
    notifyListeners();
  }

  bool get isOledSafe => focusDisplayMode == FocusDisplayMode.oledSafe;
}
