import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum BreathPhase { inhale, hold, exhale, rest }

/// מאמן נשימה 4-2-6 עם הדרכה קולית רגועה.
class BreathingVoiceCoach {
  final FlutterTts _tts = FlutterTts();
  Timer? _timer;
  BreathPhase _phase = BreathPhase.inhale;
  int _phaseSecondsLeft = 4;
  bool _running = false;
  bool _ready = false;
  void Function(BreathPhase phase, int secondsLeft)? onTick;

  BreathPhase get phase => _phase;
  int get secondsLeft => _phaseSecondsLeft;
  bool get isRunning => _running;

  Future<void> prepare() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('he-IL');
    } catch (_) {
      try {
        await _tts.setLanguage('he');
      } catch (_) {
        await _tts.setLanguage('en-US');
      }
    }
    await _tts.setSpeechRate(0.38);
    await _tts.setVolume(0.85);
    await _tts.setPitch(0.92);
    if (!kIsWeb) {
      await _tts.awaitSpeakCompletion(true);
    }
    _ready = true;
  }

  Future<void> start() async {
    if (_running) return;
    await prepare();
    _running = true;
    _phase = BreathPhase.inhale;
    _phaseSecondsLeft = 4;
    onTick?.call(_phase, _phaseSecondsLeft);
    await _speakForPhase(_phase);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onSecond());
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }

  Future<void> _onSecond() async {
    if (!_running) return;
    _phaseSecondsLeft -= 1;
    if (_phaseSecondsLeft <= 0) {
      _phase = switch (_phase) {
        BreathPhase.inhale => BreathPhase.hold,
        BreathPhase.hold => BreathPhase.exhale,
        BreathPhase.exhale => BreathPhase.rest,
        BreathPhase.rest => BreathPhase.inhale,
      };
      _phaseSecondsLeft = switch (_phase) {
        BreathPhase.inhale => 4,
        BreathPhase.hold => 2,
        BreathPhase.exhale => 6,
        BreathPhase.rest => 2,
      };
      await _speakForPhase(_phase);
    }
    onTick?.call(_phase, _phaseSecondsLeft);
  }

  Future<void> _speakForPhase(BreathPhase phase) async {
    final text = switch (phase) {
      BreathPhase.inhale => 'שאפו לאט דרך האף. ארבע שניות.',
      BreathPhase.hold => 'החזיקו רגע. אתם בטוחים.',
      BreathPhase.exhale => 'נשפו לאט מהפה. שש שניות. שחררו.',
      BreathPhase.rest => 'מנוחה קצרה. ממשיכים יחד.',
    };
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // TTS may be unavailable on some platforms; UI still guides.
    }
  }

  static String labelHe(BreathPhase phase) => switch (phase) {
        BreathPhase.inhale => 'שאיפה',
        BreathPhase.hold => 'החזקה',
        BreathPhase.exhale => 'נשיפה',
        BreathPhase.rest => 'מנוחה',
      };
}
