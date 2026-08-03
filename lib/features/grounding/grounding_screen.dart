import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../domain/priority_contact.dart';
import '../night_guard/night_guard_controller.dart';

class GroundingScreen extends StatelessWidget {
  final NightGuardController controller;

  const GroundingScreen({super.key, required this.controller});

  Future<void> _dial(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _importContact(BuildContext context) async {
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('נדרשת הרשאה לאנשי קשר')),
        );
      }
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;
    final full = await FlutterContacts.getContact(contact.id);
    final phone = full?.phones.isNotEmpty == true
        ? full!.phones.first.number
        : '';
    if (phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא נמצא מספר טלפון')),
        );
      }
      return;
    }
    await controller.addContact(
      PriorityContact(
        id: const Uuid().v4(),
        name: contact.displayName,
        phone: phone,
        relationship: 'איש קשר לחירום',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final dawnIntensity = controller.dawnIntensity;
        final bg = Color.lerp(
          AnchorTheme.background,
          const Color(0xFF1A1814),
          dawnIntensity,
        )!;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: bg,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  'את/ה כאן. עכשיו.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AnchorTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'זהו רגע קשה — לא סכנה בהווה. ננשום יחד, לאט.',
                  style: TextStyle(color: AnchorTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 22),
                _BreathCircle(progress: dawnIntensity),
                const SizedBox(height: 22),
                const _GroundingSteps(),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AnchorTheme.calm,
                    foregroundColor: const Color(0xFF0B1410),
                    minimumSize: const Size.fromHeight(58),
                  ),
                  onPressed: controller.imOkayStopIntervention,
                  child: const Text('אני בסדר — עצור התערבות'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AnchorTheme.textPrimary,
                    side: const BorderSide(color: AnchorTheme.accentSoft),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: controller.returnToNightProtection,
                  child: const Text('חזרתי לנשום — המשך הגנת לילה'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'אנשי קשר לחירום',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AnchorTheme.accent,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _importContact(context),
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('ייבא'),
                    ),
                  ],
                ),
                if (controller.contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'לא הוגדרו אנשי קשר. אפשר לייבא מהטלפון.',
                      style: TextStyle(color: AnchorTheme.textMuted, fontSize: 13),
                    ),
                  )
                else
                  ...controller.contacts.map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AnchorTheme.accentSoft,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      title: Text(c.name),
                      subtitle: Text('${c.relationship} · ${c.phone}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: AnchorTheme.calm),
                            onPressed: () => _dial(c.phone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AnchorTheme.danger, size: 20),
                            onPressed: () => controller.removeContact(c.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'קווי סיוע',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AnchorTheme.accent,
                  ),
                ),
                const SizedBox(height: 8),
                ...kIsraelSupportHotlines.map(
                  (h) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(h.name),
                    subtitle: Text(h.note),
                    trailing: TextButton(
                      onPressed: () => _dial(h.phone),
                      child: Text(h.phone),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BreathCircle extends StatelessWidget {
  final double progress;
  const _BreathCircle({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scale = 0.85 + (progress * 0.2);
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 160,
          height: 160,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AnchorTheme.accent.withValues(alpha: 0.35),
                AnchorTheme.accentSoft.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: AnchorTheme.accent.withValues(alpha: 0.45)),
          ),
          child: const Text(
            'שאיפה 4\nהפסקה\nנשיפה 6',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AnchorTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroundingSteps extends StatelessWidget {
  const _GroundingSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      '5 דברים שאת/ה רואה בחדר',
      '4 דברים שאת/ה מרגיש/ה בגוף',
      '3 צלילים עכשיו',
      '2 ריחות או טעמים',
      '1 משפט: אני בטוח/ה במיטה שלי',
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AnchorTheme.surfaceElevated,
                  child: Text(
                    '${5 - i}',
                    style: const TextStyle(fontSize: 12, color: AnchorTheme.accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(
                      color: AnchorTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
