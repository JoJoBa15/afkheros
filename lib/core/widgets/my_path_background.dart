
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// --- Widget Principale ---

class MyPathBackground extends StatefulWidget {
  const MyPathBackground({super.key});

  @override
  State<MyPathBackground> createState() => _MyPathBackgroundState();
}

class _MyPathBackgroundState extends State<MyPathBackground>
    with TickerProviderStateMixin {
  static const _w = 1024.0;
  static const _h = 1536.0;

  late final AnimationController _fx;
  late final Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fx = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blend = _computeBlend(_now);
    final nightness = _nightness(_now); // 0 (giorno) -> 1 (notte)
    final mist = _mistIntensity(_now);
    final leaves = nightness < 0.8 ? 1.0 : 0.0; // No foglie di notte fonda

    return Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: _w,
          height: _h,
          child: AnimatedBuilder(
            animation: _fx,
            builder: (_, __) {
              final tFx = _fx.value;
              final tBlend = smoothstep(blend.t);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Base (giorno/notte)
                  Opacity(
                    opacity: 1 - tBlend,
                    child: Image.asset(blend.a, fit: BoxFit.fill, filterQuality: FilterQuality.none),
                  ),
                  Opacity(
                    opacity: tBlend,
                    child: Image.asset(blend.b, fit: BoxFit.fill, filterQuality: FilterQuality.none),
                  ),

                  // Effetto Foglie che cadono dagli alberi
                  if (leaves > 0.01)
                    CustomPaint(painter: LeafFallPainter(t: tFx, intensity: leaves)),

                  // Nebbia mattutina
                  if (mist > 0.001)
                    CustomPaint(painter: MistPainter(t: tFx, intensity: mist)),
                    
                  // Bagliore pulsante della lanterna
                  if (nightness > 0.001)
                    CustomPaint(painter: LanternGlowPainter(t: tFx, intensity: nightness)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- Logica Temporale ---

class _Blend {
  final String a, b;
  final double t;
  const _Blend(this.a, this.b, this.t);
}

_Blend _computeBlend(DateTime now) {
  const sunrise = 'assets/images/bg/mine_sunrise.png';
  const day = 'assets/images/bg/mine_day.png';
  const sunset = 'assets/images/bg/mine_sunset.png';
  const night = 'assets/images/bg/mine_night.png';

  final m = now.hour * 60 + now.minute;
  const sunriseStart = 6 * 60, sunriseEnd = 8 * 60;
  const sunsetStart = 17 * 60, sunsetEnd = 19 * 60;
  const nightStart = 20 * 60 + 30;

  if (m >= sunriseStart && m < sunriseEnd) {
    return _Blend(sunrise, day, (m - sunriseStart) / (sunriseEnd - sunriseStart));
  }
  if (m >= sunriseEnd && m < sunsetStart) {
    return _Blend(day, day, 0);
  }
  if (m >= sunsetStart && m < sunsetEnd) {
    return _Blend(day, sunset, (m - sunsetStart) / (sunsetEnd - sunsetStart));
  }
  if (m >= sunsetEnd && m < nightStart) {
    return _Blend(sunset, night, (m - sunsetEnd) / (nightStart - sunsetEnd));
  }
  return _Blend(night, night, 0);
}

double _nightness(DateTime now) {
  final m = now.hour * 60 + now.minute;
  const nightFrom = 18 * 60, nightTo = 22 * 60;
  return smoothstep(clamp01((m - nightFrom) / (nightTo - nightFrom)));
}

double _mistIntensity(DateTime now) {
  final m = now.hour * 60 + now.minute;
  const mistFrom = 6 * 60, mistTo = 10 * 60;
  if (m < mistFrom || m > mistTo) return 0;
  final x = 1 - (m - mistFrom) / (mistTo - mistFrom);
  return smoothstep(clamp01(x)) * 0.9;
}

// --- Painters Personalizzati ---

// NUOVO: Effetto foglie che cadono
class LeafFallPainter extends CustomPainter {
  final double t;
  final double intensity;
  final _paint = Paint()..isAntiAlias = false;

  LeafFallPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Area di spawn delle foglie (chiome degli alberi)
    final spawnArea = Rect.fromLTRB(size.width * 0.1, size.height * 0.4, size.width * 0.9, size.height * 0.6);
    const leafCount = 80;

    for (int i = 0; i < leafCount; i++) {
      final seed = i * 1337;
      final hash1 = _hash01(seed);
      final hash2 = _hash01(seed * 2);
      final hash3 = _hash01(seed * 3);
      final hash4 = _hash01(seed * 4);
      
      // Traiettoria e ciclo di vita
      final lifetime = 0.5 + hash2 * 0.5;
      final progress = (t + hash1) % lifetime / lifetime;

      // Movimento verticale (caduta) e orizzontale (vento)
      final startX = spawnArea.left + hash1 * spawnArea.width;
      final startY = spawnArea.top + hash2 * spawnArea.height;
      final wind = (hash3 - 0.5) * size.width * 0.3;
      
      final x = startX + wind * progress;
      final y = startY + progress * size.height * 0.4;
      
      // Rotazione
      final rotation = (hash4 - 0.5) * 4 * math.pi * progress;
      
      // Dimensioni e colore della foglia
      final leafW = 4.0 + hash3 * 4.0;
      final leafH = 6.0 + hash4 * 5.0;
      final opacity = (1 - progress) * 0.7 * intensity;
      
      _paint.color = Color.fromARGB((opacity * 255).round(), 130, 180, 90).withOpacity(opacity);

      // Disegna la foglia ruotata
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: leafW, height: leafH), const Radius.circular(2)),
        _paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LeafFallPainter old) => old.t != t || old.intensity != intensity;
}

// MIGLIORATO: Bagliore della lanterna più realistico
class LanternGlowPainter extends CustomPainter {
  final double t;
  final double intensity;

  LanternGlowPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final glowCenter = Offset(size.width * 0.62, size.height * 0.74);
    
    // Flicker più complesso e organico
    final flicker = 0.8 + 
                  math.sin(t * math.pi * 2 * 2.1) * 0.15 + 
                  math.sin(t * math.pi * 2 * 5.7) * 0.08 +
                  math.sin(t * math.pi * 2 * 13.3) * 0.05;
    final a = clamp01(intensity * flicker);

    final rOuter = size.width * 0.22;
    final rInner = size.width * 0.08;
    
    // Gradiente per l'aura esterna
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x00FFD08A), const Color(0xAAFFB05A), a)!,
          const Color(0x00000000),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: rOuter));

    canvas.drawCircle(glowCenter, rOuter, paint);

    // Core più piccolo e caldo per la fiamma
    final corePaint = Paint()
      ..blendMode = BlendMode.plus // 'Plus' per un effetto più luminoso
      ..color = Color.fromARGB((200 * a).round(), 255, 230, 180);
    canvas.drawCircle(glowCenter, rInner, corePaint);
  }

  @override
  bool shouldRepaint(covariant LanternGlowPainter old) => old.t != t || old.intensity != intensity;
}

