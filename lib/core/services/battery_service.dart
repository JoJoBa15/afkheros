import 'package:flutter/services.dart';

class BatteryInfo {
  final int level; // 0..100
  final bool isCharging;

  const BatteryInfo({
    required this.level,
    required this.isCharging,
  });

  factory BatteryInfo.fromMap(Map<dynamic, dynamic> map) {
    final level = (map['level'] as int?) ?? 0;
    final charging = (map['isCharging'] as bool?) ?? false;
    return BatteryInfo(level: level, isCharging: charging);
  }
}

class BatteryService {
  static const MethodChannel _channel = MethodChannel('afkheros/battery');

  static Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryInfo');
      if (result == null) return null;
      return BatteryInfo.fromMap(result);
    } catch (_) {
      return null;
    }
  }
}