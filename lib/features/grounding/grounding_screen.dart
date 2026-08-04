import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../domain/priority_contact.dart';
import '../../intervention/breathing_voice_coach.dart';
import '../night_guard/night_guard_controller.dart';

class GroundingScreen extends StatefulWidget {
  final NightGuardController controller;

  const GroundingScreen({super.key, required this.controller});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  final _breathCoach = BreathingVoiceCoach();
  BreathPhase _phase = BreathPhase.inhale;
  int _secondsLeft = 4;
  bool _voiceGuideOn = true;
  bool _voiceStarted = false;
  String _voiceStatus = '';

  @override
  void initState() {
    super.initState();
    _breathCoach.onTick = (phase, seconds) {
      if (!mounted) return;
      setState(() {
        _phase = phase;
        _secondsLeft = seconds;
      });
    };
    _breathCoach.onStatus = (status) {
      if (!mounted) return;
      setState(() => _voiceStatus = status);
    };
    // Mobile can auto-start; web needs a tap (browser autoplay policy).
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_voiceGuideOn) {
          unawaited(_startVoiceGuide());
        }
      });
    }
  }

  @override
  void dispose() {
    _breathCoach.dispose();
    super.dispose();
  }

  Future<void> _startVoiceGuide() async {
    await _breathCoach.stop();
    await _breathCoach.start();
    if (!mounted) return;
    setState(() {
      _voiceGuideOn = true;
      _voiceStarted = true;
    });
  }

  Future<void> _toggleVoiceGuide(bool on) async {
    setState(() => _voiceGuideOn = on);
    if (on) {
      await _startVoiceGuide();
    } else {
      await _breathCoach.stop();
      if (!mounted) return;
      setState(() => _voiceStarted = false);
    }
  }

  Future<void> _dial(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _addManualContact() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AnchorTheme.surfaceElevated,
        title: const Text('הוספת איש קשר'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'שם'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'טלפון'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('שמור'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא למלא שם ומספר טלפון')),
      );
      return;
    }
    await widget.controller.addContact(
      PriorityContact(
        id: const Uuid().v4(),
        name: name,
        phone: phone,
        relationship: 'איש קשר לחירום',
      ),
    );
  }

  Future<void> _importContact() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ביב אין גישה לאנשי קשר — הוסיפו ידנית'),
        ),
      );
      await _addManualContact();
      return;
    }

    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('נדרשת הרשאה לאנשי קשר בהגדרות המכשיר'),
          ),
        );
        return;
      }

      final picked = await FlutterContacts.openExternalPick();
      if (picked == null) return;

      Contact? full;
      if (picked.id.isNotEmpty) {
        full = await FlutterContacts.getContact(
          picked.id,
          withProperties: true,
          withPhoto: false,
        );
      }

      final name = (full?.displayName.isNotEmpty == true)
          ? full!.displayName
          : (picked.displayName.isNotEmpty
              ? picked.displayName
              : 'איש קשר');

      String phone = '';
      final phones = full?.phones ?? picked.phones;
      if (phones.isNotEmpty) {
        phone = phones.first.number;
      }

      if (phone.trim().isEmpty) {
        if (!mounted) return;
        final phoneCtrl = TextEditingController();
        final typed = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AnchorTheme.surfaceElevated,
            title: Text('מספר ל־$name'),
            content: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'טלפון'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, phoneCtrl.text.trim()),
                child: const Text('שמור'),
              ),
            ],
          ),
        );
        if (typed == null || typed.isEmpty) return;
        phone = typed;
      }

      await widget.controller.addContact(
        PriorityContact(
          id: const Uuid().v4(),
          name: name,
          phone: phone,
          relationship: 'איש קשר לחירום',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נוסף: $name')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ייבוא נכשל — הוסיפו ידנית. ($e)'),
        ),
      );
      await _addManualContact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('הדרכה קולית לנשימה'),
                  subtitle: Text(
                    _voiceStatus.isEmpty
                        ? 'קול רגוע שמנחה שאיפה / החזקה / נשיפה'
                        : _voiceStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AnchorTheme.textMuted,
                    ),
                  ),
                  value: _voiceGuideOn,
                  activeThumbColor: AnchorTheme.calm,
                  onChanged: _toggleVoiceGuide,
                ),
                if (!_voiceStarted || kIsWeb) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _startVoiceGuide,
                      icon: const Icon(Icons.volume_up),
                      label: Text(
                        _voiceStarted ? 'הפעל מחדש הדרכה' : 'הפעל הדרכה קולית',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _BreathCircle(phase: _phase, secondsLeft: _secondsLeft),
                const SizedBox(height: 10),
                Text(
                  BreathingVoiceCoach.instructionHe(_phase),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AnchorTheme.calm,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                const _GroundingSteps(),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AnchorTheme.calm,
                    foregroundColor: const Color(0xFF0B1410),
                    minimumSize: const Size(120, 58),
                  ),
                  onPressed: () async {
                    await _breathCoach.stop();
                    controller.imOkayStopIntervention();
                  },
                  child: const Text('אני בסדר — עצור התערבות'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AnchorTheme.textPrimary,
                    side: const BorderSide(color: AnchorTheme.accentSoft),
                    minimumSize: const Size(120, 50),
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
                      onPressed: _addManualContact,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('הוסף'),
                    ),
                    TextButton.icon(
                      onPressed: _importContact,
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('ייבא'),
                    ),
                  ],
                ),
                if (controller.contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'לא הוגדרו אנשי קשר. אפשר לייבא מהטלפון או להוסיף ידנית.',
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
  final BreathPhase phase;
  final int secondsLeft;
  const _BreathCircle({required this.phase, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final scale = switch (phase) {
      BreathPhase.inhale => 0.92 + (4 - secondsLeft) * 0.05,
      BreathPhase.hold => 1.12,
      BreathPhase.exhale => 1.12 - (6 - secondsLeft) * 0.04,
      BreathPhase.rest => 0.88,
    };
    return Center(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        scale: scale.clamp(0.85, 1.2),
        child: Container(
          width: 170,
          height: 170,
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
          child: Text(
            '${BreathingVoiceCoach.labelHe(phase)}\n$secondsLeft',
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.35,
              fontSize: 22,
              fontWeight: FontWeight.w700,
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
