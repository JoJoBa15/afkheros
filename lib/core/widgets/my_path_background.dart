import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble, ImageFilter;

import 'package:flutter/material.dart';

/// My Path background:
/// - Sky gradient that changes with time (smooth transitions)
/// - Sun (day) / Moon + stars (night)
/// - Pixel clouds from PNG assets (3 parallax layers, infinite loop)
/// - Optional mine background crossfade (sunrise/day/sunset/night)
///
/// IMPORTANT:
/// - Put your cloud pngs in: assets/images/clouds/
/// - Update pubspec.yaml:
///   flutter:
///     assets:
///       - assets/images/clouds/
///       - assets/images/bg/
///
/// If you don't have clouds yet, it still runs (images just won't show).
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

  // ✅ Metti qui i tuoi nomi file reali (AI clouds). Anche 6-12 vanno bene.
  // Se non esistono ancora, non crasha (ma vedrai warning in console).
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

    // Clouds seeds (3 layer)
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
      if (mounted) setState(() => _now = DateTime.now());
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
      final assetIndex = (rnd.nextDouble() * assetsCount)
          .floor()
          .clamp(0, assetsCount - 1);

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
        // ✅ Cover + bottom anchor: no “abbassamento” / bande
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: _w,
            height: _h,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final t = _anim.value;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // SKY
                    CustomPaint(
                      painter: _SkyPainter(
                        sky: sky,
                        t: t,
                      ),
                    ),

                    // SUN / MOON
                    CustomPaint(
                      painter: _SunMoonPainter(
                        sky: sky,
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

                    // Slight top vignette to feel more “cinematic”
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.10 + 0.18 * sky.night),
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
    );
  }
}

// ============================================================================
// SKY
// ============================================================================

class _SkyState {
  final Color top;
  final Color bottom;
  final double night;     // 0..1
  final double day;       // 0..1
  final double sunAlpha;  // 0..1

  const _SkyState({
    required this.top,
    required this.bottom,
    required this.night,
    required this.day,
    required this.sunAlpha,
  });
}

/// Smooth sky color transitions across the day (no hard steps).
_SkyState _skyState(DateTime now) {
  // Palettes (you can tune these)
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

  const tDayStable0 = 9 * 60; // 09:00
  const tDayStable1 = 17 * 60; // 17:00

  const tDayToSunset0 = 17 * 60; // 17:00
  const tDayToSunset1 = 18 * 60 + 45; // 18:45

  const tSunsetToNight0 = 18 * 60 + 45; // 18:45
  const tSunsetToNight1 = 20 * 60 + 15; // 20:15

  Color top, bottom;

  if (m < tNightToSunrise0) {
    top = nightTop;
    bottom = nightBottom;
  } else if (m < tNightToSunrise1) {
    final u = smoothstep((m - tNightToSunrise0) / (tNightToSunrise1 - tNightToSunrise0));
    top = Color.lerp(nightTop, sunriseTop, u)!;
    bottom = Color.lerp(nightBottom, sunriseBottom, u)!;
  } else if (m < tSunriseToDay1) {
    final u = smoothstep((m - tSunriseToDay0) / (tSunriseToDay1 - tSunriseToDay0));
    top = Color.lerp(sunriseTop, dayTop, u)!;
    bottom = Color.lerp(sunriseBottom, dayBottom, u)!;
  } else if (m < tDayStable1) {
    top = dayTop;
    bottom = dayBottom;
  } else if (m < tDayToSunset1) {
    final u = smoothstep((m - tDayToSunset0) / (tDayToSunset1 - tDayToSunset0));
    top = Color.lerp(dayTop, sunsetTop, u)!;
    bottom = Color.lerp(dayBottom, sunsetBottom, u)!;
  } else if (m < tSunsetToNight1) {
    final u = smoothstep((m - tSunsetToNight0) / (tSunsetToNight1 - tSunsetToNight0));
    top = Color.lerp(sunsetTop, nightTop, u)!;
    bottom = Color.lerp(sunsetBottom, nightBottom, u)!;
  } else {
    top = nightTop;
    bottom = nightBottom;
  }

  // Night/day factors
  final night = _nightness(now);
  final day = (1.0 - night).clamp(0.0, 1.0);

  // Sun alpha (less at dawn/dusk)
  final sunAlpha = (day * 0.95).clamp(0.0, 1.0);

  return _SkyState(
    top: top,
    bottom: bottom,
    night: night,
    day: day,
    sunAlpha: sunAlpha,
  );
}

class _SkyPainter extends CustomPainter {
  final _SkyState sky;
  final double t;

