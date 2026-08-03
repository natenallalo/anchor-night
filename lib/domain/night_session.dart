class MorningCheckIn {
  final int restfulness; // 1-5
  final bool interventionHelped;
  final String note;
  final DateTime at;

  const MorningCheckIn({
    required this.restfulness,
    required this.interventionHelped,
    required this.note,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'restfulness': restfulness,
        'interventionHelped': interventionHelped,
        'note': note,
        'at': at.toIso8601String(),
      };

  factory MorningCheckIn.fromJson(Map<String, dynamic> json) {
    return MorningCheckIn(
      restfulness: (json['restfulness'] as num?)?.toInt() ?? 3,
      interventionHelped: json['interventionHelped'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NightSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int interventionCount;
  final int groundingCount;
  final bool usedLiveHeartRate;
  final MorningCheckIn? checkIn;

  const NightSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.interventionCount = 0,
    this.groundingCount = 0,
    this.usedLiveHeartRate = false,
    this.checkIn,
  });

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  NightSession copyWith({
    DateTime? endedAt,
    int? interventionCount,
    int? groundingCount,
    bool? usedLiveHeartRate,
    MorningCheckIn? checkIn,
  }) {
    return NightSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      interventionCount: interventionCount ?? this.interventionCount,
      groundingCount: groundingCount ?? this.groundingCount,
      usedLiveHeartRate: usedLiveHeartRate ?? this.usedLiveHeartRate,
      checkIn: checkIn ?? this.checkIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'interventionCount': interventionCount,
        'groundingCount': groundingCount,
        'usedLiveHeartRate': usedLiveHeartRate,
        'checkIn': checkIn?.toJson(),
      };

  factory NightSession.fromJson(Map<String, dynamic> json) {
    return NightSession(
      id: json['id'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      interventionCount: (json['interventionCount'] as num?)?.toInt() ?? 0,
      groundingCount: (json['groundingCount'] as num?)?.toInt() ?? 0,
      usedLiveHeartRate: json['usedLiveHeartRate'] as bool? ?? false,
      checkIn: json['checkIn'] is Map<String, dynamic>
          ? MorningCheckIn.fromJson(json['checkIn'] as Map<String, dynamic>)
          : null,
    );
  }
}
