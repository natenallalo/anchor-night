import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'watch_connect_result.dart';

/// קורא דופק מ־Apple Health / Google Health Connect (polling).
class PlatformHeartRateSource implements HeartRateSourceLike {
  final Health _health;
  final _controller = StreamController<double>.broadcast();
  Timer? _pollTimer;
  Timer? _fastPollTimer;

  bool _running = false;
  bool _authorized = false;
  bool _configured = false;
  bool _needsHealthConnectInstall = false;
  double? _lastBpm;
  DateTime? _lastSampleAt;
  String _status = 'שעון לא מחובר';
  VoidCallback? onStatusChanged;

  static const _types = [HealthDataType.HEART_RATE];
  static const _permissions = [HealthDataAccess.READ];
  // Samsung Health → Health Connect sync is often sparse; keep a wider window.
  static const _freshness = Duration(minutes: 10);
  static const _lookback = Duration(minutes: 30);
  static const _pollEvery = Duration(seconds: 4);
  static const _fastPollEvery = Duration(seconds: 2);

  PlatformHeartRateSource({Health? health}) : _health = health ?? Health();

  @override
  Stream<double> get heartRateBpm => _controller.stream;

  /// מורשה + יש דגימה בחלון הסביר.
  @override
  bool get isLiveHardware =>
      _authorized && hasUsableData && _lastBpm != null;

  /// מורשה למצב חי (גם בלי דגימה טרייה עדיין).
  bool get isLinked => _authorized;

  bool get needsHealthConnectInstall => _needsHealthConnectInstall;

  bool get hasUsableData {
    if (_lastSampleAt == null || _lastBpm == null) return false;
    return DateTime.now().difference(_lastSampleAt!) <= _freshness;
  }

  bool get isAuthorized => _authorized;

  @override
  String get statusLabel => _status;

  double? get lastBpm => _lastBpm;
  DateTime? get lastSampleAt => _lastSampleAt;

  bool get _unsupportedPlatform =>
      kIsWeb ||
      !(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> ensureConfigured() async {
    if (_unsupportedPlatform) {
      _status = 'חיבור שעון זמין רק באפליקציית Android / iPhone';
      _emitStatus();
      return false;
    }
    if (_configured) return true;
    try {
      await _health.configure();
      _configured = true;
      return true;
    } catch (e) {
      _status = 'שירות הבריאות לא זמין במכשיר זה';
      debugPrint('Health configure failed: $e');
      _emitStatus();
      return false;
    }
  }

  Future<bool> _ensureHealthConnectReady() async {
    _needsHealthConnectInstall = false;
    if (_unsupportedPlatform) return false;
    if (kIsWeb) return false;
    if (!_isAndroid) return true;

    try {
      final status = await _health.getHealthConnectSdkStatus();
      if (status == HealthConnectSdkStatus.sdkAvailable) {
        return true;
      }
      _needsHealthConnectInstall = true;
      if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        _status =
            'יש לעדכן את Health Connect מחנות Play, ואז לחזור לכאן';
      } else {
        _status =
            'יש להתקין Google Health Connect (חובה לחיבור שעון באנדרואיד)';
      }
      _emitStatus();
      return false;
    } catch (e) {
      _needsHealthConnectInstall = true;
      _status = 'Health Connect לא זמין — התקינו מחנות Play';
      debugPrint('Health Connect status failed: $e');
      _emitStatus();
      return false;
    }
  }

  Future<void> installHealthConnect() async {
    if (_unsupportedPlatform || !_isAndroid) return;
    try {
      await _health.installHealthConnect();
      _status = 'נפתחה חנות Play להתקנת Health Connect — אחרי ההתקנה לחצו שוב «חבר שעון»';
      _emitStatus();
    } catch (e) {
      _status = 'לא ניתן לפתוח התקנת Health Connect';
      debugPrint('installHealthConnect failed: $e');
      _emitStatus();
    }
  }

