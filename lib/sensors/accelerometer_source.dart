import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// קורא אקסלרומטר וממיר ל־g יחסי (אחרי הסרת כוח הכבידה).
class AccelerometerSource {
  StreamSubscription<AccelerometerEvent>? _sub;
  final _controller = StreamController<double>.broadcast();
  double _currentG = 0;
  // ממוצע נע להסרת רעש
  double _ema = 0;
  static const double _alpha = 0.35;

  Stream<double> get movementG => _controller.stream;
  double get currentG => _currentG;

  void start() {
    _sub?.cancel();
    _sub = accelerometerEventStream().listen((event) {
      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final linear = (magnitude - 9.80665).abs();
      _ema = (_alpha * linear) + ((1 - _alpha) * _ema);
      // רצפת רעש — טלפון על שידה
      _currentG = _ema < 0.12 ? 0.0 : _ema;
      if (!_controller.isClosed) {
        _controller.add(_currentG);
      }
    }, onError: (_) {
      // חיישן לא זמין (אמולטור) — נשארים על 0
    });
  }

  void injectForDemo(double g) {
    _currentG = g;
    _ema = g;
    if (!_controller.isClosed) {
      _controller.add(_currentG);
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
