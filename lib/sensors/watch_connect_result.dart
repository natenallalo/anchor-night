class WatchConnectResult {
  final bool success;
  final bool needsHealthConnectInstall;
  final String message;

  const WatchConnectResult({
    required this.success,
    required this.message,
    this.needsHealthConnectInstall = false,
  });
}