  /// מחבר הרשאות Health + מתחיל קריאה. מחזיר תוצאה מפורטת ל־UI.
  Future<WatchConnectResult> connect() async {
    if (_unsupportedPlatform) {
      return const WatchConnectResult(
        success: false,
        message:
            'בדפדפן אי אפשר לחבר שעון. התקינו את האפליקציה בטלפון.',
      );
    }

    final configured = await ensureConfigured();
    if (!configured) {
      return WatchConnectResult(success: false, message: _status);
    }

    final hcReady = await _ensureHealthConnectReady();
    if (!hcReady) {
      return WatchConnectResult(
        success: false,
        needsHealthConnectInstall: _needsHealthConnectInstall,
        message: _status,
      );
    }

    try {
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );

      // iOS may return true even when denied — verify when possible.
      bool reallyGranted = granted;
      try {
        final has = await _health.hasPermissions(
          _types,
          permissions: _permissions,
        );
        if (has == false) reallyGranted = false;
      } catch (_) {}

      if (!reallyGranted) {
        _authorized = false;
        _status = 'הרשאת דופק נדחתה — אפשר להפעיל בהגדרות הבריאות';
        _emitStatus();
        return WatchConnectResult(success: false, message: _status);
      }

      _authorized = true;

      // History + background improve night reliability on Android.
      if (_isAndroid) {
        try {
          await _health.requestHealthDataHistoryAuthorization();
        } catch (e) {
          debugPrint('history auth: $e');
        }
        try {
          await _health.requestHealthDataInBackgroundAuthorization();
        } catch (e) {
          debugPrint('background auth: $e');
        }
      }

      _status =
          'הרשאה ניתנה — ממתין לסנכרון דופק מהשעון (Samsung Health → Health Connect)';
      _emitStatus();

      await start();
      // Immediate aggressive polls after connect.
      await _pollOnce();
      _startFastBurst();

      if (hasUsableData) {
        _status = 'דופק חי מהשעון: ${_lastBpm!.round()} BPM';
        _emitStatus();
        return WatchConnectResult(
          success: true,
          message: 'השעון מחובר — דופק ${_lastBpm!.round()} BPM',
        );
      }

      return const WatchConnectResult(
        success: true,
        message:
            'הרשאה אושרה. אם אין דופק תוך דקה — ב־Samsung Health הפעילו סנכרון ל־Health Connect (דופק).',
      );
    } catch (e) {
      _authorized = false;
      final msg = e.toString();
      if (msg.contains('Health Connect') || msg.contains('installHealthConnect')) {
        _needsHealthConnectInstall = true;
        _status = 'יש להתקין / לעדכן Health Connect ואז לנסות שוב';
      } else {
        _status = 'לא ניתן לבקש הרשאת דופק';
      }
      debugPrint('Health auth failed: $e');
      _emitStatus();
      return WatchConnectResult(
        success: false,
        needsHealthConnectInstall: _needsHealthConnectInstall,
        message: _status,
      );
    }
  }

  /// תאימות לאחור.
  Future<bool> requestAuthorization() async {
    final result = await connect();
    return result.success;
  }

  @override
  Future<void> start() async {
    if (_running) return;
    if (_unsupportedPlatform) return;
    final configured = await ensureConfigured();
    if (!configured) return;
    if (!_authorized) {
      final result = await connect();
      if (!result.success) return;
      return; // connect() already started polling
    }

    final hcReady = await _ensureHealthConnectReady();
    if (!hcReady) return;

    _running = true;
    await _pollOnce();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) => _pollOnce());
  }

  void _startFastBurst() {
    _fastPollTimer?.cancel();
    var ticks = 0;
    _fastPollTimer = Timer.periodic(_fastPollEvery, (t) async {
      ticks += 1;
      await _pollOnce();
      if (!_running || ticks >= 30 || hasUsableData) {
        t.cancel();
        _fastPollTimer = null;
      }
    });
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
        _status = hasUsableData
            ? 'דופק מהשעון: ${_lastBpm!.round()} BPM'
            : 'מחובר ל־Health — ממתין לסנכרון דופק מהשעון '
                '(בדקו שסנכרון דופק ל־Health Connect פעיל)';
        _emitStatus();
        return;
      }

      final newest = numeric.first;
      final bpm = (newest.value as NumericHealthValue).numericValue.toDouble();
      if (bpm < 30 || bpm > 230) return;

      final age = now.difference(newest.dateTo);
      _lastBpm = bpm;
      _lastSampleAt = newest.dateTo;

      if (age <= _freshness) {
        _status = 'דופק חי מהשעון: ${bpm.round()} BPM';
        if (!_controller.isClosed) {
          _controller.add(bpm);
        }
      } else {
        _status =
            'נמצא דופק ישן (${bpm.round()} BPM, לפני ${age.inMinutes} דק׳) — ממתין לסנכרון חדש';
      }
      _emitStatus();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Health Connect') || msg.contains('not available')) {
        _needsHealthConnectInstall = true;
        _status = 'Health Connect לא זמין — התקינו ועברו חזרה לאפליקציה';
      } else {
        _status = 'שגיאה בקריאת דופק מהשעון';
      }
      debugPrint('Health poll failed: $e');
      _emitStatus();
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _fastPollTimer?.cancel();
    _fastPollTimer = null;
  }

  Future<void> disconnect() async {
    await stop();
    _authorized = false;
    _needsHealthConnectInstall = false;
    _lastBpm = null;
    _lastSampleAt = null;
    _status = 'שעון לא מחובר';
    _emitStatus();
  }

  void _emitStatus() {
    onStatusChanged?.call();
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
