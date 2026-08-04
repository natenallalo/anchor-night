import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../detection/detection_engine.dart';
import '../../domain/intervention_config.dart';
import '../../domain/night_guard_state.dart';
import '../../domain/night_session.dart';
import '../../domain/personal_baseline.dart';
import '../../domain/priority_contact.dart';
import '../../domain/sensor_sample.dart';
import '../../intervention/intervention_controller.dart';
import '../../sensors/heart_rate_coordinator.dart';
import '../../sensors/sensor_hub.dart';
import '../../services/companion_alert_service.dart';
import '../../services/night_background_service.dart';
import '../../services/soft_analytics.dart';
import '../../services/insight_engine.dart';
import '../../services/therapist_report.dart';
import '../../storage/night_store.dart';

class NightGuardController extends ChangeNotifier {
  final SensorHub sensors;
  final DetectionEngine engine;
  final InterventionController intervention;
  final NightStore store;
  final NightBackgroundService background;
  final CompanionAlertService companionAlert;
  final SoftAnalytics analytics;

  InterventionConfig _config = const InterventionConfig();
  String _statusDetail = 'מערכת דרוכה';
  double _dawnIntensity = 0;
  Timer? _dawnTimer;
  Timer? _companionTicker;
  StreamSubscription<SensorSample>? _sampleSub;
  bool _booted = false;
  bool _recordingVoice = false;
  bool _backgroundActive = false;
  DateTime? _sleepStartedAt;
  bool _analyticsOptIn = false;
  Locale _locale = const Locale('he');

  NightSession? _activeSession;
  List<NightSession> _sessions = [];
  List<PriorityContact> _contacts = [];
  NightSession? _lastCompletedSession;

  NightGuardController({
    SensorHub? sensors,
    DetectionEngine? engine,
    InterventionController? intervention,
    NightStore? store,
    NightBackgroundService? background,
    CompanionAlertService? companionAlert,
    SoftAnalytics? analytics,
  })  : sensors = sensors ?? SensorHub(),
        engine = engine ?? DetectionEngine(),
        intervention = intervention ?? InterventionController(),
        store = store ?? NightStore(),
        background = background ?? NightBackgroundService(),
        companionAlert = companionAlert ?? CompanionAlertService(),
        analytics = analytics ?? SoftAnalytics();

  NightGuardPhase get phase => engine.phase;
  InterventionConfig get config => _config;
  PersonalBaseline get baseline => engine.baseline;
  String get statusDetail => _statusDetail;
  double get dawnIntensity => _dawnIntensity;
  double get movementG => sensors.movementG;
  double get heartRateBpm => sensors.heartRateBpm ?? baseline.restingHeartRate;
  String get heartRateStatus => sensors.heartRateStatus;
  bool get isInterventionActive => intervention.isActive;
  double get audioVolume => intervention.audioVolume;
  bool get recordingVoice => _recordingVoice;
  bool get isCalibrated => baseline.isCalibrated;
  bool get hasLiveHeartRate => sensors.hasLiveHeartRate;
  HeartRateMode get heartRateMode => sensors.heartRateMode;
  bool get backgroundActive => _backgroundActive;
  List<PriorityContact> get contacts => List.unmodifiable(_contacts);
  List<NightSession> get sessions => List.unmodifiable(_sessions);
  NightSession? get activeSession => _activeSession;
  NightSession? get lastCompletedSession => _lastCompletedSession;
  bool get companionAlertPending => companionAlert.isPending;
  Duration? get companionRemaining => companionAlert.remaining;
  bool get analyticsOptIn => _analyticsOptIn;
  Locale get locale => _locale;

  NightInsight get currentInsight => InsightEngine().analyze(_sessions);

