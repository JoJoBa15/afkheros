import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

/// MyPathBackground:
/// - Sky gradient che cambia in base all'orario (transizioni morbide)
/// - Blob sfocati (aurora) per dare profondità
/// - Granatura/film grain leggera (procedurale, no asset)
/// - Sole/Luna su traiettoria che dipende dall'orario
/// - Stelle di notte
/// - Nuvole pixel (3 layer parallax, loop infinito) da PNG in assets/images/clouds/
/// - Background “mine_*.png” con crossfade (sunrise/day/sunset/night)
///
/// Nota assets consigliati in pubspec.yaml:
/// flutter:
///   assets:
///     - assets/images/bg/
///     - assets/images/clouds/
class MyPathBackground extends StatefulWidget {
  final double parallaxOffset;

  const MyPathBackground({
    super.key,
    this.parallaxOffset = 0,
  });

  @override
  State<MyPathBackground> createState() => _MyPathBackgroundState();
}

class _MyPathBackgroundState extends State<MyPathBackground>
    with SingleTickerProviderStateMixin {
  // Canvas “fisso” (poi cover sul device)
  static const double _w = 1024;
  static const double _h = 1536;

  late final AnimationController _anim;
  late final Timer _clock;

  DateTime _now = DateTime.now();

  // ✅ Metti qui i tuoi nomi file reali (AI clouds).
  // Se alcuni non esistono ancora, non crasha: semplicemente non si vedranno.
  static const List<String> _cloudAssets = [
    'assets/images/clouds/cloud_01.png',
    'assets/images/clouds/cloud_02.png',
    'assets/images/clouds/cloud_03.png',
    'assets/images/clouds/cloud_04.png',
    'assets/images/clouds/cloud_05.png',
    'assets/images/clouds/cloud_06.png',
    'assets/images/clouds/cloud_07.png',
    'assets/images/clouds/cloud_08.png',
  ];

  late final List<_CloudSprite> _farClouds;
  late final List<_CloudSprite> _midClouds;
  late final List<_CloudSprite> _nearClouds;

  @override
  void initState() {
    super.initState();

    _farClouds = _genClouds(
      count: 6,
      seed: 11,
      yMin: 0.06,
      yMax: 0.18,
      speedMin: 0.004,
      speedMax: 0.010,
      scaleMin: 0.65,
      scaleMax: 1.05,
    );

    _midClouds = _genClouds(
      count: 5,
      seed: 23,
      yMin: 0.14,
      yMax: 0.28,
      speedMin: 0.008,
      speedMax: 0.016,
      scaleMin: 0.80,
      scaleMax: 1.25,
    );

    _nearClouds = _genClouds(
      count: 4,
      seed: 37,
      yMin: 0.22,
      yMax: 0.40,
      speedMin: 0.012,
      speedMax: 0.024,
      scaleMin: 0.95,
      scaleMax: 1.55,
    );

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();

    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _anim.dispose();
    super.dispose();
  }

  List<_CloudSprite> _genClouds({
    required int count,
    required int seed,
    required double yMin,
    required double yMax,
    required double speedMin,
    required double speedMax,
    required double scaleMin,
    required double scaleMax,
  }) {
    final rnd = _Seeded(seed);
    final assetsCount = _cloudAssets.isEmpty ? 1 : _cloudAssets.length;

    return List.generate(count, (i) {
      final assetIndex =
          (rnd.nextDouble() * assetsCount).floor().clamp(0, assetsCount - 1);

      return _CloudSprite(
        assetIndex: assetIndex,
        x: rnd.nextDouble(), // 0..1
        y: yMin + rnd.nextDouble() * (yMax - yMin),
        speed: lerpDouble(speedMin, speedMax, rnd.nextDouble())!,
        scale: lerpDouble(scaleMin, scaleMax, rnd.nextDouble())!,
        wobble: lerpDouble(0.6, 1.4, rnd.nextDouble())!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sky = _skyState(_now);
    final mine = _computeMineBlend(_now);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          child: RepaintBoundary(
            child: SizedBox(
              width: _w,
              height: _h,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final t = _anim.value;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // SKY (gradient + blur blobs + grain + stars)
                      CustomPaint(
                        painter: _SkyPainter(
                          sky: sky,
                          now: _now,
                          t: t,
                        ),
                      ),

                      // SUN / MOON (time-based path)
                      CustomPaint(
                        painter: _SunMoonPainter(
                          sky: sky,
                          now: _now,
                          t: t,
                          parallax: widget.parallaxOffset,
                        ),
                      ),

                      // CLOUDS (3 layers)
                      _PixelCloudLayer(
                        t: t,
                        parallax: widget.parallaxOffset,
                        sky: sky,
                        depth: 0.35,
                        clouds: _farClouds,
                        assets: _cloudAssets,
                        baseOpacity: 0.38,
                      ),
                      _PixelCloudLayer(
                        t: t,
                        parallax: widget.parallaxOffset,
                        sky: sky,
                        depth: 0.65,
                        clouds: _midClouds,
                        assets: _cloudAssets,
                        baseOpacity: 0.52,
                      ),
                      _PixelCloudLayer(
                        t: t,
                        parallax: widget.parallaxOffset,
                        sky: sky,
                        depth: 1.00,
                        clouds: _nearClouds,
                        assets: _cloudAssets,
                        baseOpacity: 0.64,
                      ),

                      // MINE BACKGROUND (crossfade)
                      Opacity(
                        opacity: 1.0 - smoothstep(mine.t),
                        child: _SafeAsset(path: mine.a, fallback: mine.b),
                      ),
                      Opacity(
                        opacity: smoothstep(mine.t),
                        child: _SafeAsset(path: mine.b, fallback: mine.a),
                      ),

                      // Top vignette (focus)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                _op(Colors.black, 0.10 + 0.18 * sky.night),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SKY
// ============================================================================

class _SkyState {
  final Color top;
  final Color bottom;

  /// 0..1
  final double night;

  /// 0..1
  final double day;

  /// 0..1 (alto in alba/tramonto)
  final double twilight;

  /// 0..1
  final double sunAlpha;

  const _SkyState({
    required this.top,
    required this.bottom,
    required this.night,
    required this.day,
    required this.twilight,
    required this.sunAlpha,
  });
}

_SkyState _skyState(DateTime now) {
  // Palettes
  const nightTop = Color(0xFF0A0F24);
  const nightBottom = Color(0xFF121834);

  const sunriseTop = Color(0xFF2C2D6D);
  const sunriseBottom = Color(0xFFFFB07A);

  const dayTop = Color(0xFF3E99FF);
  const dayBottom = Color(0xFFBDEAFF);

  const sunsetTop = Color(0xFF352A6A);
  const sunsetBottom = Color(0xFFFF7A62);

  final m = now.hour * 60 + now.minute;

  // Key time windows (minutes)
  const tNightToSunrise0 = 5 * 60 + 30; // 05:30
  const tNightToSunrise1 = 7 * 60 + 30; // 07:30

  const tSunriseToDay0 = 7 * 60 + 30; // 07:30
  const tSunriseToDay1 = 9 * 60; // 09:00

  const tDayStable1 = 17 * 60; // 17:00

  const tDayToSunset0 = 17 * 60; // 17:00
  const tDayToSunset1 = 18 * 60 + 45; // 18:45

  const tSunsetToNight0 = 18 * 60 + 45; // 18:45
  const tSunsetToNight1 = 20 * 60 + 15; // 20:15

  Color top;
  Color bottom;

  if (m < tNightToSunrise0) {
    top = nightTop;
    bottom = nightBottom;
  } else if (m < tNightToSunrise1) {
    final u = smoothstep(
      (m - tNightToSunrise0) / (tNightToSunrise1 - tNightToSunrise0),
    );
    top = Color.lerp(nightTop, sunriseTop, u)!;
    bottom = Color.lerp(nightBottom, sunriseBottom, u)!;
  } else if (m < tSunriseToDay1) {
    final u = smoothstep(
      (m - tSunriseToDay0) / (tSunriseToDay1 - tSunriseToDay0),
    );
    top = Color.lerp(sunriseTop, dayTop, u)!;
    bottom = Color.lerp(sunriseBottom, dayBottom, u)!;
  } else if (m < tDayStable1) {
    top = dayTop;
    bottom = dayBottom;
  } else if (m < tDayToSunset1) {
    final u = smoothstep(
      (m - tDayToSunset0) / (tDayToSunset1 - tDayToSunset0),
    );
    top = Color.lerp(dayTop, sunsetTop, u)!;
    bottom = Color.lerp(dayBottom, sunsetBottom, u)!;
  } else if (m < tSunsetToNight1) {
    final u = smoothstep(
      (m - tSunsetToNight0) / (tSunsetToNight1 - tSunsetToNight0),
    );
    top = Color.lerp(sunsetTop, nightTop, u)!;
    bottom = Color.lerp(sunsetBottom, nightBottom, u)!;
  } else {
    top = nightTop;
    bottom = nightBottom;
  }

  final night = _nightness(now);
  final day = (1.0 - night).clamp(0.0, 1.0);

  // “twilight”: alto a metà tra notte/giorno (alba e tramonto)
  final twilight = (1.0 - (day - 0.5).abs() * 2).clamp(0.0, 1.0);

  final sunAlpha = (day * 0.95).clamp(0.0, 1.0);

  return _SkyState(
    top: top,
    bottom: bottom,
    night: night,
    day: day,
    twilight: twilight,
    sunAlpha: sunAlpha,
  );
}

class _SkyPainter extends CustomPainter {
  final _SkyState sky;
  final DateTime now;
  final double t;

  _SkyPainter({
    required this.sky,
    required this.now,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ------------------------------------------------------------
    // 1) GRADIENT (4 stop) + micro lift -> meno banding
    // ------------------------------------------------------------
    final mid1 = _lift(Color.lerp(sky.top, sky.bottom, 0.38)!, 0.08 * sky.twilight);
    final mid2 = _lift(Color.lerp(sky.top, sky.bottom, 0.72)!, 0.05 * sky.twilight);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(0, -1),
          end: const Alignment(0, 1),
          stops: const [0.0, 0.45, 0.78, 1.0],
          colors: [sky.top, mid1, mid2, sky.bottom],
        ).createShader(rect),
    );

    // ------------------------------------------------------------
    // 2) BLUR BLOBS (aurora) — più morbidi e meno invadenti
    // ------------------------------------------------------------
    final blurSigma = lerpDouble(18, 52, sky.twilight) ?? 34;
    final blobAlphaBase = (0.06 + 0.18 * sky.twilight).clamp(0.05, 0.22);

    final warm = Color.lerp(const Color(0xFFFFB86B), sky.bottom, 0.35)!;
    final cool = Color.lerp(const Color(0xFF64D2FF), sky.top, 0.45)!;

    canvas.saveLayer(
      rect,
      Paint()..imageFilter = ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
    );

    _blob(
      canvas,
      center: Offset(
        size.width * (0.18 + 0.02 * math.sin(t * math.pi * 2)),
        size.height * (0.18 + 0.02 * math.cos(t * math.pi * 2)),
      ),
      radius: size.width * 0.46,
      color: cool,
      opacity: blobAlphaBase * (0.85 - 0.25 * sky.night),
    );

    _blob(
      canvas,
      center: Offset(
        size.width * (0.86 - 0.02 * math.sin(t * math.pi * 2)),
        size.height * (0.22 + 0.02 * math.sin(t * math.pi * 2)),
      ),
      radius: size.width * 0.40,
      color: warm,
      opacity: blobAlphaBase,
    );

    _blob(
      canvas,
      center: Offset(
        size.width * (0.52 + 0.015 * math.sin(t * math.pi * 4)),
        size.height * 0.92,
      ),
      radius: size.width * 0.52,
      color: cool,
      opacity: blobAlphaBase * 0.65,
    );

    canvas.restore();

    // Glow all’orizzonte (alba/tramonto)
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: const Alignment(0, 0.30),
          colors: [
            _op(warm, 0.05 + 0.30 * sky.twilight),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // ------------------------------------------------------------
    // 3) STELLE (stabili, niente pop-in/out)
    // ------------------------------------------------------------
    if (sky.night > 0.10) {
      _drawStars(canvas, size);
    }

    // ------------------------------------------------------------
    // 4) GRAIN / DITHER (soft) — elimina banding senza pixel-morti
    //    (pattern stabile + micro shimmer, NO random reset)
    // ------------------------------------------------------------
    _drawSoftGrain(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    // Anti "pixel morti": varie dimensioni e qualche star “soft”.
    final count = 110;
    final nightA = sky.night.clamp(0.0, 1.0);

    for (int i = 0; i < count; i++) {
      final x = _hash01(i * 991) * size.width;
      final y = _hash01(i * 773) * (size.height * 0.55);

      // Dimensione: la maggior parte 1px, qualcuna 2px, poche 3px (soft)
      final rPick = _hash01(i * 313);
      final r = (rPick < 0.08)
          ? 1.6
          : (rPick < 0.28)
              ? 1.2
              : 0.9;

      // Twinkle dolce: +/- 8% max, mai a zero
      final phase = _hash01(i * 101) * math.pi * 2;
      final speed = 0.15 + 0.35 * _hash01(i * 17);
      final tw = 0.92 + 0.08 * math.sin((t * math.pi * 2 * speed) + phase);

      final base = 0.10 + 0.18 * _hash01(i * 29); // 0.10..0.28
      final alpha = (255 * (base * nightA * tw)).round().clamp(0, 95);

      // leggermente bluastre, più “cielo”
      final col = Color.fromARGB(alpha, 220, 235, 255);

      if (r >= 1.4) {
        // star “soft” (cerchietto) per evitare puntini da pixel morto
        final paint = Paint()
          ..isAntiAlias = true
          ..color = col;
        canvas.drawCircle(Offset(x, y), r, paint);

        // micro glow
        final glow = Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            colors: [
              _op(col, 0.22),
              const Color(0x00000000),
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r * 4));
        canvas.drawCircle(Offset(x, y), r * 4, glow);
      } else {
        // star piccola (1px) ma NON aggressiva
        final p = Paint()..color = col;
        canvas.drawRect(Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), 1, 1), p);
      }
    }
  }

  void _drawSoftGrain(Canvas canvas, Size size) {
    // Grain morbido: pattern stabile + shimmer dolce
    final intensity = (0.010 + 0.020 * sky.night + 0.012 * sky.twilight).clamp(0.008, 0.045);

    // Leggerissimo blur per NON sembrare pixel morti
    final rect = Offset.zero & size;
    canvas.saveLayer(
      rect,
      Paint()..imageFilter = ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
    );

    final paint = Paint()..blendMode = BlendMode.softLight;

    // Numero specks: abbastanza per dithering, ma non pesante
    const specks = 520;

    for (int i = 0; i < specks; i++) {
      final x = _hash01(i * 1993) * size.width;
      final y = _hash01(i * 991) * size.height;

      // shimmer dolce: mai ON/OFF
      final phase = _hash01(i * 41) * math.pi * 2;
      final tw = 0.85 + 0.15 * math.sin(t * math.pi * 2 * (0.20 + 0.30 * _hash01(i * 73)) + phase);

      final isWhite = _hash01(i * 37) > 0.5;
      final a = (intensity * tw).clamp(0.0, 1.0);

      paint.color = _op(isWhite ? Colors.white : Colors.black, a);

      final s = (_hash01(i * 19) > 0.92) ? 2.0 : 1.0;
      canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
    }

    canvas.restore();
  }

  void _blob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          _op(color, opacity),
          color.withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  Color _lift(Color c, double amount) => Color.lerp(c, Colors.white, amount.clamp(0.0, 0.20))!;

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) {
    return oldDelegate.sky.top != sky.top ||
        oldDelegate.sky.bottom != sky.bottom ||
        oldDelegate.sky.night != sky.night ||
        oldDelegate.sky.twilight != sky.twilight ||
        oldDelegate.t != t ||
        oldDelegate.now.minute != now.minute;
  }
}

// ============================================================================
// SUN / MOON (time-based path)
// ============================================================================

class _SunMoonPainter extends CustomPainter {
  final _SkyState sky;
  final DateTime now;
  final double t;
  final double parallax;

  _SunMoonPainter({
    required this.sky,
    required this.now,
    required this.t,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final m = now.hour * 60 + now.minute;

    const sunStart = 6 * 60;  // 06:00
    const sunEnd = 19 * 60;   // 19:00

    final isDay = m >= sunStart && m <= sunEnd && sky.day > 0.10;

    if (isDay) {
      final p = ((m - sunStart) / (sunEnd - sunStart)).clamp(0.0, 1.0);
      final c = _arcPos(size, p, isMoon: false).translate(parallax * -6, parallax * 5);

      // r leggermente variabile (respira ma poco)
      final pulse = 0.995 + 0.005 * math.sin(t * math.pi * 2 * 1.4);
      final r = size.width * 0.040 * pulse;

      // più caldo ad alba/tramonto
      final noonFactor = (1.0 - (p - 0.5).abs() * 2).clamp(0.0, 1.0);
      final warmth = (1.0 - noonFactor).clamp(0.0, 1.0);

      final sunCore = Color.lerp(const Color(0xFFFFE7B6), const Color(0xFFFFD08A), 0.65)!;
      final sunEdge = Color.lerp(const Color(0xFFFFC06A), const Color(0xFFFF9B55), warmth)!;

      // Corona grande (glow)
      final corona = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          stops: const [0.0, 0.35, 1.0],
          colors: [
            _op(sunEdge, 0.18 * sky.sunAlpha),
            _op(sunEdge, 0.08 * sky.sunAlpha),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 7));
      canvas.drawCircle(c, r * 7, corona);

      // Disco (gradiente) — evita “pallina piatta”
      final disk = Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          stops: const [0.0, 0.60, 1.0],
          colors: [
            _op(sunCore, 0.95 * sky.sunAlpha),
            _op(Color.lerp(sunCore, sunEdge, 0.55)!, 0.95 * sky.sunAlpha),
            _op(sunEdge, 0.95 * sky.sunAlpha),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, disk);

      // Specular highlight (piccolo, elegante)
      final hi = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            _op(Colors.white, 0.18 * sky.sunAlpha),
            const Color(0x00000000),
          ],
        ).createShader(
          Rect.fromCircle(
            center: c.translate(-r * 0.25, -r * 0.30),
            radius: r * 1.1,
          ),
        );
      canvas.drawCircle(c.translate(-r * 0.25, -r * 0.30), r * 0.9, hi);
    } else {
      // Moon — più soft, meno “pallina”
      final totalNight = (24 * 60 - sunEnd) + sunStart;
      final afterSunset = (m >= sunEnd) ? (m - sunEnd) : (m + (24 * 60 - sunEnd));
      final p = (afterSunset / totalNight).clamp(0.0, 1.0);

      final c = _arcPos(size, p, isMoon: true).translate(parallax * 4, parallax * 6);
      final r = size.width * 0.030;

      final moonA = (0.55 + 0.45 * sky.night).clamp(0.0, 1.0);

      final glow = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            Color.fromARGB((65 * sky.night).round(), 205, 230, 255),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 6));
      canvas.drawCircle(c, r * 6, glow);

      final disk = Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          stops: const [0.0, 0.75, 1.0],
          colors: [
            _op(const Color(0xFFEAF4FF), 0.65 * moonA),
            _op(const Color(0xFFCFE4FF), 0.55 * moonA),
            _op(const Color(0xFFB7D2F5), 0.48 * moonA),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, disk);

      // Crescent cut
      canvas.drawCircle(
        c.translate(r * 0.35, -r * 0.10),
        r * 0.95,
        Paint()..color = _op(sky.top, 0.50),
      );
    }
  }

  Offset _arcPos(Size size, double p, {required bool isMoon}) {
    final x = lerpDouble(size.width * 0.12, size.width * 0.88, p)!;
    final amp = isMoon ? 0.24 : 0.30;
    final baseY = isMoon ? 0.30 : 0.25;
    final y = size.height * (baseY + (1 - math.sin(math.pi * p)) * amp);

    // drift micro (non “balla”)
    final driftX = math.sin(t * math.pi * 2) * (isMoon ? 0.6 : 0.4);
    final driftY = math.cos(t * math.pi * 2) * (isMoon ? 0.4 : 0.6);

    return Offset(x + driftX, y + driftY);
  }

  @override
  bool shouldRepaint(covariant _SunMoonPainter oldDelegate) {
    return oldDelegate.sky.day != sky.day ||
        oldDelegate.sky.night != sky.night ||
        oldDelegate.parallax != parallax ||
        oldDelegate.t != t ||
        oldDelegate.now.minute != now.minute;
  }
}

