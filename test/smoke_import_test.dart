import 'package:anchor_night/app/app.dart';
import 'package:anchor_night/features/night_guard/night_guard_controller.dart';
import 'package:anchor_night/services/night_background_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core types resolve', () {
    expect(NightGuardController, isNotNull);
    expect(AnchorNightApp, isNotNull);
    expect(NightBackgroundService, isNotNull);
  });
}
