import 'dart:async';

import 'package:flutter/foundation.dart';

import 'heart_rate_source.dart';
import 'platform_heart_rate_source.dart';
import 'watch_connect_result.dart';

enum HeartRateMode { demo, live }

/// בוחר בין דופק חי (שעון) לדמו, עם אפשרות דריסה זמנית לבדיקות.
class HeartRateCoordinator implements HeartRateSource {
  final DemoHeartRateSource demo;
  final PlatformHeartRateSource platform;

  final _controller = StreamController<double>.broadcast();
  StreamSubscription<double>? _activeSub;

  HeartRateMode _mode = HeartRateMode.demo;
  double? _overrideBpm;
  bool _running = false;
  String _lastError = '';
  WatchConnectResult? _lastConnectResult;
  VoidCallback? onChanged;

  HeartRateCoordinator({
    DemoHeartRateSource? demo,
    PlatformHeartRateSource? platform,
  })  : demo = demo ?? DemoHeartRateSource(),
        platform = platform ?? PlatformHeartRateSource() {
    this.platform.onStatusChanged = () => onChanged?.call();
  }

  HeartRateMode get mode => _mode;
  bool get usingLiveWatch =>
      _mode == HeartRateMode.live && platform.isLiveHardware;
  bool get isWatchLinked => _mode == HeartRateMode.live && platform.isLinked;
  bool get needsHealthConnectInstall => platform.needsHealthConnectInstall;
  String get lastError => _lastError;
  WatchConnectResult? get lastConnectResult => _lastConnectResult;

  @override
  Stream<double> get heartRateBpm => _controller.stream;

  @override
  bool get isLiveHardware =>
      _overrideBpm == null &&
      _mode == HeartRateMode.live &&
      platform.isLiveHardware;

  @override
  String get statusLabel {
    if (_overrideBpm != null) {
      return 'מצב בדיקה (${_overrideBpm!.round()} BPM) · מקור: '
          '${_mode == HeartRateMode.live ? 'שעון' : 'דמו'}';
    }
    if (_mode == HeartRateMode.live) {
      return platform.statusLabel;
    }
    return demo.statusLabel;
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    if (_mode == HeartRateMode.live) {
      await _switchToLiveInternal();
    } else {
      await _switchToDemoInternal();
    }
  }

  /// מבקש הרשאות ומנסה לעבור לדופק חי.
  Future<WatchConnectResult> connectWatch() async {
    _lastError = '';
    if (kIsWeb) {
      final result = const WatchConnectResult(
        success: false,
        message:
            'בדפדפן אי אפשר לחבר שעון. התקינו את האפליקציה בטלפון Android/iPhone.',
      );
      _lastConnectResult = result;
      _lastError = result.message;
      onChanged?.call();
      return result;
    }

    final result = await platform.connect();
    _lastConnectResult = result;
    if (!result.success) {
      _lastError = result.message;
      await useDemo();
      onChanged?.call();
      return result;
    }

    _mode = HeartRateMode.live;
    _overrideBpm = null;
    if (_running) {
      await _switchToLiveInternal();
    } else {
      // platform.connect already started polling; wire the stream.
      await _activeSub?.cancel();
      await demo.stop();
      _activeSub = platform.heartRateBpm.listen(_onUpstream);
      final last = platform.lastBpm;
      if (last != null) _onUpstream(last);
    }
    onChanged?.call();
    return result;
  }

  Future<void> installHealthConnect() => platform.installHealthConnect();

  Future<void> openHealthConnectStore() => platform.openHealthConnectStore();

  Future<void> openSamsungHealth() => platform.openSamsungHealth();

  Future<void> useDemo() async {
    _mode = HeartRateMode.demo;
    _overrideBpm = null;
    await platform.disconnect();
    if (_running) {
      await _switchToDemoInternal();
    }
    onChanged?.call();
  }

  void setDemoOverride(double? bpm) {
    _overrideBpm = bpm?.clamp(40, 200);
    if (_overrideBpm != null) {
      _emit(_overrideBpm!);
    }
    onChanged?.call();
  }

  void clearOverride() => setDemoOverride(null);

  Future<void> _switchToDemoInternal() async {
    await _activeSub?.cancel();
    await platform.stop();
    await demo.start();
    _activeSub = demo.heartRateBpm.listen(_onUpstream);
  }

  Future<void> _switchToLiveInternal() async {
    await _activeSub?.cancel();
    await demo.stop();
    await platform.start();
    _activeSub = platform.heartRateBpm.listen(_onUpstream);
    final last = platform.lastBpm;
    if (last != null) {
      _onUpstream(last);
    }
  }

  void _onUpstream(double bpm) {
    if (_overrideBpm != null) {
      _emit(_overrideBpm!);
      return;
    }
    _emit(bpm);
  }

  void _emit(double bpm) {
    if (!_controller.isClosed) {
      _controller.add(bpm);
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _activeSub?.cancel();
    _activeSub = null;
    await demo.stop();
    await platform.stop();
  }

  @override
  void dispose() {
    stop();
    demo.dispose();
    platform.dispose();
    _controller.close();
  }
}
