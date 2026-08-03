class SensorSample {
  final DateTime at;
  final double movementG;
  final double? heartRateBpm;
  final double? hrvRmssd;

  const SensorSample({
    required this.at,
    required this.movementG,
    this.heartRateBpm,
    this.hrvRmssd,
  });

  SensorSample copyWith({
    DateTime? at,
    double? movementG,
    double? heartRateBpm,
    double? hrvRmssd,
  }) {
    return SensorSample(
      at: at ?? this.at,
      movementG: movementG ?? this.movementG,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      hrvRmssd: hrvRmssd ?? this.hrvRmssd,
    );
  }
}
