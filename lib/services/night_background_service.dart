import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// שומר את תהליך האפליקציה חי בלילה דרך Foreground Service (בעיקר אנדרואיד).
class NightBackgroundService {
  bool _initialized = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_initialized || !_isMobile) return;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'anchor_night_guard',
        channelName: 'הגנת לילה',
        channelDescription: 'התראה שקטה בזמן ניטור שינה',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  Future<bool> ensureNotificationPermission() async {
    if (!_isAndroid) return true;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> start() async {
    await init();
    await ensureNotificationPermission();

    if (!_isAndroid) {
      // iOS / web: אין FGS זהה — מסתמכים על background modes באפל
      return _isMobile;
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'עוגן לילה',
        notificationText: 'הגנת לילה פעילה — מנטרת בעדינות',
      );
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 2407,
      notificationTitle: 'עוגן לילה',
      notificationText: 'הגנת לילה פעילה — מנטרת בעדינות',
      notificationButtons: const [
        NotificationButton(id: 'open', text: 'פתח'),
      ],
      callback: nightGuardStartCallback,
      serviceTypes: [ForegroundServiceTypes.health],
    );
    return result is ServiceRequestSuccess;
  }

  Future<void> stop() async {
    if (!_isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<bool> get isRunning async {
    if (!_isAndroid) return false;
    return FlutterForegroundTask.isRunningService;
  }
}

@pragma('vm:entry-point')
void nightGuardStartCallback() {
  FlutterForegroundTask.setTaskHandler(_NightGuardTaskHandler());
}

class _NightGuardTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'עוגן לילה',
      notificationText: 'הגנת לילה פעילה',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