  Future<void> boot() async {
    if (_booted) return;
    _booted = true;
    await background.init();
    _config = await store.loadConfig();
    engine.setBedPartnerMode(_config.bedPartnerMode);
    final baseline = await store.loadBaseline();
    engine.updateBaseline(baseline);
    final voice = await store.loadVoicePath();
    if (voice != null) {
      _config = _config.copyWith(customAudioPath: voice);
      await intervention.audio.setCustomRecordingPath(voice);
    }
    _contacts = await store.loadContacts();
    _sessions = await store.loadSessions();
    if (_sessions.isNotEmpty && _sessions.last.endedAt != null) {
      _lastCompletedSession = _sessions.last;
    }
    _analyticsOptIn = await analytics.isOptedIn();
    _locale = Locale(await store.loadLocaleCode());

    intervention.onEscalateToGrounding = () {
      if (engine.phase == NightGuardPhase.intervening &&
          heartRateBpm >= baseline.crisisHeartRateThreshold) {
        enterGrounding(auto: true);
      }
    };

    await sensors.start();
    _sampleSub = sensors.samples.listen(_onSample);
    await analytics.track('app_boot');
    notifyListeners();
  }

  Future<void> updateConfig(InterventionConfig config) async {
    _config = config;
    engine.setBedPartnerMode(config.bedPartnerMode);
    await store.saveConfig(config);
    notifyListeners();
  }

  Future<void> setLocaleCode(String code) async {
    _locale = Locale(code);
    await store.saveLocaleCode(code);
    notifyListeners();
  }

  Future<void> setAnalyticsOptIn(bool value) async {
    _analyticsOptIn = value;
    await analytics.setOptIn(value);
    if (value) await analytics.track('analytics_opt_in');
    notifyListeners();
  }

  Future<void> markVoicePreviewed() async {
    await updateConfig(_config.copyWith(voiceAnchorPreviewed: true));
  }

  Future<void> previewSelectedAudio() async {
    if (_config.selectedAudioAnchorId == 'custom_voice' &&
        _config.customAudioPath != null) {
      await intervention.audio.previewFile(_config.customAudioPath!);
      await markVoicePreviewed();
    } else if (_config.builtInAssetPath != null) {
      await intervention.audio.previewAsset(_config.builtInAssetPath!);
    }
  }

  String buildTherapistReport({bool includeNotes = true}) {
    return TherapistReportBuilder.build(
      sessions: _sessions,
      baseline: baseline,
      includeNotes: includeNotes,
      locale: _locale.languageCode,
    );
  }

  Future<bool> connectWatch() async {
    final ok = await sensors.connectWatch();
    _statusDetail = ok
        ? 'מנסה לקרוא דופק מהשעון — ודא סנכרון Health / Health Connect'
        : 'לא חובר שעון — ממשיכים בדופק מדומה';
    notifyListeners();
    return ok;
  }

  Future<void> useDemoHeartRate() async {
    await sensors.useDemoHeartRate();
    _statusDetail = 'חזרה לדופק מדומה';
    notifyListeners();
  }

  Future<void> startPreSleep() async {
    await intervention.cancel();
    engine.markUserReadyForSleep();
    _statusDetail = 'בדיקת כשירות הושלמה — ממתין לשינה טבעית';
    _dawnIntensity = 0;
    notifyListeners();
  }

  Future<void> enterNightProtection({bool manualSleep = true}) async {
    await intervention.cancel();
    companionAlert.cancel();
    if (manualSleep) {
      engine.markSleepingManually();
      sensors.clearDemoHeartRateOverride();
      sensors.demoSetMovement(0);
    }
    _sleepStartedAt = DateTime.now();
    intervention.sleepStartedAt = _sleepStartedAt;
    await _beginSession();
    final started = await background.start();
    _backgroundActive = started || await background.isRunning;
    _statusDetail = _backgroundActive
        ? 'הגנת לילה פעילה ברקע'
        : 'הגנת לילה פעילה (ללא שירות רקע במכשיר זה)';
    await analytics.track('night_protection_started', {
      'bedPartner': _config.bedPartnerMode,
      'liveHr': hasLiveHeartRate,
    });
    notifyListeners();
  }

  Future<void> forceSleepForDemo() => enterNightProtection(manualSleep: true);

  Future<void> imOkayStopIntervention() async {
    await intervention.cancel();
    companionAlert.cancel();
    _companionTicker?.cancel();
    _dawnTimer?.cancel();
    _dawnIntensity = 0;
    if (engine.phase == NightGuardPhase.grounding ||
        engine.phase == NightGuardPhase.intervening) {
      engine.acknowledgeCrisisHandled();
      _statusDetail = 'עצרת את ההתערבות — חוזרים להגנה שקטה';
    }
    await analytics.track('im_okay_pressed');
    notifyListeners();
  }

