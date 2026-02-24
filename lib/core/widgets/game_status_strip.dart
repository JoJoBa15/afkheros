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
    _syncBattery();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.minute != _now.minute) setState(() => _now = n);
    });

    _batteryTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _syncBattery());
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

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final vp = MediaQuery.of(context).viewPadding;

    // ✅ altezza della “status bar” reale
    final top = vp.top;

    // ✅ più respiro ai lati
    final w = MediaQuery.of(context).size.width;
    final baseSide = (w * 0.055).clamp(18.0, 28.0); // 5.5% dello schermo
    final left = baseSide + (vp.left > 0 ? vp.left : 0);
    final right = baseSide + (vp.right > 0 ? vp.right : 0);

    final time = _hhmm(_now);

    final level = _battery?.level;
    final charging = _battery?.isCharging ?? false;

    final icon = charging ? Icons.battery_charging_full : Icons.battery_full;
    final text = level == null ? '—%' : '$level%';

    // ✅ “più in alto” ottico: spostiamo su di ~1.5px
    final lift = -(top * 0.35).clamp(6.0, 14.0);

    return SizedBox(
      height: top,
      child: Padding(
        padding: EdgeInsets.only(left: left, right: right),
        child: Transform.translate(
          offset: Offset(0, lift),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}