import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';
import '../../domain/intervention_config.dart';
import '../../domain/night_guard_state.dart';
import '../../sensors/heart_rate_coordinator.dart';
import '../legal/privacy_screen.dart';
import '../settings/care_settings_screen.dart';
import 'night_guard_controller.dart';

class NightGuardScreen extends StatelessWidget {
  final NightGuardController controller;

  const NightGuardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'עוגן לילה',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AnchorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.phase.hebrewLabel,
              style: const TextStyle(color: AnchorTheme.accent, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              controller.statusDetail,
              style: const TextStyle(color: AnchorTheme.textMuted, height: 1.35),
            ),
            if (controller.backgroundActive) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.shield_moon_outlined, size: 16, color: AnchorTheme.calm),
                  SizedBox(width: 6),
                  Text(
                    'ניטור רקע פעיל',
                    style: TextStyle(color: AnchorTheme.calm, fontSize: 13),
                  ),
                ],
              ),
            ],
            if (controller.companionAlertPending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AnchorTheme.warn.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AnchorTheme.warn.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'התראת מלווה ממתינה '
                  '(${controller.companionRemaining?.inSeconds ?? 0} שנ׳) — לחצו "אני בסדר" לביטול',
                  style: const TextStyle(color: AnchorTheme.warn),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _LiveMetricsCard(controller: controller),
            const SizedBox(height: 14),
            _WatchConnectCard(controller: controller),
            const SizedBox(height: 14),
            _PreferencesCard(controller: controller),
            const SizedBox(height: 14),
            _VoiceAnchorCard(controller: controller),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AnchorTheme.textPrimary,
                side: const BorderSide(color: AnchorTheme.accentSoft),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CareSettingsScreen(controller: controller),
                  ),
                );
              },
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('הגדרות בטיחות / מלווה / ייצוא'),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => _showPreSleepSheet(context),
              child: const Text('כניסה יזומה למצב שינה'),
            ),
            const SizedBox(height: 10),
            if (controller.phase == NightGuardPhase.intervening ||
                controller.isInterventionActive)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AnchorTheme.calm,
                  foregroundColor: const Color(0xFF0B1410),
                ),
                onPressed: controller.imOkayStopIntervention,
                child: const Text('אני בסדר — עצור עכשיו'),
              ),
            if (controller.phase == NightGuardPhase.intervening ||
                controller.isInterventionActive)
              const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AnchorTheme.textPrimary,
                side: const BorderSide(color: AnchorTheme.accentSoft),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: controller.enterGrounding,
              child: const Text('פתח מסך קרקוע'),
            ),
            if (AppConfig.showDemoTools) ...[
              const SizedBox(height: 22),
              const Text(
                'כלי פיתוח (מוצגים רק ב־debug)',
                style: TextStyle(
                  color: AnchorTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DemoChip(
                    label: 'סיוט',
                    onTap: controller.demoTriggerNightmare,
                  ),
                  _DemoChip(label: 'רגיעה', onTap: controller.demoCalm),
                  _DemoChip(label: 'יקיצה', onTap: controller.demoTriggerWakeup),
                  _DemoChip(
                    label: 'סיים לילה',
                    onTap: controller.endNightToMorning,
                  ),
                  _DemoChip(label: 'איפוס', onTap: controller.resetToIdle),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'כלי תמיכה בלבד — אינו תחליף לטיפול. במצוקה חריפה פנו לגורם מקצועי.',
              style: TextStyle(color: AnchorTheme.textMuted, fontSize: 11, height: 1.35),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyScreen(),
                  ),
                );
              },
              child: const Text(
                'מדיניות פרטיות',
                style: TextStyle(color: AnchorTheme.accent, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPreSleepSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AnchorTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'בדיקת כשירות לפני שינה',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AnchorTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _CheckRow(
                  title: 'מקור דופק',
                  value: controller.heartRateStatus,
                  ok: controller.hasLiveHeartRate,
                ),
                _CheckRow(
                  title: 'דופק נוכחי',
                  value: '${controller.heartRateBpm.round()} BPM',
                  ok: true,
                ),
                _CheckRow(
                  title: 'כיול אישי',
                  value: controller.isCalibrated
                      ? 'פעיל (${controller.baseline.sampleCount} דגימות)'
                      : 'בבנייה — הספים ישתפרו עם לילות רגועים',
                  ok: controller.isCalibrated,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await controller.startPreSleep();
                    await controller.forceSleepForDemo();
                  },
                  child: const Text('אני מוכן/ה — כנס להגנת לילה'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveMetricsCard extends StatelessWidget {
  final NightGuardController controller;
  const _LiveMetricsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnchorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'דופק',
                  value: '${controller.heartRateBpm.round()}',
                  unit: 'BPM',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'תנועה',
                  value: controller.movementG.toStringAsFixed(2),
                  unit: 'g',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'שמע',
                  value: (controller.audioVolume * 100).round().toString(),
                  unit: '%',
                ),
              ),
            ],
          ),
          if (controller.isInterventionActive) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: controller.audioVolume /
                  (controller.config.maxAudioVolume == 0
                      ? 1
                      : controller.config.maxAudioVolume),
              backgroundColor: AnchorTheme.surfaceElevated,
              color: AnchorTheme.accent,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            const Text(
              'התערבות פעילה — העוצמה עולה בהדרגה',
              style: TextStyle(color: AnchorTheme.warn, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _Metric({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AnchorTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AnchorTheme.textPrimary,
          ),
        ),
        Text(unit, style: const TextStyle(color: AnchorTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _WatchConnectCard extends StatelessWidget {
  final NightGuardController controller;
  const _WatchConnectCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final live = controller.hasLiveHeartRate;
    final mode = controller.heartRateMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnchorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                live ? Icons.watch : Icons.watch_off_outlined,
                color: live ? AnchorTheme.calm : AnchorTheme.warn,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'חיבור שעון דופק',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AnchorTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.heartRateStatus,
            style: const TextStyle(
              color: AnchorTheme.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            live
                ? 'המערכת משתמשת בדופק חי לזיהוי מדויק יותר.'
                : 'בלי שעון — הזיהוי מוגבל. חברו Apple Watch / שעון עם Health Connect.',
            style: const TextStyle(
              color: AnchorTheme.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (mode != HeartRateMode.live || !live)
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await controller.connectWatch();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'הרשאה התקבלה — ממתין לסנכרון דופק מהשעון'
                          : 'לא ניתן לחבר שעון. בדקו Health Connect / Apple Health.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.link),
              label: const Text('חבר שעון / Health'),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AnchorTheme.textPrimary,
                side: const BorderSide(color: AnchorTheme.accentSoft),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: controller.useDemoHeartRate,
              icon: const Icon(Icons.link_off),
              label: const Text('נתק ועבור לדמו'),
            ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final NightGuardController controller;
  const _PreferencesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller.config;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnchorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'התאמת גירוי אישי',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AnchorTheme.accent,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButton<InterventionMode>(
            isExpanded: true,
            value: c.mode,
            dropdownColor: AnchorTheme.surfaceElevated,
            items: const [
              DropdownMenuItem(
                value: InterventionMode.combined,
                child: Text('משולב (רטט ואז קול)'),
              ),
              DropdownMenuItem(
                value: InterventionMode.vibrationOnly,
                child: Text('רק רטט'),
              ),
              DropdownMenuItem(
                value: InterventionMode.audioOnly,
                child: Text('רק קול'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                controller.updateConfig(c.copyWith(mode: v));
              }
            },
          ),
          DropdownButton<StimulusIntensity>(
            isExpanded: true,
            value: c.intensity,
            dropdownColor: AnchorTheme.surfaceElevated,
            items: const [
              DropdownMenuItem(
                value: StimulusIntensity.gentle,
                child: Text('חלש ועדין'),
              ),
              DropdownMenuItem(
                value: StimulusIntensity.firm,
                child: Text('ברור יותר'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                controller.updateConfig(c.copyWith(intensity: v));
              }
            },
          ),
          DropdownButton<VibrationStyle>(
            isExpanded: true,
            value: c.vibrationStyle,
            dropdownColor: AnchorTheme.surfaceElevated,
            items: const [
              DropdownMenuItem(
                value: VibrationStyle.breath46,
                child: Text('דפוס נשימה 4–6'),
              ),
              DropdownMenuItem(
                value: VibrationStyle.shortPulses,
                child: Text('פולסים קצרים'),
              ),
              DropdownMenuItem(
                value: VibrationStyle.longSoft,
                child: Text('רטט ארוך ורך'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                controller.updateConfig(c.copyWith(vibrationStyle: v));
              }
            },
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: c.selectedAudioAnchorId == 'custom_voice' &&
                    c.customAudioPath == null
                ? 'rain'
                : c.selectedAudioAnchorId,
            dropdownColor: AnchorTheme.surfaceElevated,
            items: [
              const DropdownMenuItem(value: 'rain', child: Text('גשם עמום')),
              const DropdownMenuItem(
                value: 'white_noise',
                child: Text('רעש לבן / ורוד עדין'),
              ),
              const DropdownMenuItem(
                value: 'soft_tone',
                child: Text('טון נמוך רך'),
              ),
              if (c.customAudioPath != null)
                const DropdownMenuItem(
                  value: 'custom_voice',
                  child: Text('הקלטה אישית'),
                ),
            ],
            onChanged: (v) {
              if (v != null) {
                controller.updateConfig(c.copyWith(selectedAudioAnchorId: v));
              }
            },
          ),
          TextButton.icon(
            onPressed: controller.previewSelectedAudio,
            icon: const Icon(Icons.headphones, size: 18),
            label: const Text('האזנה מקדימה לעוגן הנבחר'),
          ),
        ],
      ),
    );
  }
}

class _VoiceAnchorCard extends StatelessWidget {
  final NightGuardController controller;
  const _VoiceAnchorCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasVoice = controller.config.customAudioPath != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnchorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'עוגן קולי אישי',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AnchorTheme.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasVoice
                ? 'יש הקלטה שמורה — תופעל בעדינות בזמן התערבות'
                : 'הקליטו קול מוכר (בן/בת זוג, ילד, אתם) — זה העוגן החזק ביותר',
            style: const TextStyle(color: AnchorTheme.textMuted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.recordingVoice
                  ? AnchorTheme.danger
                  : AnchorTheme.accentSoft,
            ),
            onPressed: () async {
              if (controller.recordingVoice) {
                await controller.stopVoiceAnchorRecording();
              } else {
                final ok = await controller.startVoiceAnchorRecording();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('נדרשת הרשאת מיקרופון')),
                  );
                }
              }
            },
            icon: Icon(controller.recordingVoice ? Icons.stop : Icons.mic),
            label: Text(
              controller.recordingVoice ? 'עצור הקלטה ושמור' : 'הקלט עוגן קולי',
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String title;
  final String value;
  final bool ok;
  const _CheckRow({required this.title, required this.value, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.info_outline,
            size: 18,
            color: ok ? AnchorTheme.calm : AnchorTheme.warn,
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: ok ? AnchorTheme.calm : AnchorTheme.warn,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DemoChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AnchorTheme.surfaceElevated,
      labelStyle: const TextStyle(color: AnchorTheme.textPrimary, fontSize: 12),
    );
  }
}