class MistPainter extends CustomPainter {
  final double t, intensity;
  MistPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    final baseY = size.height * 0.42, bandH = size.height * 0.18;

    const blobs = 48;
    for (int i = 0; i < blobs; i++) {
      final p = _hash01(i * 97), q = _hash01(i * 193);
      final speed = 0.02 + 0.05 * q;
      final x = (p + t * speed) % 1.0;
      final y = baseY + (q - 0.5) * bandH * 0.55;
      final w = size.width * (0.10 + 0.18 * _hash01(i * 311));
      final h = bandH * (0.10 + 0.18 * _hash01(i * 431));
      final alpha = (18 + (55 * intensity).round());
      paint.color = Color.fromARGB(alpha, 220, 235, 255);
      canvas.drawRect(Rect.fromLTWH(x * size.width - w * 0.5, y, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MistPainter old) => old.t != t || old.intensity != intensity;
}

// --- Funzioni Utili ---

double _hash01(int n) {
  n = (n ^ 0xA3C59AC3) * 2654435761;
  n = (n ^ (n >> 16)) * 2246822519;
  n = (n ^ (n >> 13)) * 3266489917;
  n = n ^ (n >> 16);
  return (n & 0xFFFFFF) / 0xFFFFFF;
}

double smoothstep(double t) => t * t * (3 - 2 * t);
double clamp01(double x) => x.clamp(0.0, 1.0);