  Future<void> enterGrounding({bool auto = false}) async {
    await intervention.cancel();
    engine.enterGrounding();
    _bumpGrounding();
    _statusDetail = auto
        ? 'חריגה ממושכת — עברת למסך קרקוע'
        : 'נכנסת למסך קרקוע';
    _dawnIntensity = 0;
    _dawnTimer?.cancel();
    _dawnTimer = Timer.periodic(const Duration(milliseconds: 450), (t) {
      if (_dawnIntensity >= 1) {
        t.cancel();
        return;
      }
      _dawnIntensity = (_dawnIntensity + 0.04).clamp(0.0, 1.0);
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> returnToNightProtection() async {
    await intervention.cancel();
    _dawnTimer?.cancel();
    _dawnIntensity = 0;
    engine.acknowledgeCrisisHandled();
    sensors.clearDemoHeartRateOverride();
    sensors.demoSetMovement(0);
    if (!_backgroundActive) {
      _backgroundActive = await background.start();
    }
    _statusDetail = 'חזרה להגנת לילה';
    notifyListeners();
  }

  Future<void> endNightToMorning() async {
    await intervention.cancel();
    _dawnTimer?.cancel();
    await _completeSession();
    await background.stop();
    _backgroundActive = false;
    engine.forcePhase(NightGuardPhase.morning);
    _statusDetail = 'הגנת הלילה הסתיימה';
    notifyListeners();
  }

  Future<void> resetToIdle() async {
    await intervention.cancel();
    _dawnTimer?.cancel();
    _dawnIntensity = 0;
    await background.stop();
    _backgroundActive = false;
    _activeSession = null;
    engine.stopAllToIdle();
    sensors.clearDemoHeartRateOverride();
    sensors.demoSetMovement(0);
    _statusDetail = 'מערכת דרוכה — ממתין';
    notifyListeners();
  }

  Future<void> submitMorningCheckIn({
    required int restfulness,
    required bool interventionHelped,
    required String note,
  }) async {
    final target = _lastCompletedSession;
    if (target == null) {
      await resetToIdle();
      return;
    }
    final updated = target.copyWith(
      checkIn: MorningCheckIn(
        restfulness: restfulness,
        interventionHelped: interventionHelped,
        note: note.trim(),
        at: DateTime.now(),
      ),
    );
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) {
      _sessions[idx] = updated;
    } else {
      _sessions.add(updated);
    }
    _lastCompletedSession = updated;
    await store.saveSessions(_sessions);
    await resetToIdle();
  }

  Future<void> addContact(PriorityContact contact) async {
    _contacts = [..._contacts, contact];
    await store.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> removeContact(String id) async {
    _contacts = _contacts.where((c) => c.id != id).toList();
    await store.saveContacts(_contacts);
    notifyListeners();
  }

  void demoTriggerNightmare() {
    if (!phase.isProtecting && phase != NightGuardPhase.sleeping) {
      engine.markSleepingManually();
    }
    sensors.demoSetHeartRate(baseline.crisisHeartRateThreshold + 8);
    sensors.demoSetMovement(baseline.crisisMovementThreshold * 0.7);
    _statusDetail = 'סימולציית סיוט הופעלה';
    notifyListeners();
  }

  void demoTriggerWakeup() {
    sensors.demoSetHeartRate(baseline.awakeHeartRateThreshold + 4);
    sensors.demoSetMovement(baseline.stillnessThreshold * 2);
    _statusDetail = 'סימולציית יקיצה';
    notifyListeners();
  }

  void demoCalm() {
    sensors.clearDemoHeartRateOverride();
    sensors.demoSetHeartRate(baseline.restingHeartRate);
    sensors.demoSetMovement(0);
    _statusDetail = 'סימולציית רגיעה';
    notifyListeners();
  }

  Future<bool> startVoiceAnchorRecording() async {
    final ok = await intervention.audio.startRecordingAnchor();
    _recordingVoice = ok;
    notifyListeners();
    return ok;
  }

  Future<void> stopVoiceAnchorRecording() async {
    final path = await intervention.audio.stopRecordingAnchor();
    _recordingVoice = false;
    if (path != null) {
      _config = _config.copyWith(
        customAudioPath: path,
        selectedAudioAnchorId: 'custom_voice',
      );
      await store.saveConfig(_config);
      _statusDetail = 'עוגן קולי נשמר';
    }
    notifyListeners();
  }

  Future<void> _beginSession() async {
    _activeSession = NightSession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      usedLiveHeartRate: hasLiveHeartRate,
      audioAnchorId: _config.selectedAudioAnchorId,
      interventionMode: _config.mode.name,
      intensity: _config.intensity.name,
      bedPartnerMode: _config.bedPartnerMode,
    );
  }

  Future<void> _completeSession() async {
    if (_activeSession == null) {
      _activeSession = NightSession(
        id: const Uuid().v4(),
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        usedLiveHeartRate: hasLiveHeartRate,
        audioAnchorId: _config.selectedAudioAnchorId,
        interventionMode: _config.mode.name,
        intensity: _config.intensity.name,
        bedPartnerMode: _config.bedPartnerMode,
      );
    }
    final completed = _activeSession!.copyWith(endedAt: DateTime.now());
    _sessions = [..._sessions, completed];
    _lastCompletedSession = completed;
    _activeSession = null;
    await store.saveSessions(_sessions);
  }

  void _bumpIntervention() {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(
      interventionCount: _activeSession!.interventionCount + 1,
      usedLiveHeartRate:
          _activeSession!.usedLiveHeartRate || hasLiveHeartRate,
    );
  }

  void _bumpGrounding() {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(
      groundingCount: _activeSession!.groundingCount + 1,
    );
  }

  Future<void> _onSample(SensorSample sample) async {
    final prevPhase = engine.phase;
    final snap = engine.ingest(sample);
    _statusDetail = snap.reason;

    if (snap.signal == DetectionSignal.enteredSleep) {
      await _beginSession();
      _backgroundActive = await background.start();
    }

    if (snap.signal == DetectionSignal.crisisSuspected &&
        prevPhase != NightGuardPhase.intervening) {
      _bumpIntervention();
      await intervention.start(_config);
      _maybeScheduleCompanionAlert();
      await analytics.track('crisis_suspected');
    }

    if (snap.signal == DetectionSignal.calmAfterCrisis) {
      await intervention.cancel();
      _dawnTimer?.cancel();
      _dawnIntensity = 0;
    }

    if (snap.signal == DetectionSignal.fullWakeup) {
      await intervention.cancel();
      _dawnTimer?.cancel();
      _dawnIntensity = 0;
      await _completeSession();
      await background.stop();
      _backgroundActive = false;
    }

    if (engine.baseline.sampleCount > 0 &&
        engine.baseline.sampleCount % 10 == 0) {
      await store.saveBaseline(engine.baseline);
    }

    notifyListeners();
  }

  void _maybeScheduleCompanionAlert() {
    if (!_config.companionAlertEnabled ||
        !_config.companionConsentGiven ||
        (_config.companionPhone ?? '').isEmpty) {
      return;
    }
    companionAlert.schedule(
      phone: _config.companionPhone!,
      userDisplayName: 'המשתמש/ת',
      delaySeconds: _config.companionDelaySeconds,
      onFired: () {
        analytics.track('companion_alert_fired');
        notifyListeners();
      },
    );
    _companionTicker?.cancel();
    _companionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!companionAlert.isPending) {
        _companionTicker?.cancel();
      }
      notifyListeners();
    });
    _statusDetail =
        'התראת מלווה תישלח בעוד ${_config.companionDelaySeconds} שנ׳ — "אני בסדר" מבטל';
  }

  Future<void> shutdown() async {
    await _sampleSub?.cancel();
    _dawnTimer?.cancel();
    _companionTicker?.cancel();
    companionAlert.cancel();
    await background.stop();
    await sensors.stop();
    await intervention.cancel();
  }

  @override
  void dispose() {
    _sampleSub?.cancel();
    _dawnTimer?.cancel();
    _companionTicker?.cancel();
    companionAlert.dispose();
    background.stop();
    sensors.dispose();
    intervention.dispose();
    super.dispose();
  }
}
