import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../domain/night_guard_state.dart';
import '../features/grounding/grounding_screen.dart';
import '../features/morning/morning_screen.dart';
import '../features/night_guard/night_guard_controller.dart';
import '../features/night_guard/night_guard_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../l10n/app_localizations.dart';
import '../storage/night_store.dart';
import 'preview_mode.dart';
import 'theme.dart';

class AnchorNightApp extends StatefulWidget {
  final NightGuardController controller;

  const AnchorNightApp({super.key, required this.controller});

  @override
  State<AnchorNightApp> createState() => _AnchorNightAppState();
}

class _AnchorNightAppState extends State<AnchorNightApp> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    _loadGate();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGate() async {
    if (PreviewMode.skipOnboarding) {
      if (!mounted) return;
      setState(() => _onboardingDone = true);
      return;
    }
    if (PreviewMode.current == 'onboarding') {
      if (!mounted) return;
      setState(() => _onboardingDone = false);
      return;
    }
    final done = await NightStore().isOnboardingDone();
    if (!mounted) return;
    setState(() => _onboardingDone = done);
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'עוגן לילה',
      debugShowCheckedModeBanner: false,
      theme: AnchorTheme.dark(),
      locale: widget.controller.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isRtl = widget.controller.locale.languageCode == 'he';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _onboardingDone == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _onboardingDone!
              ? NightShell(controller: widget.controller)
              : OnboardingScreen(
                  onFinished: () => setState(() => _onboardingDone = true),
                ),
    );
    // Foreground-task wrapper is Android-only; skip on web/desktop preview.
    if (kIsWeb) return app;
    return WithForegroundTask(child: app);
  }
}

class NightShell extends StatefulWidget {
  final NightGuardController controller;
  const NightShell({super.key, required this.controller});

  @override
  State<NightShell> createState() => _NightShellState();
}

class _NightShellState extends State<NightShell> {
  int _tab = PreviewMode.initialTab ?? 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncTabToPhase);
    widget.controller.boot().then((_) {
      if (!mounted) return;
      if (PreviewMode.current == 'grounding') {
        widget.controller.enterGrounding();
      }
      if (PreviewMode.current == 'morning') {
        widget.controller.endNightToMorning();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTabToPhase);
    super.dispose();
  }

  void _syncTabToPhase() {
    final phase = widget.controller.phase;
    if (phase == NightGuardPhase.grounding && _tab != 2) {
      setState(() => _tab = 2);
    } else if (phase == NightGuardPhase.morning && _tab != 0) {
      setState(() => _tab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final screens = [
          MorningScreen(controller: widget.controller),
          NightGuardScreen(controller: widget.controller),
          GroundingScreen(controller: widget.controller),
        ];

        return Scaffold(
          body: SafeArea(child: screens[_tab]),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.wb_sunny_outlined),
                label: l10n.morningTab,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.nightlight_round),
                label: l10n.nightGuardTab,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.self_improvement),
                label: l10n.groundingTab,
              ),
            ],
          ),
        );
      },
    );
  }
}