  _SkyPainter({
    required this.sky,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ✅ Always fill with gradient. Never "move" the gradient -> no black bands.
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [sky.top, sky.bottom],
      ).createShader(rect);

    canvas.drawRect(rect, skyPaint);

    // Micro dither lines: tiny life + pixel vibe, without shifting
    const lines = 84;
    for (int i = 0; i < lines; i++) {
      final y = ((i / (lines - 1)) * size.height).floorToDouble();

      final n = (_hash01(i * 97 + (t * 900).floor()) - 0.5);
      final baseA = lerpDouble(0.030, 0.018, sky.night) ?? 0.024;
      final a = (baseA + n.abs() * 0.016).clamp(0.010, 0.050);

      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        Paint()..color = Colors.white.withOpacity(a),
      );
    }

    // Stars (night only)
    if (sky.night > 0.08) {
      final p = Paint()..isAntiAlias = false;
      for (int i = 0; i < 70; i++) {
        final x = _hash01(i * 991) * size.width;
        final y = _hash01(i * 773) * (size.height * 0.55);

        final tw = 0.65 + 0.35 * math.sin(t * math.pi * 2 * (0.7 + _hash01(i * 31)));
        final alpha = ((60 * sky.night) * tw).round().clamp(0, 85);

        p.color = Color.fromARGB(alpha, 255, 255, 255);
        canvas.drawRect(
          Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), 2, 2),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) {
    return oldDelegate.sky.top != sky.top ||
        oldDelegate.sky.bottom != sky.bottom ||
        oldDelegate.sky.night != sky.night ||
        oldDelegate.t != t;
  }
}

// ============================================================================
// SUN / MOON
// ============================================================================

class _SunMoonPainter extends CustomPainter {
  final _SkyState sky;
  final double t;
  final double parallax;

  _SunMoonPainter({
    required this.sky,
    required this.t,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDay = sky.day > 0.12;

    if (isDay) {
      final c = _sunPos(size, parallax);
      final pulse = 0.98 + 0.02 * math.sin(t * math.pi * 2 * 2.1);
      final r = size.width * 0.038 * pulse;

      // Glow
      final glow = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            Color(0x66FFD9A0).withOpacity(0.9 * sky.sunAlpha),
            const Color(0x00FFD9A0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 5));
      canvas.drawCircle(c, r * 5, glow);

      // Disk
      final sun = Paint()
        ..color = const Color(0xFFFFD08A).withOpacity(0.95 * sky.sunAlpha)
        ..isAntiAlias = true;
      canvas.drawCircle(c, r, sun);

      // Soft highlight
      final hi = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.35 * sky.sunAlpha),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: c.translate(-r * 0.25, -r * 0.25), radius: r * 1.2),
        );
      canvas.drawCircle(c.translate(-r * 0.25, -r * 0.25), r * 0.9, hi);
    } else {
      // Moon
      final c = Offset(size.width * 0.18 + parallax * 4, size.height * 0.22 + parallax * 6);
      final r = size.width * 0.030;
      final a = (160 * sky.night).round().clamp(0, 160);

      final glow = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            Color.fromARGB((80 * sky.night).round(), 210, 230, 255),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 5));
      canvas.drawCircle(c, r * 5, glow);

      canvas.drawCircle(
        c,
        r,
        Paint()..color = Color.fromARGB(a, 220, 235, 255),
      );

      // Crescent cut
      canvas.drawCircle(
        c.translate(r * 0.35, -r * 0.10),
        r * 0.95,
        Paint()..color = sky.top.withOpacity(0.35),
      );
    }
  }

  Offset _sunPos(Size size, double parallax) {
    // Simple arc across the sky (static day position + slight parallax)
    // If you want it time-accurate, we can hook to minutes (but this already looks good).
    final x = size.width * 0.78 + parallax * 4;
    final y = size.height * 0.20 + parallax * 6;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _SunMoonPainter oldDelegate) {
    return oldDelegate.sky.day != sky.day ||
        oldDelegate.sky.night != sky.night ||
        oldDelegate.t != t ||
        oldDelegate.parallax != parallax;
  }
}

// ============================================================================
// CLOUDS (PNG sprites)
// ============================================================================

class _CloudSprite {
  final int assetIndex;
  final double x;      // 0..1
  final double y;      // 0..1
  final double speed;  // how fast it moves
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
  final double baseOpacity;
  final List<_CloudSprite> clouds;
  final List<String> assets;

