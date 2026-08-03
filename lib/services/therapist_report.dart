import '../domain/night_session.dart';
import '../domain/personal_baseline.dart';

class TherapistReportBuilder {
  static String build({
    required List<NightSession> sessions,
    required PersonalBaseline baseline,
    required bool includeNotes,
    String locale = 'he',
  }) {
    final buf = StringBuffer();
    if (locale == 'en') {
      buf.writeln('AnchorNight — Therapist summary (user exported)');
      buf.writeln('Not a medical record. Support-tool data only.');
      buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buf.writeln(
        'Baseline resting HR (approx): ${baseline.restingHeartRate.toStringAsFixed(1)} | samples: ${baseline.sampleCount}',
      );
      buf.writeln('');
      for (final s in sessions.reversed.take(14)) {
        buf.writeln(
          '- ${s.startedAt.toIso8601String()} | duration ${s.duration.inMinutes}m | interventions ${s.interventionCount} | grounding ${s.groundingCount} | liveHR ${s.usedLiveHeartRate}',
        );
        if (includeNotes && s.checkIn != null) {
          buf.writeln(
            '  morning: ${s.checkIn!.restfulness}/5 helped=${s.checkIn!.interventionHelped} note="${s.checkIn!.note}"',
          );
        }
      }
    } else {
      buf.writeln('עוגן לילה — סיכום לייצוא למטפל/ת (ייצוא משתמש)');
      buf.writeln('אינו רשומה רפואית. נתוני כלי תמיכה בלבד.');
      buf.writeln('נוצר: ${DateTime.now().toIso8601String()}');
      buf.writeln(
        'דופק מנוחה משוער: ${baseline.restingHeartRate.toStringAsFixed(1)} | דגימות כיול: ${baseline.sampleCount}',
      );
      buf.writeln('');
      for (final s in sessions.reversed.take(14)) {
        buf.writeln(
          '- ${s.startedAt.toIso8601String()} | משך ${s.duration.inMinutes} דק׳ | התערבויות ${s.interventionCount} | קרקוע ${s.groundingCount} | דופק חי ${s.usedLiveHeartRate}',
        );
        if (includeNotes && s.checkIn != null) {
          buf.writeln(
            '  בוקר: ${s.checkIn!.restfulness}/5 עזר=${s.checkIn!.interventionHelped} הערה="${s.checkIn!.note}"',
          );
        }
      }
    }
    return buf.toString();
  }
}
