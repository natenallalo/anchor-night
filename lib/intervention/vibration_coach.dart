import 'package:vibration/vibration.dart';

import '../domain/intervention_config.dart';

class VibrationCoach {
  bool _active = false;

  bool get isActive => _active;

  Future<void> start(InterventionConfig config) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    _active = true;
    final pattern = _patternFor(config);
    // repeat: 0 = לולאה על האינדקס הראשון אחרי ההמתנה הראשונית
    await Vibration.vibrate(pattern: pattern, repeat: 0);
  }

  Future<void> stop() async {
    _active = false;
    try {
      await Vibration.cancel();
    } catch (_) {
      // אין רטט בסביבת בדיקה / דסקטופ
    }
  }

  /// מחזיר תבנית [wait, vibrate, wait, vibrate, ...]
  List<int> _patternFor(InterventionConfig config) {
    final gentle = config.intensity == StimulusIntensity.gentle;
    switch (config.vibrationStyle) {
      case VibrationStyle.breath46:
        // שאיפה רטט עדין ~4ש', הפסקה ~6ש' — חוזר
        final on = gentle ? 3800 : 4200;
        final off = gentle ? 6200 : 5800;
        return [0, on, off, on, off, on, off];
      case VibrationStyle.shortPulses:
        final pulse = gentle ? 120 : 280;
        return [0, pulse, 400, pulse, 400, pulse, 800, pulse, 400, pulse];
      case VibrationStyle.longSoft:
        final on = gentle ? 900 : 1800;
        return [0, on, 1400, on, 1400, on];
    }
  }
}
