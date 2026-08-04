import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

enum BreathPhase { inhale, hold, exhale, rest }

/// מאמן נשימה 4-2-6 עם הדרכה קולית.
/// משתמש בעיקר בקובצי קול מוכנים (אמין), ו־TTS רק כגיבוי.
class BreathingVoiceCoach {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  BreathPhase _phase = BreathPhase.inhale;
  int _phaseSecondsLeft = 4;
  bool _running = false;
  bool _ready = false;
  bool _ttsReady = false;
  bool _speaking = false;
  String _status = '';

  void Function(BreathPhase phase, int secondsLeft)? onTick;
  void Function(String status)? onStatus;

  BreathPhase get phase => _phase;
  int get secondsLeft => _phaseSecondsLeft;
  bool get isRunning => _running;
  String get status => _status;

  static const _clips = <BreathPhase, String>{
    BreathPhase.inhale: 'assets/audio/voice/inhale.mp3',
    BreathPhase.hold: 'assets/audio/voice/hold.mp3',
    BreathPhase.exhale: 'assets/audio/voice/exhale.mp3',
    BreathPhase.rest: 'assets/audio/voice/rest.mp3',
  };
  static const _introClip = 'assets/audio/voice/intro.mp3';

  Future<void> prepare() async {
    if (_ready) return;
    try {
      await _player.setVolume(0.9);
      await _player.setLoopMode(LoopMode.off);
    } catch (_) {}
    await _prepareTtsFallback();
    _ready = true;
  }

  Future<void> _prepareTtsFallback() async {
    try {
      await _tts.awaitSpeakCompletion(false);
      if (!kIsWeb) {
        try {
          await _tts.setSharedInstance(true);
        } catch (_) {}
        try {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        } catch (_) {}
      }
      final langs = <String>['he-IL', 'iw-IL', 'he', 'en-US'];
      for (final lang in langs) {
        try {
          final available = await _tts.isLanguageAvailable(lang);
          if (available == true) {
            await _tts.setLanguage(lang);
            _ttsReady = true;
            break;
          }
        } catch (_) {}
      }
      if (!_ttsReady) {
        await _tts.setLanguage('en-US');
        _ttsReady = true;
      }
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(0.9);
      await _tts.setPitch(0.95);
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> start() async {
    if (_running) return;
    await prepare();
    _running = true;
    _phase = BreathPhase.inhale;
    _phaseSecondsLeft = 4;
    _setStatus('הדרכה קולית פעילה');
    onTick?.call(_phase, _phaseSecondsLeft);

    // Start the phase clock immediately — never block on audio.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onSecond());

    // Intro then first cue (fire-and-forget).
    unawaited(_playSequence([_introClip, _clips[BreathPhase.inhale]!]));
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _speaking = false;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    _setStatus('');
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player.dispose();
    } catch (_) {}
  }

  void _onSecond() {
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
      unawaited(_speakForPhase(_phase));
    }
    onTick?.call(_phase, _phaseSecondsLeft);
  }

  Future<void> _speakForPhase(BreathPhase phase) async {
    final clip = _clips[phase];
    if (clip != null) {
      final ok = await _playClip(clip);
      if (ok) return;
    }
    await _speakTtsFallback(phase);
  }

  Future<void> _playSequence(List<String> assets) async {
    for (final asset in assets) {
      if (!_running) return;
      final ok = await _playClip(asset);
      if (!ok) {
        // If clips fail, fall back once for current phase.
        await _speakTtsFallback(_phase);
        return;
      }
    }
  }

  Future<bool> _playClip(String assetPath) async {
    if (_speaking) {
      try {
        await _player.stop();
      } catch (_) {}
    }
    _speaking = true;
    try {
      await _player.setAsset(assetPath);
      await _player.setVolume(0.95);
      await _player.seek(Duration.zero);
      await _player.play();
      // Wait briefly for clip end; never hang the coach forever.
      await _player.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 8));
      _speaking = false;
      return true;
    } catch (e) {
      _speaking = false;
      _setStatus('מעבר לגיבוי קולי');
      return false;
    }
  }

  Future<void> _speakTtsFallback(BreathPhase phase) async {
    if (!_ttsReady) {
      _setStatus('הדרכה על המסך פעילה (קול מערכת לא זמין)');
      return;
    }
    final text = switch (phase) {
      BreathPhase.inhale => 'שאפו לאט דרך האף. ארבע שניות.',
      BreathPhase.hold => 'החזיקו רגע. אתם בטוחים.',
      BreathPhase.exhale => 'נשפו לאט מהפה. שש שניות. שחררו.',
      BreathPhase.rest => 'מנוחה קצרה. ממשיכים יחד.',
    };
    try {
      await _tts.stop();
      // Do not await completion — avoids freezing the coach.
      // ignore: unawaited_futures
      _tts.speak(text);
    } catch (_) {
      _setStatus('הדרכה על המסך פעילה');
    }
  }

  void _setStatus(String value) {
    _status = value;
    onStatus?.call(value);
  }

  static String labelHe(BreathPhase phase) => switch (phase) {
        BreathPhase.inhale => 'שאיפה',
        BreathPhase.hold => 'החזקה',
        BreathPhase.exhale => 'נשיפה',
        BreathPhase.rest => 'מנוחה',
      };

  static String instructionHe(BreathPhase phase) => switch (phase) {
        BreathPhase.inhale => 'שאפו לאט דרך האף',
        BreathPhase.hold => 'החזיקו בעדינות — אתם בטוחים',
        BreathPhase.exhale => 'נשפו לאט מהפה ושחררו',
        BreathPhase.rest => 'מנוחה קצרה לפני הסיבוב הבא',
      };
}
