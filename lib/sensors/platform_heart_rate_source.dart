import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Samsung sync can lag; keep a wide discovery window.
  static const _freshness = Duration(minutes: 15);
  static const _lookback = Duration(hours: 24);
  static const _pollEvery = Duration(seconds: 3);
  static const _fastPollEvery = Duration(seconds: 2);

  PlatformHeartRateSource({Health? health}) : _health = health ?? Health();

  @override
  Stream<double> get heartRateBpm => _controller.stream;

  @override
  bool get isLiveHardware =>
      _authorized && hasUsableData && _lastBpm != null;

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
      _status =
          'חיבור שעון זמין רק באפליקציה על הטלפון (לא בדפדפן)';
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

  Future<void> _requestAndroidRuntimePerms() async {
    if (!_isAndroid) return;
    try {
      await Permission.activityRecognition.request();
    } catch (_) {}
  }

  Future<bool> _ensureHealthConnectReady() async {
    _needsHealthConnectInstall = false;
    if (_unsupportedPlatform) return false;
    if (!_isAndroid) return true;

    try {
      final available = await _health.isHealthConnectAvailable();
      if (available) return true;

      final status = await _health.getHealthConnectSdkStatus();
      _needsHealthConnectInstall = true;
      if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        _status = 'יש לעדכן את Health Connect מחנות Play, ואז לחזור לכאן';
      } else {
        _status =
            'חובה להתקין Google Health Connect לפני חיבור שעון באנדרואיד';
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
      _status =
          'נפתחה חנות Play — התקינו Health Connect ואז לחצו שוב «חבר שעון»';
      _emitStatus();
    } catch (e) {
      // Fallback: open Play Store page directly.
      await openHealthConnectStore();
      debugPrint('installHealthConnect failed: $e');
    }
  }

  Future<void> openHealthConnectStore() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _status = 'נפתחה חנות Play ל־Health Connect';
      _emitStatus();
    } catch (e) {
      _status = 'לא ניתן לפתוח את חנות Play';
      _emitStatus();
    }
  }

  Future<void> openSamsungHealth() async {
    final candidates = <Uri>[
      Uri.parse('samsunghealth://'),
      Uri.parse('https://play.google.com/store/apps/details?id=com.sec.android.app.shealth'),
    ];
    for (final uri in candidates) {
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) {
          _status =
              'נפתח Samsung Health — הפעילו סנכרון דופק ל־Health Connect';
          _emitStatus();
          return;
        }
      } catch (_) {}
    }
    _status = 'לא ניתן לפתוח Samsung Health אוטומטית';
    _emitStatus();
  }

  /// מחבר הרשאות Health + מתחיל קריאה.
  Future<WatchConnectResult> connect() async {
    if (_unsupportedPlatform) {
      return const WatchConnectResult(
        success: false,
        message:
            'בדפדפן אי אפשר לחבר שעון. התקינו את האפליקציה על הטלפון ובצעו את ההוראות שם.',
      );
    }

    final configured = await ensureConfigured();
    if (!configured) {
      return WatchConnectResult(success: false, message: _status);
    }

    await _requestAndroidRuntimePerms();

    final hcReady = await _ensureHealthConnectReady();
    if (!hcReady) {
      return WatchConnectResult(
        success: false,
        needsHealthConnectInstall: _needsHealthConnectInstall,
        message: _status,
      );
    }

    try {
      // Prefer only available types on this platform.
      final types = <HealthDataType>[HealthDataType.HEART_RATE];
      if (_health.isDataTypeAvailable(HealthDataType.RESTING_HEART_RATE)) {
        types.add(HealthDataType.RESTING_HEART_RATE);
      }
      final perms = List<HealthDataAccess>.filled(
        types.length,
        HealthDataAccess.READ,
      );

      final granted = await _health.requestAuthorization(
        types,
        permissions: perms,
      );

      bool reallyGranted = granted;
      try {
        final has = await _health.hasPermissions(types, permissions: perms);
        if (has == false) reallyGranted = false;
        // null = unknown (common on iOS) — trust granted flag
      } catch (_) {}

      if (!reallyGranted) {
        _authorized = false;
        _status = _isAndroid
            ? 'הרשאת דופק נדחתה. אשרו שוב ב־Health Connect ואז «חבר שעון».'
            : 'הרשאת דופק נדחתה. אייפון: הגדרות ← בריאות ← עוגן לילה ← דופק.';
        _emitStatus();
        return WatchConnectResult(success: false, message: _status);
      }

      _authorized = true;

      if (_isAndroid) {
        try {
          if (await _health.isHealthDataHistoryAvailable()) {
            await _health.requestHealthDataHistoryAuthorization();
          }
        } catch (e) {
          debugPrint('history auth: $e');
        }
        try {
          if (await _health.isHealthDataInBackgroundAvailable()) {
            await _health.requestHealthDataInBackgroundAuthorization();
          }
        } catch (e) {
          debugPrint('background auth: $e');
        }
      }

      _status = 'הרשאה ניתנה — קורא דופק מהשעון…';
      _emitStatus();

      await start();
      await _pollOnce(forceTypes: types);
      // Burst for ~2 minutes
      _startFastBurst(forceTypes: types, maxTicks: 60);

      if (hasUsableData) {
        _status = 'דופק חי מהשעון: ${_lastBpm!.round()} BPM';
        _emitStatus();
        return WatchConnectResult(
          success: true,
          message: 'השעון מחובר — דופק ${_lastBpm!.round()} BPM',
        );
      }

      if (_lastBpm != null && _lastSampleAt != null) {
        final mins = DateTime.now().difference(_lastSampleAt!).inMinutes;
        _status =
            'נמצא דופק אחרון ${_lastBpm!.round()} BPM (לפני $mins דק׳). שימו את השעון על היד והמתינו לסנכרון, או לחצו «רענן».';
        _emitStatus();
        // Still count as success for permission path; emit last known for UI.
        if (!_controller.isClosed) {
          _controller.add(_lastBpm!);
        }
        return WatchConnectResult(
          success: true,
          message: _status,
        );
      }

      return const WatchConnectResult(
        success: true,
        message:
            'ההרשאה אושרה, אך עדיין אין דגימת דופק. ודאו שהשעון כותב דופק ל־Health Connect (באפליקציית השעון שכבר מותקנת), ואז «רענן».',
      );
    } catch (e) {
      _authorized = false;
      final msg = e.toString();
      if (msg.contains('Health Connect') || msg.contains('installHealthConnect')) {
        _needsHealthConnectInstall = true;
        _status = 'יש להתקין / לעדכן Health Connect ואז לנסות שוב';
      } else {
        _status = 'שגיאה בחיבור: $e';
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
      return;
    }

    final hcReady = await _ensureHealthConnectReady();
    if (!hcReady) return;

    _running = true;
    await _pollOnce();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) => _pollOnce());
  }

  void _startFastBurst({
    List<HealthDataType>? forceTypes,
    int maxTicks = 60,
  }) {
    _fastPollTimer?.cancel();
    var ticks = 0;
    _fastPollTimer = Timer.periodic(_fastPollEvery, (t) async {
      ticks += 1;
      await _pollOnce(forceTypes: forceTypes);
      if (!_running || ticks >= maxTicks || hasUsableData) {
        t.cancel();
        _fastPollTimer = null;
      }
    });
  }

  Future<void> _pollOnce({List<HealthDataType>? forceTypes}) async {
    if (!_running || !_authorized) return;
    try {
      final now = DateTime.now();
      final types = forceTypes ??
          [
            HealthDataType.HEART_RATE,
            if (_health.isDataTypeAvailable(HealthDataType.RESTING_HEART_RATE))
              HealthDataType.RESTING_HEART_RATE,
          ];

      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: now.subtract(_lookback),
        endTime: now,
      );

      final numeric = points
          .where(
            (p) =>
                p.type == HealthDataType.HEART_RATE ||
                p.type == HealthDataType.RESTING_HEART_RATE,
          )
          .where((p) => p.value is NumericHealthValue)
          .toList()
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

      if (numeric.isEmpty) {
        _status = hasUsableData
            ? 'דופק מהשעון: ${_lastBpm!.round()} BPM'
            : 'מחובר — אין עדיין דגימת דופק. '
                'בדקו באפליקציית השעון ששיתוף דופק ל־Health Connect פעיל';
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
            'דופק אחרון ${bpm.round()} BPM (לפני ${age.inMinutes} דק׳) — ממתין לסנכרון חדש';
        // Emit so UI shows a number and detection can use until fresher arrives.
        if (!_controller.isClosed) {
          _controller.add(bpm);
        }
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

abstract class HeartRateSourceLike {
  Stream<double> get heartRateBpm;
  bool get isLiveHardware;
  String get statusLabel;
  Future<void> start();
  Future<void> stop();
  void dispose();
}
