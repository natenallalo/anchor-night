import 'package:anchor_night/domain/personal_baseline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('personal baseline uses relative crisis threshold', () {
    const low = PersonalBaseline(restingHeartRate: 52, sampleCount: 50);
    const high = PersonalBaseline(restingHeartRate: 78, sampleCount: 50);

    expect(low.crisisHeartRateThreshold, lessThan(high.crisisHeartRateThreshold));
    expect(low.crisisHeartRateThreshold, greaterThanOrEqualTo(88));
    expect(high.crisisHeartRateThreshold, lessThanOrEqualTo(120));
  });
}
