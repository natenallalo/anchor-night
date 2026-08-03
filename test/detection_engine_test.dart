import 'package:anchor_night/detection/detection_engine.dart';
import 'package:anchor_night/domain/night_guard_state.dart';
import 'package:anchor_night/domain/personal_baseline.dart';
import 'package:anchor_night/domain/sensor_sample.dart';
import 'package:flutter_test/flutter_test.dart';

SensorSample sample({double hr = 62, double move = 0.05}) {
  return SensorSample(
    at: DateTime.now(),
    movementG: move,
    heartRateBpm: hr,
  );
}

void main() {
  group('DetectionEngine', () {
    test('enters sleep after sustained stillness and low HR', () {
      final engine = DetectionEngine(
        baseline: const PersonalBaseline(restingHeartRate: 60),
      );
      engine.markUserReadyForSleep();

      DetectionSnapshot? last;
      for (var i = 0; i < DetectionEngine.sleepConfirmCycles; i++) {
        last = engine.ingest(sample(hr: 58, move: 0.05));
      }

      expect(last!.signal, DetectionSignal.enteredSleep);
      expect(engine.phase, NightGuardPhase.sleeping);
    });

    test('movement alone does not trigger crisis', () {
      final engine = DetectionEngine(
        baseline: const PersonalBaseline(restingHeartRate: 60, sampleCount: 50),
      );
      engine.markSleepingManually();

      DetectionSnapshot? last;
      for (var i = 0; i < 5; i++) {
        last = engine.ingest(sample(hr: 62, move: 3.0));
      }

      expect(last!.signal, isNot(DetectionSignal.crisisSuspected));
      expect(engine.phase, NightGuardPhase.sleeping);
    });

    test('elevated HR relative to baseline triggers crisis', () {
      final engine = DetectionEngine(
        baseline: const PersonalBaseline(restingHeartRate: 60, sampleCount: 50),
      );
      engine.markSleepingManually();

      DetectionSnapshot? last;
      for (var i = 0; i < DetectionEngine.crisisConfirmCycles; i++) {
        last = engine.ingest(sample(hr: 100, move: 0.4));
      }

      expect(last!.signal, DetectionSignal.crisisSuspected);
      expect(engine.phase, NightGuardPhase.intervening);
    });

    test('calm after intervention returns to sleeping', () {
      final engine = DetectionEngine(
        baseline: const PersonalBaseline(restingHeartRate: 60, sampleCount: 50),
      );
      engine.markSleepingManually();
      for (var i = 0; i < DetectionEngine.crisisConfirmCycles; i++) {
        engine.ingest(sample(hr: 105, move: 1.0));
      }
      expect(engine.phase, NightGuardPhase.intervening);

      DetectionSnapshot? last;
      for (var i = 0; i < DetectionEngine.calmConfirmCycles; i++) {
        last = engine.ingest(sample(hr: 64, move: 0.05));
      }

      expect(last!.signal, DetectionSignal.calmAfterCrisis);
      expect(engine.phase, NightGuardPhase.sleeping);
    });
  });
}
