import '../domain/audio_anchor_catalog.dart';
import '../domain/night_session.dart';

class NightInsight {
  final String headline;
  final List<String> whatHelped;
  final List<String> whatMayHelp;
  final List<String> patterns;
  final double confidence; // 0-1 pattern confidence, NOT medical accuracy
  final String disclaimer;

  const NightInsight({
    required this.headline,
    required this.whatHelped,
    required this.whatMayHelp,
    required this.patterns,
    required this.confidence,
    required this.disclaimer,
  });
}

/// מנוע תובנות מקומי — ניתוח דפוסים מהיומן והלילות.
/// אינו אבחון רפואי ואינו מבטיח דיוק קליני.
class InsightEngine {
  static const disclaimer =
      'תובנות מבוססות דפוסים מהנתונים שלך במכשיר בלבד. '
      'אינן אבחון, אינן טיפול, ואינן מחליפות איש מקצוע. '
      'במצוקה — פנו לגורם מקצועי או לקווי הסיוע.';

  NightInsight analyze(List<NightSession> sessions) {
    final withCheckIn =
        sessions.where((s) => s.checkIn != null).toList(growable: false);
    if (sessions.isEmpty) {
      return const NightInsight(
        headline: 'עדיין אין מספיק נתונים לניתוח',
        whatHelped: [],
        whatMayHelp: [
          'הפעילו הגנת לילה לכמה לילות',
          'מלאו דיווח בוקר קצר',
          'בחרו עוגן קולי שמרגיש בטוח',
        ],
        patterns: [],
        confidence: 0.15,
        disclaimer: disclaimer,
      );
    }

    final helped = withCheckIn.where((s) => s.checkIn!.interventionHelped);
    final notHelped =
        withCheckIn.where((s) => !s.checkIn!.interventionHelped);
    final avgRest = withCheckIn.isEmpty
        ? 0.0
        : withCheckIn
                .map((s) => s.checkIn!.restfulness)
                .reduce((a, b) => a + b) /
            withCheckIn.length;

    final audioScores = <String, _Score>{};
    for (final s in withCheckIn) {
      final id = s.audioAnchorId ?? 'unknown';
      final score = audioScores.putIfAbsent(id, _Score.new);
      score.n += 1;
      score.restSum += s.checkIn!.restfulness;
      if (s.checkIn!.interventionHelped) score.helped += 1;
    }

    String? bestAudio;
    double bestAudioRate = -1;
    for (final e in audioScores.entries) {
      if (e.value.n < 1) continue;
      final rate = e.value.helped / e.value.n;
      if (rate > bestAudioRate) {
        bestAudioRate = rate;
        bestAudio = e.key;
      }
    }

    final liveHrSessions =
        sessions.where((s) => s.usedLiveHeartRate).length;
    final groundingSessions =
        sessions.where((s) => s.groundingCount > 0).length;
    final avgInterventions = sessions
            .map((s) => s.interventionCount)
            .fold<int>(0, (a, b) => a + b) /
        sessions.length;

    final whatHelped = <String>[];
    final whatMayHelp = <String>[];
    final patterns = <String>[];

    if (helped.isNotEmpty) {
      whatHelped.add(
        'ב־${helped.length} מתוך ${withCheckIn.length} דיווחי בוקר ציינתם שההתערבות עזרה',
      );
    }
    if (bestAudio != null && bestAudio != 'unknown') {
      final label = AudioAnchorCatalog.byId(bestAudio)?.labelHe ?? bestAudio;
      whatHelped.add(
        'העוגן הקולי «$label» נקשר יותר ללילות שדווחו כעוזרים',
      );
    }
    final gentleOk = withCheckIn
        .where((s) => s.intensity == 'gentle' && s.checkIn!.interventionHelped)
        .length;
    final firmOk = withCheckIn
        .where((s) => s.intensity == 'firm' && s.checkIn!.interventionHelped)
        .length;
    if (gentleOk > firmOk && gentleOk > 0) {
      whatHelped.add('עוצמה עדינה הופיעה יותר בלילות מוצלחים');
    } else if (firmOk > gentleOk && firmOk > 0) {
      whatHelped.add('עוצמה יציבה יותר הופיעה בלילות שדווחו כעוזרים');
    }

    final notes = withCheckIn
        .map((s) => s.checkIn!.note.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (notes.isNotEmpty) {
      whatHelped.add('יש לכם ${notes.length} הערות אישיות — הן חשובות לשיחה עם מטפל/ת');
    }

    if (avgRest > 0 && avgRest < 2.8) {
      whatMayHelp.add('ממוצע המנוחה נמוך — שקלו מצב שותף במיטה / פחות שמע בלילה');
    } else if (avgRest >= 3.5) {
      whatHelped.add('ממוצע תחושת מנוחה יחסית טוב (${avgRest.toStringAsFixed(1)}/5)');
    }

    if (liveHrSessions == 0) {
      whatMayHelp.add('חיבור שעון דופק ישפר את דיוק הזיהוי משמעותית');
    } else {
      patterns.add('דופק חי שימש ב־$liveHrSessions לילות');
    }

    if (avgInterventions > 4) {
      whatMayHelp.add(
        'מספר התערבויות גבוה יחסית — בדקו מצב שותף במיטה או העלו סף רגישות עדין',
      );
    } else if (avgInterventions > 0 && avgInterventions <= 2) {
      patterns.add('מספר התערבויות ממוצע נמוך-יציב — סימן לכיול סביר');
    }

    if (groundingSessions > 0) {
      patterns.add('קרקוע הופעל ב־$groundingSessions לילות');
      whatMayHelp.add('תרגול נשימה מונחית גם מחוץ למשבר יכול לחזק את העוגן');
    } else {
      whatMayHelp.add('נסו את מסך הקרקוע עם הדרכת נשימה קולית כשיש מצוקה');
    }

    if (notHelped.length >= 2) {
      whatMayHelp.add('נסו עוגן קולי אחר או הקלטה אישית של משפט מרגיע');
      whatMayHelp.add('בדקו אם השמע מושתק / חלון שקט אחרי הירדמות חוסם את העוגן');
    }

    if (bestAudio == null || withCheckIn.length < 3) {
      whatMayHelp.add('עוד 2–3 דיווחי בוקר ישפרו מאוד את איכות הניתוח');
    }

    // Confidence grows with sample size and consistency — capped honestly.
    final sampleFactor = (withCheckIn.length / 12).clamp(0.0, 1.0);
    final consistency = withCheckIn.isEmpty
        ? 0.0
        : (helped.length - notHelped.length).abs() / withCheckIn.length;
    final confidence =
        (0.35 + 0.4 * sampleFactor + 0.2 * consistency).clamp(0.2, 0.92);

    final headline = withCheckIn.length < 3
        ? 'ניתוח ראשוני — ממשיכים לאסוף דפוסים'
        : confidence > 0.7
            ? 'דפוסים יציבים יחסית בנתונים שלכם'
            : 'תמונה מתגבשת — יש כיוונים ברורים לשיפור';

    return NightInsight(
      headline: headline,
      whatHelped: whatHelped,
      whatMayHelp: whatMayHelp,
      patterns: patterns,
      confidence: confidence,
      disclaimer: disclaimer,
    );
  }
}

class _Score {
  int n = 0;
  int helped = 0;
  int restSum = 0;
}
