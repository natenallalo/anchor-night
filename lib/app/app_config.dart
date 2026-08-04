import 'package:flutter/foundation.dart';

/// שערי פרודקשן — כלי דמו רק בבילד דיבאג.
class AppConfig {
  static bool get showDemoTools => kDebugMode;

  static const appName = 'עוגן לילה';
  static const appNameEn = 'AnchorNight';
  static const versionLabel = '0.3.0';
  static const supportEmail = 'privacy@anchornight.app';

  /// קישור ציבורי למדיניות פרטיות — עדכנו אחרי GitHub Pages.
  static const privacyPolicyUrl =
      'https://natenallalo.github.io/anchor-night/privacy.html';

  static const packageId = 'com.anchornight.app.anchor_night';
}
