import 'dart:async';

import '../domain/sensor_sample.dart';
import 'accelerometer_source.dart';
import 'heart_rate_coordinator.dart';

class SensorHub {
  final AccelerometerSource accelerometer;
  final HeartRateCoordinator heartRate;

  double _movementG = 0;
  double? _heartRateBpm;
  final _samples = StreamController<SensorSample>.broadcast();
  StreamSubscription<double>? _moveSub;
  StreamSubscription<double>? _hrSub;
  Timer? _tick;

  SensorHub({
    AccelerometerSource? accelerometer,
    HeartRateCoordinator? heartRate,
  })  : accelerometer = accelerometer ?? AccelerometerSource(),
        heartRate = heartRate ?? HeartRateCoordinator();

  Stream<SensorSample> get samples => _samples.stream;
  double get movementG => _movementG;
  double? get heartRateBpm => _heartRateBpm;
  bool get hasLiveHeartRate => heartRate.isLiveHardware;
  String get heartRateStatus => heartRate.statusLabel;
  HeartRateMode get heartRateMode => heartRate.mode;

  Future<void> start() async {
    accelerometer.start();
    await heartRate.start();
    _moveSub = accelerometer.movementG.listen((g) => _movementG = g);
    _hrSub = heartRate.heartRateBpm.listen((bpm) => _heartRateBpm = bpm);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_samples.isClosed) return;
      _samples.add(
        SensorSample(
          at: DateTime.now(),
          movementG: _movementG,
          heartRateBpm: _heartRateBpm,
        ),
      );
    });
  }

  Future<bool> connectWatch() => heartRate.connectWatch();

  Future<void> useDemoHeartRate() => heartRate.useDemo();

  Future<void> stop() async {
    _tick?.cancel();
    await _moveSub?.cancel();
    await _hrSub?.cancel();
    accelerometer.stop();
    await heartRate.stop();
  }

  /// לדמו/בדיקות — דורס את מקור הדופק זמנית
  void demoSetHeartRate(double bpm) {
    heartRate.setDemoOverride(bpm);
    _heartRateBpm = bpm;
  }

  void clearDemoHeartRateOverride() {
    heartRate.clearOverride();
  }

  void demoSetMovement(double g) {
    accelerometer.injectForDemo(g);
    _movementG = g;
  }

  void dispose() {
    stop();
    accelerometer.dispose();
    heartRate.dispose();
    _samples.close();
  }
}
