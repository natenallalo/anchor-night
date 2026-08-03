enum NightGuardPhase {
  idle,
  preSleep,
  sleeping,
  intervening,
  grounding,
  morning,
}

extension NightGuardPhaseX on NightGuardPhase {
  String get hebrewLabel {
    switch (this) {
      case NightGuardPhase.idle:
        return 'מוכן — ממתין לכניסה לשינה';
      case NightGuardPhase.preSleep:
        return 'בדיקת כשירות לפני שינה';
      case NightGuardPhase.sleeping:
        return 'הגנה פעילה — זוהתה שינה';
      case NightGuardPhase.intervening:
        return 'התערבות עדינה פעילה';
      case NightGuardPhase.grounding:
        return 'מצב קרקוע — נדרשת תמיכה';
      case NightGuardPhase.morning:
        return 'בוקר — הגנת הלילה הסתיימה';
    }
  }

  bool get isProtecting =>
      this == NightGuardPhase.sleeping ||
      this == NightGuardPhase.intervening ||
      this == NightGuardPhase.grounding;
}
