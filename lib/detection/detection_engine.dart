import '../domain/night_guard_state.dart';
import '../domain/personal_baseline.dart';
import '../domain/sensor_sample.dart';

enum DetectionSignal {
  none,
  enteredSleep,
  crisisSuspected,
  calmAfterCrisis,
  fullWakeup,
  daytimeHighMovementReset,
}

class DetectionSnapshot {
  final NightGuardPhase phase;
  final DetectionSignal signal;
  final int stillnessCycles;
  final int crisisCycles;
  final int calmCycles;
  final int wakeupCycles;
  final String reason;

  const DetectionSnapshot({
    required this.phase,
    required this.signal,
    required this.stillnessCycles,
    required this.crisisCycles,
    required this.calmCycles,
    required this.wakeupCycles,
    required this.reason,
  });
}

/// מנוע זיהוי טהור — בלי Flutter, ניתן לבדיקות יחידה.
class DetectionEngine {
  NightGuardPhase _phase = NightGuardPhase.idle;
  PersonalBaseline _baseline;
  bool bedPartnerMode;

  int _stillnessCycles = 0;
  int _highMovementWhileAwake = 0;
  int _crisisCycles = 0;
  int _calmCycles = 0;
  int _wakeupCycles = 0;

  /// כמה דגימות רצופות נדרשות (כל דגימה ~3 שנ')
  static const int sleepConfirmCycles = 12; // ~36s stillness+low HR
  static const int crisisConfirmCycles = 2; // ~6s — מהיר אבל לא רעש חד־פעמי
  static const int crisisConfirmCyclesBedPartner = 4; // ~12s
  static const int calmConfirmCycles = 8; // ~24s
  static const int wakeupConfirmCycles = 8; // ~24s
  static const int awakeHighMovementReset = 5;

  DetectionEngine({
    PersonalBaseline? baseline,
    this.bedPartnerMode = false,
  }) : _baseline = baseline ?? const PersonalBaseline();

  NightGuardPhase get phase => _phase;
  PersonalBaseline get baseline => _baseline;

  int get _crisisNeeded =>
      bedPartnerMode ? crisisConfirmCyclesBedPartner : crisisConfirmCycles;

  void updateBaseline(PersonalBaseline baseline) => _baseline = baseline;

  void setBedPartnerMode(bool enabled) => bedPartnerMode = enabled;

  void forcePhase(NightGuardPhase phase) {
    _phase = phase;
    _resetCounters();
  }

  void markUserReadyForSleep() {
    _phase = NightGuardPhase.preSleep;
    _resetCounters();
  }

  void markSleepingManually() {
    _phase = NightGuardPhase.sleeping;
    _resetCounters();
  }

  void acknowledgeCrisisHandled() {
    _phase = NightGuardPhase.sleeping;
    _resetCounters();
  }

  void stopAllToIdle() {
    _phase = NightGuardPhase.idle;
    _resetCounters();
  }

  DetectionSnapshot ingest(SensorSample sample) {
    final hr = sample.heartRateBpm ?? _baseline.restingHeartRate;
    final move = sample.movementG;

    switch (_phase) {
      case NightGuardPhase.idle:
      case NightGuardPhase.preSleep:
        return _ingestAwake(hr, move);
      case NightGuardPhase.sleeping:
        return _ingestSleeping(hr, move);
      case NightGuardPhase.intervening:
        return _ingestIntervening(hr, move);
      case NightGuardPhase.grounding:
        return _ingestGrounding(hr, move);
      case NightGuardPhase.morning:
        return _snapshot(DetectionSignal.none, 'בוקר — אין ניטור משבר');
    }
  }

  DetectionSnapshot _ingestAwake(double hr, double move) {
    if (move >= _baseline.crisisMovementThreshold) {
      _highMovementWhileAwake++;
      _stillnessCycles = 0;
      if (_highMovementWhileAwake >= awakeHighMovementReset) {
        _highMovementWhileAwake = 0;
        return _snapshot(
          DetectionSignal.daytimeHighMovementReset,
          'תנועה גבוהה בזמן ערות — איפוס מונים',
        );
      }
    } else {
      _highMovementWhileAwake = 0;
    }

    final still = move < _baseline.stillnessThreshold;
    final lowHr = hr <= _baseline.sleepEntryHeartRateThreshold;
    if (still && lowHr) {
      _stillnessCycles++;
      if (_stillnessCycles >= sleepConfirmCycles) {
        _phase = NightGuardPhase.sleeping;
        _resetCounters();
        return _snapshot(
          DetectionSignal.enteredSleep,
          'כניסה לשינה: דופק נמוך + חוסר תנועה ממושך',
        );
      }
    } else {
      _stillnessCycles = 0;
    }

    return _snapshot(
      DetectionSignal.none,
      'ממתין לשינה (${_stillnessCycles}/$sleepConfirmCycles)',
    );
  }

