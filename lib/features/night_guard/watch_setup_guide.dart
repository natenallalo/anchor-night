import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';

/// הוראות פשוטות: חיבור אחד דרך Health Connect / Apple Health.
Future<void> showWatchSetupGuide(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AnchorTheme.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final isAndroid =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const Text(
                  'חיבור שעון — פשוט',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AnchorTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'עוגן לילה קוראת דופק ממרכז בריאות אחד בטלפון. '
                  'אין צורך באפליקציות נוספות מעבר למה שכבר מגיע עם השעון.',
                  style: TextStyle(
                    color: AnchorTheme.textMuted,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 14),
                  _warnBox(
                    'בדפדפן אי אפשר לחבר שעון. התקינו את קובץ ה־APK על הטלפון.',
                  ),
                ],
                if (isAndroid || kIsWeb) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'אנדרואיד (כל סוגי השעונים)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AnchorTheme.accent,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _Step(
                    n: '1',
                    text:
                        'לחצו «חבר שעון» באפליקציה ואשרו קריאת דופק. אם חסר — תיפתח התקנת Health Connect (אפליקציה אחת של Google, לרוב כבר מותקנת).',
                  ),
                  const _Step(
                    n: '2',
                    text:
                        'ודאו שהשעון כבר מחובר לטלפון דרך האפליקציה שהגיעה איתו (Galaxy Watch / Wear OS / Garmin / Fitbit וכו׳). אין צורך להוריד אפליקציות נוספות רק בשביל עוגן לילה.',
                  ),
                  const _Step(
                    n: '3',
                    text:
                        'באפליקציית השעון שלכם: הפעילו שיתוף דופק ל־Health Connect (לרוב בהגדרות / Connected apps).',
                  ),
                  const _Step(
                    n: '4',
                    text:
                        'שימו את השעון על היד ל־30 שניות, חזרו לכאן ולחצו «רענן קריאת דופק».',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'טיפ: Galaxy Watch משתמש ב־Samsung Health שכבר מותקן ברוב מכשירי Samsung. '
                    'Wear OS / Pixel Watch לרוב כותבים ישירות ל־Health Connect.',
                    style: TextStyle(
                      color: AnchorTheme.textMuted,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _open(
                      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('התקן / עדכן Health Connect'),
                  ),
                ],
                if (isIos || kIsWeb) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'iPhone / Apple Watch',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AnchorTheme.accent,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _Step(
                    n: '1',
                    text:
                        'ודאו שהשעון מסונכרן וכותב דופק לאפליקציית «בריאות» (כבר מותקנת).',
                  ),
                  const _Step(
                    n: '2',
                    text: 'ב־«עוגן לילה» לחצו «חבר שעון» ואשרו קריאת דופק.',
                  ),
                  const _Step(
                    n: '3',
                    text:
                        'אם נחסם: הגדרות ← פרטיות ובטיחות ← בריאות ← עוגן לילה ← דופק.',
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('הבנתי — חזרה לחיבור'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _warnBox(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AnchorTheme.warn.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AnchorTheme.warn.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AnchorTheme.warn, height: 1.4, fontSize: 13),
    ),
  );
}

Future<void> _open(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AnchorTheme.accentSoft,
            child: Text(
              n,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AnchorTheme.textPrimary,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