// ============================================================================
// CLOUDS (pixel layer)
// ============================================================================

class _CloudSprite {
  final int assetIndex;
  final double x; // 0..1
  final double y; // 0..1
  final double speed;
  final double scale;
  final double wobble;

  const _CloudSprite({
    required this.assetIndex,
    required this.x,
    required this.y,
    required this.speed,
    required this.scale,
    required this.wobble,
  });
}

class _PixelCloudLayer extends StatelessWidget {
  final double t;
  final double parallax;
  final _SkyState sky;
  final double depth;
  final List<_CloudSprite> clouds;
  final List<String> assets;
  final double baseOpacity;

  const _PixelCloudLayer({
    required this.t,
    required this.parallax,
    required this.sky,
    required this.depth,
    required this.clouds,
    required this.assets,
    required this.baseOpacity,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty || clouds.isEmpty) return const SizedBox.shrink();

    // Night makes clouds less visible
    final layerOpacity = (baseOpacity * (1.0 - 0.55 * sky.night)).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Opacity(
        opacity: layerOpacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final c in clouds) _cloudWidget(c),
          ],
        ),
      ),
    );
  }

  Widget _cloudWidget(_CloudSprite c) {
    final path = assets[c.assetIndex.clamp(0, assets.length - 1)];

    // Horizontal loop (0..1)
    final u = (c.x + t * c.speed) % 1.0;

    final dx = (u * 1024) + parallax * -10 * depth;
    final dy = (c.y * 1536) + math.sin(t * math.pi * 2 * c.wobble) * (4 * depth);

    return Positioned(
      left: dx - 200,
      top: dy,
      child: Transform.scale(
        scale: c.scale,
        child: _SafeAsset(
          path: path,
          fallback: path,
          width: 420,
          height: 240,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

// ============================================================================
// MINE BACKGROUND (crossfade)
// ============================================================================

class _MineBlend {
  final String a;
  final String b;
  final double t; // 0..1
  const _MineBlend(this.a, this.b, this.t);
}

_MineBlend _computeMineBlend(DateTime now) {
  const night = 'assets/images/bg/mine_night.png';
  const sunrise = 'assets/images/bg/mine_sunrise.png';
  const day = 'assets/images/bg/mine_day.png';
  const sunset = 'assets/images/bg/mine_sunset.png';

  final m = now.hour * 60 + now.minute;

  const dawn0 = 5 * 60 + 30; // 05:30
  const dawn1 = 8 * 60; // 08:00
  const dusk0 = 16 * 60 + 45; // 16:45
  const dusk1 = 19 * 60; // 19:00
  const night0 = 19 * 60; // 19:00
  const night1 = 21 * 60; // 21:00

  if (m < dawn0) return const _MineBlend(night, night, 0);
  if (m < dawn1) {
    final u = smoothstep((m - dawn0) / (dawn1 - dawn0));
    return _MineBlend(night, sunrise, u);
  }
  if (m < dusk0) return const _MineBlend(day, day, 0);
  if (m < dusk1) {
    final u = smoothstep((m - dusk0) / (dusk1 - dusk0));
    return _MineBlend(day, sunset, u);
  }
  if (m < night1) {
    final u = smoothstep((m - night0) / (night1 - night0));
    return _MineBlend(sunset, night, u);
  }
  return const _MineBlend(night, night, 0);
}

// ============================================================================
// SAFE ASSET
// ============================================================================

class _SafeAsset extends StatelessWidget {
  final String path;
  final String fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  // ✅ non-nullable con default
  final FilterQuality filterQuality;

  const _SafeAsset({
    required this.path,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.low, // default sensato
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stackTrace) {
        if (fallback == path) return const SizedBox.shrink();
        return Image.asset(
          fallback,
          width: width,
          height: height,
          fit: fit,
          filterQuality: filterQuality,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      },
    );
  }
}

// ============================================================================
// UTILS
// ============================================================================

double smoothstep(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _nightness(DateTime now) {
  final m = now.hour * 60 + now.minute;

  const dawn0 = 5 * 60 + 30; // 05:30
  const dawn1 = 7 * 60 + 30; // 07:30
  const dusk0 = 18 * 60 + 45; // 18:45
  const dusk1 = 20 * 60 + 15; // 20:15

  if (m < dawn0) return 1.0;
  if (m < dawn1) {
    final u = smoothstep((m - dawn0) / (dawn1 - dawn0));
    return 1.0 - u;
  }
  if (m < dusk0) return 0.0;
  if (m < dusk1) {
    final u = smoothstep((m - dusk0) / (dusk1 - dusk0));
    return u;
  }
  return 1.0;
}

Color _op(Color c, double opacity) {
  final o = opacity.clamp(0.0, 1.0);
  return c.withAlpha((o * 255).round());
}

double _hash01(int x) {
  var v = x;
  v = (v ^ 61) ^ (v >> 16);
  v = v + (v << 3);
  v = v ^ (v >> 4);
  v = v * 0x27d4eb2d;
  v = v ^ (v >> 15);
  final u = v & 0x7fffffff;
  return (u % 100000) / 100000.0;
}

class _Seeded {
  int _state;
  _Seeded(int seed) : _state = seed;

  double nextDouble() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return (_state % 100000) / 100000.0;
  }
}