  const _PixelCloudLayer({
    required this.t,
    required this.parallax,
    required this.sky,
    required this.depth,
    required this.baseOpacity,
    required this.clouds,
    required this.assets,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty || clouds.isEmpty) return const SizedBox.shrink();

    // Less clouds at night
    final nightFade = (1.0 - sky.night * 0.70).clamp(0.0, 1.0);
    final opacity = (baseOpacity * nightFade).clamp(0.0, 1.0);

    // Slight dark tint at night (optional)
    final tintStrength = (sky.night * 0.28).clamp(0.0, 0.28);
    final tint = ColorFilter.mode(
      Colors.black.withOpacity(tintStrength),
      BlendMode.srcATop,
    );

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: ColorFiltered(
          colorFilter: tint,
          child: Stack(
            children: [
              for (int i = 0; i < clouds.length; i++)
                _OneCloud(
                  cloud: clouds[i],
                  t: t,
                  depth: depth,
                  parallax: parallax,
                  asset: assets[clouds[i].assetIndex % assets.length],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OneCloud extends StatelessWidget {
  final _CloudSprite cloud;
  final double t;
  final double depth;
  final double parallax;
  final String asset;

  const _OneCloud({
    required this.cloud,
    required this.t,
    required this.depth,
    required this.parallax,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    const W = 1024.0;
    const H = 1536.0;

    // Wrap: gives infinite loop
    final speed = cloud.speed * (0.75 + depth * 0.75);
    final x01 = (cloud.x + t * speed) % 1.25; // go a bit beyond
    final baseX = x01 * W - 220; // start off-screen left
    final baseY = cloud.y * H;

    final bob = math.sin(t * math.pi * 2 * cloud.wobble) * (2.0 + 6.0 * depth);
    final px = parallax * 16 * depth;

    // Pixel-crisp rounding
    final left = (baseX + px).roundToDouble();
    final top = (baseY + bob).roundToDouble();

    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: cloud.scale,
        child: Image.asset(
          asset,
          filterQuality: FilterQuality.none,
          isAntiAlias: false,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ============================================================================
// MINE BACKGROUND (crossfade)
// ============================================================================

class _Blend {
  final String a, b;
  final double t;
  const _Blend(this.a, this.b, this.t);
}

_Blend _computeMineBlend(DateTime now) {
  // Change these paths if your project differs.
  const sunrise = 'assets/images/bg/mine_sunrise.png';
  const day = 'assets/images/bg/mine_day.png';
  const sunset = 'assets/images/bg/mine_sunset.png';
  const night = 'assets/images/bg/mine_night.png';

  final m = now.hour * 60 + now.minute;

  // Blend windows
  const sunriseStart = 6 * 60;
  const sunriseEnd = 8 * 60;

  const sunsetStart = 17 * 60;
  const sunsetEnd = 19 * 60;

  const nightStart = 20 * 60 + 30;

  if (m >= sunriseStart && m < sunriseEnd) {
    return _Blend(sunrise, day, (m - sunriseStart) / (sunriseEnd - sunriseStart));
  }
  if (m >= sunriseEnd && m < sunsetStart) return const _Blend(day, day, 0);

  if (m >= sunsetStart && m < sunsetEnd) {
    return _Blend(day, sunset, (m - sunsetStart) / (sunsetEnd - sunsetStart));
  }
  if (m >= sunsetEnd && m < nightStart) {
    return _Blend(sunset, night, (m - sunsetEnd) / (nightStart - sunsetEnd));
  }
  return const _Blend(night, night, 0);
}

class _SafeAsset extends StatelessWidget {
  final String path;
  final String fallback;

  const _SafeAsset({
    required this.path,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          fallback,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const SizedBox.expand(),
        );
      },
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

double _nightness(DateTime now) {
  // Soft night ramp between ~19:00 and ~23:00
  final m = now.hour * 60 + now.minute;
  const nightFrom = 19 * 60;
  const nightTo = 23 * 60;
  final x = ((m - nightFrom) / (nightTo - nightFrom)).clamp(0.0, 1.0);
  return smoothstep(x);
}

double smoothstep(double t) => t * t * (3 - 2 * t);

double _hash01(int n) {
  n = (n ^ 0xA3C59AC3) * 2654435761;
  n = (n ^ (n >> 16)) * 2246822519;
  n = (n ^ (n >> 13)) * 3266489917;
  n = n ^ (n >> 16);
  return (n & 0xFFFFFF) / 0xFFFFFF;
}

class _Seeded {
  int _state;
  _Seeded(this._state);

  double nextDouble() {
    _state = 1664525 * _state + 1013904223;
    return ((_state >> 8) & 0xFFFFFF) / 0xFFFFFF;
  }
}
