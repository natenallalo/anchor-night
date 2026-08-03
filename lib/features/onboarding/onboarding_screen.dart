import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';
import '../../storage/night_store.dart';
import '../legal/privacy_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _accepted = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final store = NightStore();
    await store.setDisclaimerAccepted(true);
    await store.setOnboardingDone(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnchorTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardPage(
                    title: AppConfig.appName,
                    body:
                        'מעטפת לילה עדינה למתמודדי פוסט־טראומה.\nזיהוי חריגה, התערבות רכה, וקרקוע — בשליטתך המלאה.',
                  ),
                  const _OnboardPage(
                    title: 'איך זה עובד',
                    body:
                        '1. מחברים שעון דופק (מומלץ)\n'
                        '2. נכנסים להגנת לילה\n'
                        '3. בעת חריגה — רטט/עוגן קולי בעדינות\n'
                        '4. תמיד אפשר לעצור: "אני בסדר"',
                  ),
                  _DisclaimerPage(
                    accepted: _accepted,
                    onChanged: (v) => setState(() => _accepted = v),
                    onOpenPrivacy: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Text('${_page + 1}/3', style: const TextStyle(color: AnchorTheme.textMuted)),
                  const Spacer(),
                  if (_page < 2)
                    ElevatedButton(
                      onPressed: () => _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('המשך'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _accepted ? _finish : null,
                      child: const Text('אני מבין/ה, התחל'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String body;
  const _OnboardPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AnchorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: const TextStyle(
              color: AnchorTheme.textMuted,
              height: 1.55,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerPage extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;

  const _DisclaimerPage({
    required this.accepted,
    required this.onChanged,
    required this.onOpenPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'חשוב לדעת',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AnchorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'עוגן לילה הוא כלי תמיכה בלבד.\n'
            'אינו אבחון, אינו טיפול רפואי, ואינו תחליף למטפל/ת או לשירותי חירום.\n\n'
            'במצוקה חריפה — פנו לגורם מקצועי או לקווי הסיוע באפליקציה.\n'
            'הנתונים נשמרים מקומית במכשיר כברירת מחדל.',
            style: TextStyle(
              color: AnchorTheme.textMuted,
              height: 1.55,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onOpenPrivacy,
            child: const Text(
              'מדיניות פרטיות',
              style: TextStyle(color: AnchorTheme.accent),
            ),
          ),
          const Spacer(),
          CheckboxListTile(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AnchorTheme.calm,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'קראתי והבנתי שזה כלי תמיכה בלבד',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
