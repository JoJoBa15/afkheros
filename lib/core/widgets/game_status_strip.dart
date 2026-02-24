import 'dart:async';
import 'package:flutter/material.dart';
import '../services/battery_service.dart';

class GameStatusStrip extends StatefulWidget {
  const GameStatusStrip({super.key});

  @override
  State<GameStatusStrip> createState() => _GameStatusStripState();
}

class _GameStatusStripState extends State<GameStatusStrip> {
  Timer? _clockTimer;
  Timer? _batteryTimer;

  DateTime _now = DateTime.now();
  BatteryInfo? _battery;

  @override
  void initState() {
    super.initState();

    _syncClock();
    _syncBattery();

    // Aggiorna l’orario al cambio minuto (controllo ogni secondo ma setState solo quando cambia minuto)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.minute != _now.minute) {
        setState(() => _now = n);
      }
    });

    // Batteria: polling tranquillo (eviti EventChannel per ora)
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncBattery());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _batteryTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncBattery() async {
    final info = await BatteryService.getBatteryInfo();
    if (!mounted) return;
    setState(() => _battery = info);
  }

  void _syncClock() {
    _now = DateTime.now();
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    // viewPadding = area “fisica” occupata da cutout/gesture, anche quando status bar è nascosta
    final vp = MediaQuery.of(context).viewPadding;

    // Margine base “più centrale” + compensazione se c’è intrusione laterale
    const baseSide = 18.0;
    final left = baseSide + (vp.left > 0 ? vp.left : 0);
    final right = baseSide + (vp.right > 0 ? vp.right : 0);

    final time = _hhmm(_now);

    final level = _battery?.level;
    final charging = _battery?.isCharging ?? false;

    final icon = charging ? Icons.battery_charging_full : Icons.battery_full;
    final text = level == null ? '—%' : '$level%';

    // SafeArea top = true: spinge dentro senza sforare notch/punch-hole in alto.
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(left: left, right: right, top: 6, bottom: 6),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ) ??
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          child: Row(
            children: [
              Text(time),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.white.withOpacity(0.95)),
                  const SizedBox(width: 6),
                  Text(text),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}