import 'package:anchor_night/domain/night_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('night session json roundtrip keeps counts', () {
    final session = NightSession(
      id: 'abc',
      startedAt: DateTime(2026, 8, 3, 23),
      endedAt: DateTime(2026, 8, 4, 6),
      interventionCount: 2,
      groundingCount: 1,
      usedLiveHeartRate: true,
      checkIn: MorningCheckIn(
        restfulness: 4,
        interventionHelped: true,
        note: 'עבר בסדר',
        at: DateTime(2026, 8, 4, 7),
      ),
    );

    final restored = NightSession.fromJson(session.toJson());
    expect(restored.interventionCount, 2);
    expect(restored.groundingCount, 1);
    expect(restored.checkIn?.restfulness, 4);
    expect(restored.usedLiveHeartRate, isTrue);
  });
}
