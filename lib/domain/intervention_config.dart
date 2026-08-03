enum InterventionMode { combined, vibrationOnly, audioOnly }

enum VibrationStyle { breath46, shortPulses, longSoft }

enum StimulusIntensity { gentle, firm }

class InterventionConfig {
  final InterventionMode mode;
  final VibrationStyle vibrationStyle;
  final StimulusIntensity intensity;
  final String selectedAudioAnchorId;
  final String? customAudioPath;
  final bool allowAutoEscalateToGrounding;
  final int escalateAfterSeconds;

  /// מצב שותף במיטה — מחמיר זיהוי משבר.
  final bool bedPartnerMode;

  /// השתק שמע בלילה (רק רטט בפועל).
  final bool muteAudioAtNight;

  /// דקות שקטות אחרי כניסה לשינה לפני שמותר שמע.
  final int audioQuietMinutesAfterSleep;

  /// דורש האזנה מקדימה להקלטת קול אישית.
  final bool requirePreviewedVoiceAnchor;
  final bool voiceAnchorPreviewed;

  /// התראת מלווה.
  final bool companionAlertEnabled;
  final bool companionConsentGiven;
  final String? companionPhone;
  final String? companionName;
  final int companionDelaySeconds;

  /// ייצוא למטפל.
  final bool therapistExportEnabled;

  const InterventionConfig({
    this.mode = InterventionMode.combined,
    this.vibrationStyle = VibrationStyle.breath46,
    this.intensity = StimulusIntensity.gentle,
    this.selectedAudioAnchorId = 'rain',
    this.customAudioPath,
    this.allowAutoEscalateToGrounding = true,
    this.escalateAfterSeconds = 25,
    this.bedPartnerMode = false,
    this.muteAudioAtNight = false,
    this.audioQuietMinutesAfterSleep = 10,
    this.requirePreviewedVoiceAnchor = true,
    this.voiceAnchorPreviewed = false,
    this.companionAlertEnabled = false,
    this.companionConsentGiven = false,
    this.companionPhone,
    this.companionName,
    this.companionDelaySeconds = 90,
    this.therapistExportEnabled = false,
  });

  double get maxAudioVolume =>
      intensity == StimulusIntensity.gentle ? 0.40 : 0.65;

  String? get builtInAssetPath {
    switch (selectedAudioAnchorId) {
      case 'rain':
        return 'assets/audio/rain.wav';
      case 'white_noise':
        return 'assets/audio/white_noise.wav';
      case 'soft_tone':
        return 'assets/audio/soft_tone.wav';
      default:
        return null;
    }
  }

