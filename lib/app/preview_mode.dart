/// מצב צילומי מסך לחנות: ?preview=onboarding|night|morning|grounding
class PreviewMode {
  static String? get current {
    final preview = Uri.base.queryParameters['preview'];
    if (preview == null || preview.isEmpty) return null;
    return preview.toLowerCase();
  }

  static bool get enabled => current != null;

  static bool get skipOnboarding =>
      enabled && current != 'onboarding';

  static int? get initialTab {
    switch (current) {
      case 'morning':
        return 0;
      case 'night':
        return 1;
      case 'grounding':
        return 2;
      default:
        return null;
    }
  }
}
