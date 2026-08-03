import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _openOnline() async {
    final uri = Uri.parse(AppConfig.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = '''
מדיניות פרטיות — ${AppConfig.appName}

עדכון אחרון: אוגוסט 2026

1. מה אנחנו אוספים
• מדדי שינה ותנועה מהמכשיר/שעון (דופק, תאוצה) לצורך זיהוי חריגה בלילה
• העדפות התערבות והקלטת עוגן קולי שאת/ה בוחר/ת לשמור
• אנשי קשר לחירום שאת/ה מייבא/ת במפורש
• יומן בוקר שאת/ה ממלא/ת

2. איפה זה נשמר
הנתונים נשמרים מקומית במכשיר (SharedPreferences / קבצי אפליקציה).
אין שליחה לשרת כברירת מחדל בגרסה זו.

3. הרשאות
• מיקרופון — להקלטת עוגן קולי
• תנועה / חיישנים — לניטור שינה
• Health / Health Connect — לקריאת דופק
• אנשי קשר — רק אם בוחרים לייבא איש קשר לחירום
• התראות / שירות רקע — כדי לשמור על הגנת לילה כשהמסך כבוי

4. שיתוף
איננו מוכרים מידע אישי.
קווי סיוע (נט״ל, ער״ן וכו') הם חיוג מקומי מהמכשיר שלך.

5. מחיקה
הסרת האפליקציה מוחקת את הנתונים המקומיים.
ניתן למחוק אנשי קשר והקלטות מתוך האפליקציה.

6. בריאות
האפליקציה אינה כלי רפואי מוסמך ואינה תחליף לטיפול.

7. יצירת קשר
לשאלות פרטיות: ${AppConfig.supportEmail}
''';

    return Scaffold(
      backgroundColor: AnchorTheme.background,
      appBar: AppBar(
        title: const Text('מדיניות פרטיות'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: _openOnline,
              child: const Text(
                'גרסה מקוונת (לקישור בחנות)',
                style: TextStyle(color: AnchorTheme.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AnchorTheme.textMuted,
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
