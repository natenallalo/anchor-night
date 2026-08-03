import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../util/file_exists.dart';

/// נגן עוגן קולי עם עלייה הדרגתית בעוצמה — בלי הפתעות.
class AudioAnchorPlayer {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _fadeTimer;
  double _volume = 0;
  bool _playing = false;
  String? _customRecordingPath;

  bool get isPlaying => _playing;
  double get volume => _volume;
  String? get customRecordingPath => _customRecordingPath;

  Future<void> setCustomRecordingPath(String? path) async {
    _customRecordingPath = path;
  }

  Future<bool> startRecordingAnchor() async {
    if (!await _recorder.hasPermission()) {
      return false;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/voice_anchor_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    return true;
  }

  Future<String?> stopRecordingAnchor() async {
    final path = await _recorder.stop();
    if (path != null && fileExists(path)) {
      _customRecordingPath = path;
      return path;
    }
    return null;
  }

  Future<void> previewAsset(String assetPath, {double volume = 0.35}) async {
    await stop();
    try {
      await _player.setAsset(assetPath);
      await _player.setLoopMode(LoopMode.off);
      await _player.setVolume(volume);
      await _player.play();
      _playing = true;
      _volume = volume;
    } catch (_) {}
  }

  Future<void> previewFile(String path, {double volume = 0.35}) async {
    await stop();
    if (!fileExists(path)) return;
    try {
      await _player.setFilePath(path);
      await _player.setLoopMode(LoopMode.off);
      await _player.setVolume(volume);
      await _player.play();
      _playing = true;
      _volume = volume;
    } catch (_) {}
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
      if (preferredPath != null && fileExists(preferredPath)) {
        await _player.setFilePath(preferredPath);
      } else if (assetPath != null) {
        await _player.setAsset(assetPath);
      } else if (_customRecordingPath != null &&
          fileExists(_customRecordingPath!)) {
        await _player.setFilePath(_customRecordingPath!);
      } else {
        // אין מקור שמע — fade וירטואלי ל־UI בלבד
        _startFadeTimer(maxVolume);
        return;
      }
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      await _player.play();
    } catch (_) {
      // נמשיך עם fade וירטואלי
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
    await stop();
    await _player.dispose();
    await _recorder.dispose();
  }
}
