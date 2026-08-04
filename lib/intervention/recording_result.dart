class RecordingResult {
  final bool success;
  final String message;
  final String? path;

  const RecordingResult({
    required this.success,
    required this.message,
    this.path,
  });
}
