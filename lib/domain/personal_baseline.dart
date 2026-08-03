import 'dart:math' as math;

/// Baseline אישי שנבנה משינה רגועה — קריטי להפחתת אזעקות שווא.
class PersonalBaseline {
  final double restingHeartRate;
  final double sleepMovementMean;
  final double sleepMovementStd;
  final int sampleCount;
  final DateTime? updatedAt;

  const PersonalBaseline({
    this.restingHeartRate = 62,
    this.sleepMovementMean = 0.12,
    this.sleepMovementStd = 0.08,
    this.sampleCount = 0,
    this.updatedAt,
  });

  bool get isCalibrated => sampleCount >= 40;

  /// סף משבר יחסי לדופק — לא מספר קשיח לכולם.
  double get crisisHeartRateThreshold {
    final relative = restingHeartRate * 1.35;
    return relative.clamp(88, 120);
  }

  double get sleepEntryHeartRateThreshold {
    return (restingHeartRate + 8).clamp(58, 85);
  }

  double get awakeHeartRateThreshold {
    return (restingHeartRate + 14).clamp(68, 95);
  }

  double get crisisMovementThreshold {
    final relative = sleepMovementMean + (sleepMovementStd * 4.5);
    return relative.clamp(1.4, 3.5);
  }

  double get stillnessThreshold {
    final relative = sleepMovementMean + (sleepMovementStd * 1.2);
    return relative.clamp(0.18, 0.45);
  }

  PersonalBaseline absorbSleepSample({
    required double heartRate,
    required double movementG,
  }) {
    final n = sampleCount + 1;
    final hr = ((restingHeartRate * sampleCount) + heartRate) / n;
    final mean = ((sleepMovementMean * sampleCount) + movementG) / n;
    final varianceEstimate = ((sleepMovementStd * sleepMovementStd * sampleCount) +
            ((movementG - mean) * (movementG - mean))) /
        n;
    final std = varianceEstimate <= 0
        ? sleepMovementStd
        : math.sqrt(varianceEstimate).clamp(0.05, 1.5);
    return PersonalBaseline(
      restingHeartRate: hr,
      sleepMovementMean: mean,
      sleepMovementStd: std.toDouble(),
      sampleCount: n,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'restingHeartRate': restingHeartRate,
        'sleepMovementMean': sleepMovementMean,
        'sleepMovementStd': sleepMovementStd,
        'sampleCount': sampleCount,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory PersonalBaseline.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PersonalBaseline();
    return PersonalBaseline(
      restingHeartRate: (json['restingHeartRate'] as num?)?.toDouble() ?? 62,
      sleepMovementMean: (json['sleepMovementMean'] as num?)?.toDouble() ?? 0.12,
      sleepMovementStd: (json['sleepMovementStd'] as num?)?.toDouble() ?? 0.08,
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