  DetectionSnapshot _ingestSleeping(double hr, double move) {
    // יקיצה הדרגתית
    final mildMove = move >= (_baseline.stillnessThreshold * 1.4) &&
        move < _baseline.crisisMovementThreshold;
    final awakeHr = hr >= _baseline.awakeHeartRateThreshold;
    if (mildMove && awakeHr) {
      _wakeupCycles++;
      if (_wakeupCycles >= wakeupConfirmCycles) {
        _phase = NightGuardPhase.morning;
        _resetCounters();
        return _snapshot(
          DetectionSignal.fullWakeup,
          'יקיצה מלאה — סיום הגנת לילה',
        );
      }
    } else {
      _wakeupCycles = 0;
    }

    final moveThreshold = bedPartnerMode
        ? _baseline.crisisMovementThreshold * 1.35
        : _baseline.crisisMovementThreshold;
    final crisisHr = hr >= _baseline.crisisHeartRateThreshold;
    final crisisMove = move >= moveThreshold;
    // תנועה לבד לא פותחת משבר. במצב שותף — רק דופק גבוה מאושר.
    final realCrisis = bedPartnerMode
        ? crisisHr
        : (crisisHr ||
            (crisisMove && hr >= (_baseline.restingHeartRate * 1.2)));

    if (realCrisis) {
      _crisisCycles++;
      if (_crisisCycles >= _crisisNeeded) {
        _phase = NightGuardPhase.intervening;
        _resetCounters();
        return _snapshot(
          DetectionSignal.crisisSuspected,
          bedPartnerMode
              ? 'מצב שותף: חריגת דופק מאושרת'
              : (crisisHr
                  ? 'חריגת דופק יחסית לבסיס האישי'
                  : 'תנועה חריגה + עליית דופק'),
        );
      }
    } else {
      _crisisCycles = 0;
      // כיול שקט בזמן שינה יציבה
      if (move < _baseline.stillnessThreshold &&
          hr <= _baseline.sleepEntryHeartRateThreshold) {
        _baseline = _baseline.absorbSleepSample(
          heartRate: hr,
          movementG: move,
        );
      }
    }

    return _snapshot(
      DetectionSignal.none,
      'שינה תחת הגנה${_baseline.isCalibrated ? '' : ' · בכיול'}',
    );
  }

  DetectionSnapshot _ingestIntervening(double hr, double move) {
    final calm = hr < (_baseline.crisisHeartRateThreshold - 8) &&
        move < _baseline.stillnessThreshold;
    if (calm) {
      _calmCycles++;
      if (_calmCycles >= calmConfirmCycles) {
        _phase = NightGuardPhase.sleeping;
        _resetCounters();
        return _snapshot(
          DetectionSignal.calmAfterCrisis,
          'מדדים נרגעו — חזרה להגנה שקטה',
        );
      }
    } else {
      _calmCycles = 0;
    }

    // יקיצה מתוך התערבות
    if (hr >= _baseline.awakeHeartRateThreshold &&
        move >= (_baseline.stillnessThreshold * 1.5) &&
        move < _baseline.crisisMovementThreshold) {
      _wakeupCycles++;
      if (_wakeupCycles >= wakeupConfirmCycles) {
        _phase = NightGuardPhase.morning;
        _resetCounters();
        return _snapshot(DetectionSignal.fullWakeup, 'יקיצה במהלך התערבות');
      }
    } else {
      _wakeupCycles = 0;
    }

    return _snapshot(
      DetectionSignal.none,
      'התערבות פעילה (${_calmCycles}/$calmConfirmCycles לרגיעה)',
    );
  }

  DetectionSnapshot _ingestGrounding(double hr, double move) {
    final calm = hr < (_baseline.crisisHeartRateThreshold - 10) &&
        move < _baseline.stillnessThreshold;
    if (calm) {
      _calmCycles++;
      if (_calmCycles >= calmConfirmCycles) {
        _phase = NightGuardPhase.sleeping;
        _resetCounters();
        return _snapshot(
          DetectionSignal.calmAfterCrisis,
          'יציאה מקרקוע — חזרה להגנה',
        );
      }
    } else {
      _calmCycles = 0;
    }
    return _snapshot(
      DetectionSignal.none,
      'במצב קרקוע — שליטה בידי המשתמש',
    );
  }

  void enterGrounding() {
    _phase = NightGuardPhase.grounding;
    _crisisCycles = 0;
    _calmCycles = 0;
  }

  void _resetCounters() {
    _stillnessCycles = 0;
    _highMovementWhileAwake = 0;
    _crisisCycles = 0;
    _calmCycles = 0;
    _wakeupCycles = 0;
  }

  DetectionSnapshot _snapshot(DetectionSignal signal, String reason) {
    return DetectionSnapshot(
      phase: _phase,
      signal: signal,
      stillnessCycles: _stillnessCycles,
      crisisCycles: _crisisCycles,
      calmCycles: _calmCycles,
      wakeupCycles: _wakeupCycles,
      reason: reason,
    );
  }
}
