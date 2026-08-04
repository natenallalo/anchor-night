import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_night/domain/night_session.dart';
import 'package:anchor_night/services/insight_engine.dart';

void main() {
  test('InsightEngine returns guidance with empty history', () {
    final insight = InsightEngine().analyze(const []);
    expect(insight.whatMayHelp, isNotEmpty);
    expect(insight.confidence, lessThan(0.5));
  });

  test('InsightEngine prefers audio that helped', () {
    final sessions = [
      NightSession(
        id: '1',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 1, 6),
        interventionCount: 1,
        audioAnchorId: 'rain',
        intensity: 'gentle',
        checkIn: MorningCheckIn(
          restfulness: 4,
          interventionHelped: true,
          note: 'הגשם עזר',
          at: DateTime(2026, 1, 1, 7),
        ),
      ),
      NightSession(
        id: '2',
        startedAt: DateTime(2026, 1, 2),
        endedAt: DateTime(2026, 1, 2, 6),
        interventionCount: 2,
        audioAnchorId: 'rain',
        intensity: 'gentle',
        usedLiveHeartRate: true,
        checkIn: MorningCheckIn(
          restfulness: 5,
          interventionHelped: true,
          note: '',
          at: DateTime(2026, 1, 2, 7),
        ),
      ),
      NightSession(
        id: '3',
        startedAt: DateTime(2026, 1, 3),
        endedAt: DateTime(2026, 1, 3, 6),
        interventionCount: 3,
        audioAnchorId: 'white_noise',
        intensity: 'firm',
        checkIn: MorningCheckIn(
          restfulness: 2,
          interventionHelped: false,
          note: '',
          at: DateTime(2026, 1, 3, 7),
        ),
      ),
    ];
    final insight = InsightEngine().analyze(sessions);
    expect(insight.whatHelped.join(' '), contains('גשם'));
    expect(insight.confidence, greaterThan(0.3));
  });
}
