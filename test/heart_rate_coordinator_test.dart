import 'package:anchor_night/sensors/heart_rate_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coordinator starts in demo mode', () async {
    final coordinator = HeartRateCoordinator();
    await coordinator.start();
    expect(coordinator.mode, HeartRateMode.demo);
    expect(coordinator.isLiveHardware, isFalse);
    await coordinator.stop();
    coordinator.dispose();
  });

  test('demo override takes precedence', () async {
    final coordinator = HeartRateCoordinator();
    await coordinator.start();
    final values = <double>[];
    final sub = coordinator.heartRateBpm.listen(values.add);

    coordinator.setDemoOverride(110);
    await Future<void>.delayed(Duration.zero);

    expect(values, isNotEmpty);
    expect(values.last, 110);

    await sub.cancel();
    await coordinator.stop();
    coordinator.dispose();
  });
}
