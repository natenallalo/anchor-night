import 'package:anchor_night/detection/detection_engine.dart';
import 'package:anchor_night/domain/intervention_config.dart';
import 'package:anchor_night/domain/night_guard_state.dart';
import 'package:anchor_night/domain/personal_baseline.dart';
import 'package:anchor_night/domain/safety_profile.dart';
import 'package:anchor_night/domain/sensor_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClinicalSafety', () {
    test('suppresses audio in quiet window after sleep', () {
      final sleepAt = DateTime(2026, 8, 3, 23);
      final suppress = ClinicalSafety.shouldSuppressAudio(
        config: const InterventionConfig(audioQuietMinutesAfterSleep: 10),
        sleepStartedAt: sleepAt,
        now: sleepAt.add(const Duration(minutes: 3)),
      );
      expect(suppress, isTrue);
    });

    test('allows audio after quiet window', () {
      final sleepAt = DateTime(2026, 8, 3, 23);
      final suppress = ClinicalSafety.shouldSuppressAudio(
        config: const InterventionConfig(audioQuietMinutesAfterSleep: 10),
        sleepStartedAt: sleepAt,
        now: sleepAt.add(const Duration(minutes: 11)),
      );
      expect(suppress, isFalse);
    });

    test('caps volume for gentle intensity', () {
      expect(ClinicalSafety.cappedMaxVolume(StimulusIntensity.gentle), 0.40);
      expect(ClinicalSafety.cappedMaxVolume(StimulusIntensity.firm), 0.65);
    });
  });

  group('Bed partner mode', () {
    test('movement alone never triggers crisis', () {
      final engine = DetectionEngine(
        baseline: const PersonalBaseline(restingHeartRate: 60, sampleCount: 50),
        bedPartnerMode: true,
      );
      engine.markSleepingManually();
      DetectionSnapshot? last;
      for (var i = 0; i < 6; i++) {
        last = engine.ingest(
          SensorSample(
            at: DateTime.now(),
            movementG: 3.5,
            heartRateBpm: 62,
          ),
        );
      }
      expect(last!.signal, isNot(DetectionSignal.crisisSuspected));
      expect(engine.phase, NightGuardPhase.sleeping);
    });

    test('elevated HR still triggers after more confirm cycles', () {
      final engine = DetectionEngine(
        baseline: const PersonalBaseline(restingHeartRate: 60, sampleCount: 50),
        bedPartnerMode: true,
      );
      engine.markSleepingManually();
      DetectionSnapshot? last;
      for (var i = 0; i < DetectionEngine.crisisConfirmCyclesBedPartner; i++) {
        last = engine.ingest(
          SensorSample(
            at: DateTime.now(),
            movementG: 0.2,
            heartRateBpm: 105,
          ),
        );
      }
      expect(last!.signal, DetectionSignal.crisisSuspected);
      expect(engine.phase, NightGuardPhase.intervening);
    });
  });
}
