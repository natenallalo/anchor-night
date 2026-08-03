import 'intervention_config.dart';

/// הנחיות בטיחות בהשראת עקרונות טיפול בטראומה — לא תחליף לייעוץ מקצועי.
class ClinicalSafety {
  static const disclaimerHe =
      'עוגן לילה הוא כלי תמיכה בלבד. אינו אבחון או טיפול. '
      'במצוקה חריפה פנו לגורם מקצועי או לקווי סיוע.';

  static const disclaimerEn =
      'AnchorNight is a support tool only — not diagnosis or treatment. '
      'In acute distress contact a professional or crisis lines.';

  static const guidelinesHe = [
    'התחילו תמיד בעוצמה "חלש ועדין".',
    'העדיפו רטט לפני קול — קול עלול להפתיע.',
    'אל תפעילו הקלטת קול אנושי אם היא מעוררת זיכרון טראומטי.',
    'אם יש שותף/ה במיטה — הפעילו "מצב שותף" כדי להפחית אזעקות שווא.',
    'התראת מלווה רק אחרי הסכמה מפורשת של שני הצדדים.',
    'תמיד חייב להיות כפתור "אני בסדר" נגיש.',
  ];

  static const whenNotToPlayAudioHe = [
    'כשהמשתמש סימן רגישות לשמע / העדיף "רק רטט".',
    'ב־10 הדקות הראשונות אחרי כניסה לשינה (מניעת הפתעה).',
    'אם ההקלטה האישית טרם אושרה בהאזנה מוקדמת.',
    'כשמצב "השתק שמע בלילה" פעיל.',
  ];

  /// מגביל עוצמה — firm לא עובר 0.65; gentle עד 0.4
  static double cappedMaxVolume(StimulusIntensity intensity) {
    return intensity == StimulusIntensity.gentle ? 0.40 : 0.65;
  }

  static bool shouldSuppressAudio({
    required InterventionConfig config,
    required DateTime? sleepStartedAt,
    required DateTime now,
  }) {
    if (config.muteAudioAtNight) return true;
    if (config.mode == InterventionMode.vibrationOnly) return true;
    if (config.requirePreviewedVoiceAnchor &&
        config.selectedAudioAnchorId == 'custom_voice' &&
        !config.voiceAnchorPreviewed) {
      return true;
    }
    if (sleepStartedAt != null) {
      final sinceSleep = now.difference(sleepStartedAt);
      if (sinceSleep < Duration(minutes: config.audioQuietMinutesAfterSleep)) {
        return true;
      }
    }
    return false;
  }
}
