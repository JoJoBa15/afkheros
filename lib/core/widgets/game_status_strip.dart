import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
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

  // Pixel Shifting per prevenire il Burn-in su S25 (OLED)
  double _pixelShiftX = 0;
  double _pixelShiftY = 0;

  @override
  void initState() {
    super.initState();
    _syncBattery();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.minute != _now.minute) {
        if (mounted) {
          setState(() {
            _now = n;
            // Spostiamo impercettibilmente la barra ogni minuto
            final rnd = math.Random();
            _pixelShiftX = (rnd.nextDouble() * 2.0) - 1.0;
            _pixelShiftY = (rnd.nextDouble() * 2.0) - 1.0;
          });
        }
      }
    });

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

  @override
  Widget build(BuildContext context) {
    final vp = MediaQuery.of(context).viewPadding;
    final top = vp.top > 0 ? vp.top : 10.0;

    final level = _battery?.level ?? 0;
    final charging = _battery?.isCharging ?? false;

    final batteryColor = charging 
        ? const Color(0xFF00E676) 
        : (level < 20 ? const Color(0xFFFF5252) : Colors.white.withValues(alpha: 0.9));

    return Padding(
      padding: EdgeInsets.only(top: top + 4),
      child: Transform.translate(
        offset: Offset(_pixelShiftX, _pixelShiftY),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      height: 12,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    Icon(
                      charging ? Icons.bolt_rounded : _getBatteryIcon(level),
                      size: 14,
                      color: batteryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$level%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full_rounded;
    if (level > 50) return Icons.battery_6_bar_rounded;
    if (level > 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_alert_rounded;
  }
}
