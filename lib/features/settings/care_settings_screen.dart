import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../domain/safety_profile.dart';
import '../night_guard/night_guard_controller.dart';

/// הגדרות בטיחות, מלווה, שותף, ייצוא ואנליטיקס.
class CareSettingsScreen extends StatelessWidget {
  final NightGuardController controller;
  const CareSettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final c = controller.config;
        return Scaffold(
          backgroundColor: AnchorTheme.background,
          appBar: AppBar(
            title: const Text('הגדרות טיפול ובטיחות'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                ClinicalSafety.disclaimerHe,
                style: TextStyle(color: AnchorTheme.warn, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'הנחיות בטיחות',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AnchorTheme.accent,
                ),
              ),
              ...ClinicalSafety.guidelinesHe.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('• $g',
                      style: const TextStyle(color: AnchorTheme.textMuted)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'מתי לא להפעיל שמע',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AnchorTheme.accent,
                ),
              ),
              ...ClinicalSafety.whenNotToPlayAudioHe.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('• $g',
                      style: const TextStyle(color: AnchorTheme.textMuted)),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('מצב שותף במיטה'),
                subtitle: const Text(
                  'מצריך דופק גבוה מאושר; פחות אזעקות שווא מתנועה',
                ),
                value: c.bedPartnerMode,
                activeThumbColor: AnchorTheme.calm,
                onChanged: (v) =>
                    controller.updateConfig(c.copyWith(bedPartnerMode: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('השתק שמע בלילה'),
                subtitle: const Text('רק רטט — מומלץ אם שמע מפתיע'),
                value: c.muteAudioAtNight,
                activeThumbColor: AnchorTheme.calm,
                onChanged: (v) =>
                    controller.updateConfig(c.copyWith(muteAudioAtNight: v)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('שקט אחרי כניסה לשינה (דקות)'),
                subtitle: Text('${c.audioQuietMinutesAfterSleep}'),
                trailing: SizedBox(
                  width: 140,
                  child: Slider(
                    value: c.audioQuietMinutesAfterSleep.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => controller.updateConfig(
                      c.copyWith(audioQuietMinutesAfterSleep: v.round()),
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('התראת מלווה (אופציונלי)'),
                subtitle: const Text(
                  'אחרי עיכוב — נפתח SMS. "אני בסדר" מבטל. דורש הסכמה.',
                ),
                value: c.companionAlertEnabled,
                activeThumbColor: AnchorTheme.calm,
                onChanged: (v) => controller.updateConfig(
                  c.copyWith(companionAlertEnabled: v),
                ),
              ),
              if (c.companionAlertEnabled) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: c.companionConsentGiven,
                  activeColor: AnchorTheme.calm,
                  title: const Text(
                    'שני הצדדים הסכימו לקבל/לשלוח התראת מלווה',
                  ),
                  onChanged: (v) => controller.updateConfig(
                    c.copyWith(companionConsentGiven: v ?? false),
                  ),
                ),
                TextFormField(
                  initialValue: c.companionName ?? '',
                  decoration: const InputDecoration(
                    labelText: 'שם המלווה',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => controller.updateConfig(
                    c.copyWith(companionName: v.trim()),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: c.companionPhone ?? '',
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'טלפון מלווה',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => controller.updateConfig(
                    c.copyWith(companionPhone: v.trim()),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('עיכוב לפני שליחה (שניות)'),
                  subtitle: Text('${c.companionDelaySeconds}'),
                  trailing: SizedBox(
                    width: 140,
                    child: Slider(
                      value: c.companionDelaySeconds.toDouble(),
                      min: 30,
                      max: 180,
                      divisions: 15,
                      onChanged: (v) => controller.updateConfig(
                        c.copyWith(companionDelaySeconds: v.round()),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('אפשר ייצוא סיכום למטפל/ת'),
                value: c.therapistExportEnabled,
                activeThumbColor: AnchorTheme.calm,
                onChanged: (v) => controller.updateConfig(
                  c.copyWith(therapistExportEnabled: v),
                ),
              ),
              if (c.therapistExportEnabled)
                ElevatedButton.icon(
                  onPressed: () async {
                    final text = controller.buildTherapistReport();
                    await Share.share(text);
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('ייצוא / שיתוף סיכום'),
                ),
              const Divider(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('אנליטיקס מקומי (opt-in)'),
                subtitle: const Text('נשמר במכשיר בלבד, ללא שליחה לשרת'),
                value: controller.analyticsOptIn,
                activeThumbColor: AnchorTheme.calm,
                onChanged: controller.setAnalyticsOptIn,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: controller.locale.languageCode,
                dropdownColor: AnchorTheme.surfaceElevated,
                decoration: const InputDecoration(
                  labelText: 'שפה / Language',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'he', child: Text('עברית')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) controller.setLocaleCode(v);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
