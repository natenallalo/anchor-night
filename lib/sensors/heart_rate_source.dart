import 'dart:async';
import 'dart:math';

/// מקור דופק ניתן להחלפה — דמו עכשיו, Health/Watch בהמשך.
abstract class HeartRateSource {
  Stream<double> get heartRateBpm;
  bool get isLiveHardware;
  String get statusLabel;
  Future<void> start();
  Future<void> stop();
  void dispose();
}

/// דמו מציאותי: דופק רגוע עם רעש קל, ניתן לדחוף משבר/יקיצה לבדיקות.
class DemoHeartRateSource implements HeartRateSource {
  final _controller = StreamController<double>.broadcast();
  final _random = Random();
  Timer? _timer;
  double _bpm = 74;
  bool _running = false;

  @override
  Stream<double> get heartRateBpm => _controller.stream;

  @override
  bool get isLiveHardware => false;

  @override
  String get statusLabel => 'דופק מדומה (חבר שעון לדיוק מלא)';

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      // רעש פיזיולוגי קל
      final drift = (_random.nextDouble() - 0.5) * 1.6;
      _bpm = (_bpm + drift).clamp(48, 160);
      if (!_controller.isClosed) {
        _controller.add(_bpm);
      }
    });
  }

  void setBpm(double value) {
    _bpm = value.clamp(40, 200);
    if (!_controller.isClosed) {
      _controller.add(_bpm);
    }
  }

  void nudgeToward(double target, {double step = 4}) {
    if (_bpm < target) {
      _bpm = min(target, _bpm + step);
    } else {
      _bpm = max(target, _bpm - step);
    }
    if (!_controller.isClosed) {
      _controller.add(_bpm);
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}
