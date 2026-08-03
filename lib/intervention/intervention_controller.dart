import 'dart:async';

import '../domain/intervention_config.dart';
import '../domain/safety_profile.dart';
import 'audio_anchor_player.dart';
import 'vibration_coach.dart';

enum InterventionStage { idle, vibrating, audio, completed, cancelled }

class InterventionController {
  final VibrationCoach vibration;
  final AudioAnchorPlayer audio;

  InterventionStage _stage = InterventionStage.idle;
  Timer? _audioDelay;
  Timer? _escalateTimer;
  DateTime? sleepStartedAt;
  void Function()? onEscalateToGrounding;

  InterventionController({
    VibrationCoach? vibration,
    AudioAnchorPlayer? audio,
  })  : vibration = vibration ?? VibrationCoach(),
        audio = audio ?? AudioAnchorPlayer();

  InterventionStage get stage => _stage;
  double get audioVolume => audio.volume;
  bool get isActive =>
      _stage == InterventionStage.vibrating ||
      _stage == InterventionStage.audio;

  Future<void> start(InterventionConfig config) async {
    await cancel();
    _stage = InterventionStage.vibrating;

    final useVibration = config.mode == InterventionMode.combined ||
        config.mode == InterventionMode.vibrationOnly;
    final suppressAudio = ClinicalSafety.shouldSuppressAudio(
      config: config,
      sleepStartedAt: sleepStartedAt,
      now: DateTime.now(),
    );
    final useAudio = !suppressAudio &&
        (config.mode == InterventionMode.combined ||
            config.mode == InterventionMode.audioOnly);

    if (useVibration) {
      await vibration.start(config);
    }

    final delay = config.mode == InterventionMode.combined
        ? const Duration(seconds: 7)
        : Duration.zero;

    if (useAudio) {
      _audioDelay = Timer(delay, () async {
        if (_stage == InterventionStage.cancelled) return;
        _stage = InterventionStage.audio;
        final custom = config.selectedAudioAnchorId == 'custom_voice'
            ? config.customAudioPath
            : null;
        await audio.startFadeIn(
          maxVolume: ClinicalSafety.cappedMaxVolume(config.intensity),
          preferredPath: custom,
          assetPath: custom == null ? config.builtInAssetPath : null,
        );
      });
    }

    if (config.allowAutoEscalateToGrounding) {
      _escalateTimer = Timer(
        Duration(seconds: config.escalateAfterSeconds),
        () {
          if (_stage == InterventionStage.cancelled) return;
          onEscalateToGrounding?.call();
        },
      );
    }
  }

  Future<void> cancel() async {
    _stage = InterventionStage.cancelled;
    _audioDelay?.cancel();
    _escalateTimer?.cancel();
    await vibration.stop();
    await audio.stop();
    _stage = InterventionStage.idle;
  }

  Future<void> dispose() async {
    await cancel();
    await audio.dispose();
  }
}
