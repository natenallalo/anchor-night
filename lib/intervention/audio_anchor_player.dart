import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../util/file_exists.dart';
import 'recording_result.dart';

/// נגן עוגן קולי עם עלייה הדרגתית בעוצמה — בלי הפתעות.
class AudioAnchorPlayer {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _fadeTimer;
  double _volume = 0;
  bool _playing = false;
  bool _recording = false;
  String? _customRecordingPath;
  String? _lastError;

  bool get isPlaying => _playing;
  bool get isRecording => _recording;
  double get volume => _volume;
  String? get customRecordingPath => _customRecordingPath;
  String? get lastError => _lastError;

  Future<void> setCustomRecordingPath(String? path) async {
    _customRecordingPath = path;
  }

  Future<RecordingResult> startRecordingAnchor() async {
    _lastError = null;
    try {
      // Stop any playback that would block the mic.
      await stop();

      final micOk = await _ensureMicPermission();
      if (!micOk) {
        _lastError = 'נדרשת הרשאת מיקרופון בהגדרות המכשיר';
        return RecordingResult(success: false, message: _lastError!);
      }

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final path = await _outputPath();
      final started = await _startWithFallbackEncoders(path);
      if (!started) {
        _lastError = _lastError ?? 'לא ניתן להתחיל הקלטה במכשיר זה';
        return RecordingResult(success: false, message: _lastError!);
      }

      _recording = true;
      return const RecordingResult(
        success: true,
        message: 'מקליט… לחצו שוב כדי לעצור ולשמור',
      );
    } catch (e) {
      _recording = false;
      _lastError = 'שגיאת הקלטה: $e';
      debugPrint('startRecordingAnchor failed: $e');
      return RecordingResult(success: false, message: _lastError!);
    }
  }

  Future<bool> _ensureMicPermission() async {
    try {
      // record package permission
      final recordOk = await _recorder.hasPermission();
      if (recordOk) return true;
    } catch (e) {
      debugPrint('recorder.hasPermission failed: $e');
    }

    try {
      var status = await Permission.microphone.status;
      if (status.isGranted) return true;
      status = await Permission.microphone.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    } catch (e) {
      debugPrint('permission_handler mic failed: $e');
      return false;
    }
  }

  Future<String> _outputPath() async {
    if (kIsWeb) {
      // Ignored by record on web; stop() returns a blob URL.
      return 'voice_anchor.wav';
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/voice_anchor_${DateTime.now().millisecondsSinceEpoch}.m4a';
    } catch (e) {
      // Fallback temp-ish name; some platforms still accept relative names.
      debugPrint('documents dir failed: $e');
      return 'voice_anchor_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
  }

  Future<bool> _startWithFallbackEncoders(String path) async {
    final configs = <RecordConfig>[
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
      ),
    ];

    for (final config in configs) {
      try {
        final supported = await _recorder.isEncoderSupported(config.encoder);
        if (!supported && !kIsWeb) {
          continue;
        }
        await _recorder.start(config, path: path);
        return true;
      } catch (e) {
        _lastError = 'encoder ${config.encoder.name} failed: $e';
        debugPrint(_lastError);
        try {
          if (await _recorder.isRecording()) {
            await _recorder.stop();
          }
        } catch (_) {}
      }
    }
    return false;
  }

  Future<RecordingResult> stopRecordingAnchor() async {
    try {
      if (!_recording && !await _recorder.isRecording()) {
        return const RecordingResult(
          success: false,
          message: 'לא הייתה הקלטה פעילה',
        );
      }
      final path = await _recorder.stop();
      _recording = false;
      if (path == null || path.isEmpty) {
        _lastError = 'ההקלטה נעצרה אך לא נשמר קובץ';
        return RecordingResult(success: false, message: _lastError!);
      }

      // On IO verify file; on web accept blob/http URLs.
      if (!kIsWeb && !fileExists(path) && !_looksLikeWebUrl(path)) {
        // Give FS a moment on slow devices.
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!fileExists(path)) {
          _lastError = 'הקובץ לא נמצא אחרי ההקלטה';
          return RecordingResult(success: false, message: _lastError!);
        }
      }

      _customRecordingPath = path;
      return RecordingResult(
        success: true,
        message: 'עוגן קולי נשמר',
        path: path,
      );
    } catch (e) {
      _recording = false;
      _lastError = 'שגיאה בעצירת הקלטה: $e';
      debugPrint(_lastError);
      return RecordingResult(success: false, message: _lastError!);
    }
  }

  bool _looksLikeWebUrl(String path) =>
      path.startsWith('blob:') ||
      path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('data:');

  Future<void> previewAsset(String assetPath, {double volume = 0.35}) async {
    await stop();
    try {
      await _player.setAsset(assetPath);
      await _player.setLoopMode(LoopMode.off);
      await _player.setVolume(volume);
      await _player.play();
      _playing = true;
      _volume = volume;
    } catch (e) {
      debugPrint('previewAsset failed: $e');
    }
  }

  Future<void> previewFile(String path, {double volume = 0.35}) async {
    await stop();
    if (!_looksLikeWebUrl(path) && !fileExists(path)) return;
    try {
      if (_looksLikeWebUrl(path)) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      await _player.setLoopMode(LoopMode.off);
      await _player.setVolume(volume);
      await _player.play();
      _playing = true;
      _volume = volume;
    } catch (e) {
      debugPrint('previewFile failed: $e');
    }
  }

  Future<void> startFadeIn({
    required double maxVolume,
    String? preferredPath,
    String? assetPath,
  }) async {
    await stop();
    _playing = true;
    _volume = 0.05;

    try {
      final preferred = preferredPath ?? _customRecordingPath;
      if (preferred != null &&
          (_looksLikeWebUrl(preferred) || fileExists(preferred))) {
        if (_looksLikeWebUrl(preferred)) {
          await _player.setUrl(preferred);
        } else {
          await _player.setFilePath(preferred);
        }
      } else if (assetPath != null) {
        await _player.setAsset(assetPath);
      } else {
        _startFadeTimer(maxVolume);
        return;
      }
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      await _player.play();
    } catch (e) {
      debugPrint('startFadeIn failed: $e');
    }

    _startFadeTimer(maxVolume);
  }

  void _startFadeTimer(double maxVolume) {
    _fadeTimer?.cancel();
    _fadeTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!_playing) {
        timer.cancel();
        return;
      }
      if (_volume >= maxVolume) {
        timer.cancel();
        return;
      }
      _volume = (_volume + 0.08).clamp(0.0, maxVolume);
      try {
        await _player.setVolume(_volume);
      } catch (_) {}
    });
  }

  Future<void> stop() async {
    _playing = false;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _volume = 0;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    _recording = false;
    await stop();
    await _player.dispose();
    await _recorder.dispose();
  }
}