  InterventionConfig copyWith({
    InterventionMode? mode,
    VibrationStyle? vibrationStyle,
    StimulusIntensity? intensity,
    String? selectedAudioAnchorId,
    String? customAudioPath,
    bool? allowAutoEscalateToGrounding,
    int? escalateAfterSeconds,
    bool? bedPartnerMode,
    bool? muteAudioAtNight,
    int? audioQuietMinutesAfterSleep,
    bool? requirePreviewedVoiceAnchor,
    bool? voiceAnchorPreviewed,
    bool? companionAlertEnabled,
    bool? companionConsentGiven,
    String? companionPhone,
    String? companionName,
    int? companionDelaySeconds,
    bool? therapistExportEnabled,
  }) {
    return InterventionConfig(
      mode: mode ?? this.mode,
      vibrationStyle: vibrationStyle ?? this.vibrationStyle,
      intensity: intensity ?? this.intensity,
      selectedAudioAnchorId:
          selectedAudioAnchorId ?? this.selectedAudioAnchorId,
      customAudioPath: customAudioPath ?? this.customAudioPath,
      allowAutoEscalateToGrounding:
          allowAutoEscalateToGrounding ?? this.allowAutoEscalateToGrounding,
      escalateAfterSeconds: escalateAfterSeconds ?? this.escalateAfterSeconds,
      bedPartnerMode: bedPartnerMode ?? this.bedPartnerMode,
      muteAudioAtNight: muteAudioAtNight ?? this.muteAudioAtNight,
      audioQuietMinutesAfterSleep:
          audioQuietMinutesAfterSleep ?? this.audioQuietMinutesAfterSleep,
      requirePreviewedVoiceAnchor:
          requirePreviewedVoiceAnchor ?? this.requirePreviewedVoiceAnchor,
      voiceAnchorPreviewed: voiceAnchorPreviewed ?? this.voiceAnchorPreviewed,
      companionAlertEnabled:
          companionAlertEnabled ?? this.companionAlertEnabled,
      companionConsentGiven:
          companionConsentGiven ?? this.companionConsentGiven,
      companionPhone: companionPhone ?? this.companionPhone,
      companionName: companionName ?? this.companionName,
      companionDelaySeconds:
          companionDelaySeconds ?? this.companionDelaySeconds,
      therapistExportEnabled:
          therapistExportEnabled ?? this.therapistExportEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'vibrationStyle': vibrationStyle.name,
        'intensity': intensity.name,
        'selectedAudioAnchorId': selectedAudioAnchorId,
        'customAudioPath': customAudioPath,
        'allowAutoEscalateToGrounding': allowAutoEscalateToGrounding,
        'escalateAfterSeconds': escalateAfterSeconds,
        'bedPartnerMode': bedPartnerMode,
        'muteAudioAtNight': muteAudioAtNight,
        'audioQuietMinutesAfterSleep': audioQuietMinutesAfterSleep,
        'requirePreviewedVoiceAnchor': requirePreviewedVoiceAnchor,
        'voiceAnchorPreviewed': voiceAnchorPreviewed,
        'companionAlertEnabled': companionAlertEnabled,
        'companionConsentGiven': companionConsentGiven,
        'companionPhone': companionPhone,
        'companionName': companionName,
        'companionDelaySeconds': companionDelaySeconds,
        'therapistExportEnabled': therapistExportEnabled,
      };

  factory InterventionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InterventionConfig();
    return InterventionConfig(
      mode: InterventionMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => InterventionMode.combined,
      ),
      vibrationStyle: VibrationStyle.values.firstWhere(
        (e) => e.name == json['vibrationStyle'],
        orElse: () => VibrationStyle.breath46,
      ),
      intensity: StimulusIntensity.values.firstWhere(
        (e) => e.name == json['intensity'],
        orElse: () => StimulusIntensity.gentle,
      ),
      selectedAudioAnchorId:
          json['selectedAudioAnchorId'] as String? ?? 'rain',
      customAudioPath: json['customAudioPath'] as String?,
      allowAutoEscalateToGrounding:
          json['allowAutoEscalateToGrounding'] as bool? ?? true,
      escalateAfterSeconds: (json['escalateAfterSeconds'] as num?)?.toInt() ?? 25,
      bedPartnerMode: json['bedPartnerMode'] as bool? ?? false,
      muteAudioAtNight: json['muteAudioAtNight'] as bool? ?? false,
      audioQuietMinutesAfterSleep:
          (json['audioQuietMinutesAfterSleep'] as num?)?.toInt() ?? 10,
      requirePreviewedVoiceAnchor:
          json['requirePreviewedVoiceAnchor'] as bool? ?? true,
      voiceAnchorPreviewed: json['voiceAnchorPreviewed'] as bool? ?? false,
      companionAlertEnabled: json['companionAlertEnabled'] as bool? ?? false,
      companionConsentGiven: json['companionConsentGiven'] as bool? ?? false,
      companionPhone: json['companionPhone'] as String?,
      companionName: json['companionName'] as String?,
      companionDelaySeconds:
          (json['companionDelaySeconds'] as num?)?.toInt() ?? 90,
      therapistExportEnabled: json['therapistExportEnabled'] as bool? ?? false,
    );
  }
}
