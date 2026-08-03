import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// קורא דופק מ־Apple Health / Google Health Connect (polling — אין stream אמיתי).
class PlatformHeartRateSource implements HeartRateSourceLike {
  final Health _health;
  final _controller = StreamController<double>.broadcast();
  Timer? _pollTimer;

  bool _running = false;
  bool _authorized = false;
  bool _configured = false;
  double? _lastBpm;
  DateTime? _lastSampleAt;
  String _status = 'שעון לא מחובר';

  static const _types = [HealthDataType.HEART_RATE];
  static const _permissions = [HealthDataAccess.READ];
  static const _freshness = Duration(seconds: 90);
  static const _lookback = Duration(minutes: 3);
  static const _pollEvery = Duration(seconds: 5);

  PlatformHeartRateSource({Health? health}) : _health = health ?? Health();

  @override
  Stream<double> get heartRateBpm => _controller.stream;

  @override
  bool get isLiveHardware =>
      _authorized && hasFreshData && _lastBpm != null;

  bool get hasFreshData {
    if (_lastSampleAt == null) return false;
    return DateTime.now().difference(_lastSampleAt!) <= _freshness;
  }

  bool get isAuthorized => _authorized;

  @override
  String get statusLabel => _status;

  double? get lastBpm => _lastBpm;

  Future<bool> ensureConfigured() async {
    if (_configured) return true;
    try {
      await _health.configure();
      _configured = true;
      return true;
    } catch (e) {
      _status = 'שירות הבריאות לא זמין במכשיר זה';
      debugPrint('Health configure failed: $e');
      return false;
    }
  }

  /// מחזיר true אם ההרשאה ניתנה (גם בלי דגימה טרייה עדיין).
  Future<bool> requestAuthorization() async {
    final ok = await ensureConfigured();
    if (!ok) return false;

    try {
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      _authorized = granted;
      _status = granted
          ? 'הרשאה ניתנה — ממתין לדגימת דופק מהשעון'
          : 'הרשאת דופק נדחתה';
      return granted;
    } catch (e) {
      _authorized = false;
      _status = 'לא ניתן לבקש הרשאת דופק';
      debugPrint('Health auth failed: $e');
      return false;
    }
  }

  @override
  Future<void> start() async {
    if (_running) return;
    final configured = await ensureConfigured();
    if (!configured) return;

    if (!_authorized) {
      final granted = await requestAuthorization();
      if (!granted) return;
    }

    _running = true;
    await _pollOnce();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (!_running || !_authorized) return;
    try {
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: now.subtract(_lookback),
        endTime: now,
      );

      final numeric = points
          .where((p) => p.type == HealthDataType.HEART_RATE)
          .where((p) => p.value is NumericHealthValue)
          .toList()
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

      if (numeric.isEmpty) {
        _status = hasFreshData
            ? 'דופק מהשעון: ${_lastBpm!.round()} BPM'
            : 'מחובר — אין דגימת דופק חדשה (ודא שהשעון מסתנכרן)';
        return;
      }

      final newest = numeric.first;
      final bpm = (newest.value as NumericHealthValue).numericValue.toDouble();
      if (bpm < 30 || bpm > 230) return;

      _lastBpm = bpm;
      _lastSampleAt = newest.dateTo;
      _status = 'דופק חי מהשעון: ${bpm.round()} BPM';
      if (!_controller.isClosed) {
        _controller.add(bpm);
      }
    } catch (e) {
      _status = 'שגיאה בקריאת דופק מהשעון';
      debugPrint('Health poll failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> disconnect() async {
    await stop();
    _authorized = false;
    _lastBpm = null;
    _lastSampleAt = null;
    _status = 'שעון לא מחובר';
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}

/// ממשק מינימלי כדי לא לכפות health package על הדמו.
abstract class HeartRateSourceLike {
  Stream<double> get heartRateBpm;
  bool get isLiveHardware;
  String get statusLabel;
  Future<void> start();
  Future<void> stop();
  void dispose();
}
