import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/night_guard_state.dart';
import '../../domain/night_session.dart';
import '../../services/insight_engine.dart';
import '../night_guard/night_guard_controller.dart';

class MorningScreen extends StatefulWidget {
  final NightGuardController controller;
  const MorningScreen({super.key, required this.controller});

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  int _restfulness = 3;
  bool _helped = true;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final session = c.lastCompletedSession;
        final isMorning = c.phase == NightGuardPhase.morning;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'הבוקר שלך',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AnchorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMorning
                  ? 'בוקר טוב. אין צורך לשפוט את הלילה — רק לרשום בעדינות.'
                  : 'כאן יופיע סיכום אחרי יקיצה. אפשר גם לעיין בלילות קודמים.',
              style: const TextStyle(color: AnchorTheme.textMuted, height: 1.4),
            ),
            if (session != null) ...[
              const SizedBox(height: 18),
              _SessionCard(session: session),
            ],
            const SizedBox(height: 18),
            _InsightCard(insight: c.currentInsight),
            if (isMorning) ...[
              const SizedBox(height: 22),
              const Text(
                'איך את/ה מרגיש/ה עכשיו?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AnchorTheme.accent,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  final selected = _restfulness == value;
                  return ChoiceChip(
                    label: Text('$value'),
                    selected: selected,
                    onSelected: (_) => setState(() => _restfulness = value),
                    selectedColor: AnchorTheme.accentSoft,
                    labelStyle: TextStyle(
                      color: selected
                          ? AnchorTheme.textPrimary
                          : AnchorTheme.textMuted,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              const Text(
                '1 = קשה מאוד · 5 = רגוע יחסית',
                style: TextStyle(color: AnchorTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ההתערבות עזרה (אם הייתה)'),
                value: _helped,
                activeThumbColor: AnchorTheme.calm,
                onChanged: (v) => setState(() => _helped = v),
              ),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: AnchorTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'הערה חופשית (אופציונלי)',
                  hintStyle: TextStyle(color: AnchorTheme.textMuted),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => c.submitMorningCheckIn(
                  restfulness: _restfulness,
                  interventionHelped: _helped,
                  note: _noteCtrl.text,
                ),
                child: const Text('שמור והתחל יום חדש'),
              ),
            ] else if (session != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AnchorTheme.textPrimary,
                  side: const BorderSide(color: AnchorTheme.accentSoft),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: c.resetToIdle,
                child: const Text('נקה סיכום'),
              ),
            ],
            if (c.sessions.length > 1) ...[
              const SizedBox(height: 28),
              const Text(
                'לילות אחרונים',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AnchorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...c.sessions.reversed.take(5).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SessionCard(session: s, compact: true),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final NightSession session;
  final bool compact;
  const _SessionCard({required this.session, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final hours = session.duration.inHours;
    final mins = session.duration.inMinutes % 60;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AnchorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.startedAt.day}.${session.startedAt.month}.${session.startedAt.year}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AnchorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'משך משוער: ${hours}ש׳ ${mins}דק׳ · התערבויות: ${session.interventionCount} · קרקוע: ${session.groundingCount}',
            style: const TextStyle(color: AnchorTheme.textMuted, fontSize: 13),
          ),
          if (session.checkIn != null) ...[
            const SizedBox(height: 4),
            Text(
              'דיווח בוקר: ${session.checkIn!.restfulness}/5'
              '${session.checkIn!.note.isEmpty ? '' : ' · ${session.checkIn!.note}'}',
              style: const TextStyle(color: AnchorTheme.calm, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final NightInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final pct = (insight.confidence * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnchorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AnchorTheme.accentSoft.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'תובנות מהנתונים שלך',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AnchorTheme.accent,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight.headline,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AnchorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'רמת ודאות לדפוס: $pct% (לא דיוק רפואי)',
            style: const TextStyle(color: AnchorTheme.textMuted, fontSize: 12),
          ),
          if (insight.whatHelped.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'מה שנראה שעזר',
              style: TextStyle(fontWeight: FontWeight.w700, color: AnchorTheme.calm),
            ),
            ...insight.whatHelped.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $t',
                    style: const TextStyle(color: AnchorTheme.textPrimary, height: 1.35)),
              ),
            ),
          ],
          if (insight.whatMayHelp.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'מה עשוי לעזור בהמשך',
              style: TextStyle(fontWeight: FontWeight.w700, color: AnchorTheme.warn),
            ),
            ...insight.whatMayHelp.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $t',
                    style: const TextStyle(color: AnchorTheme.textPrimary, height: 1.35)),
              ),
            ),
          ],
          if (insight.patterns.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'דפוסים',
              style: TextStyle(fontWeight: FontWeight.w700, color: AnchorTheme.textPrimary),
            ),
            ...insight.patterns.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $t',
                    style: const TextStyle(color: AnchorTheme.textMuted, height: 1.35)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            insight.disclaimer,
            style: const TextStyle(color: AnchorTheme.textMuted, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }
}
