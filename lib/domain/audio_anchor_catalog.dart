class AudioAnchorOption {
  final String id;
  final String labelHe;
  final String labelEn;
  final String assetPath;
  final bool isMusic;

  const AudioAnchorOption({
    required this.id,
    required this.labelHe,
    required this.labelEn,
    required this.assetPath,
    this.isMusic = false,
  });
}

/// קטלוג עוגנים קוליים מובנים (ללא הקלטה אישית).
class AudioAnchorCatalog {
  static const builtIns = <AudioAnchorOption>[
    AudioAnchorOption(
      id: 'rain',
      labelHe: 'גשם עמום',
      labelEn: 'Soft rain',
      assetPath: 'assets/audio/rain.wav',
    ),
    AudioAnchorOption(
      id: 'white_noise',
      labelHe: 'רעש ורוד עדין',
      labelEn: 'Soft pink noise',
      assetPath: 'assets/audio/white_noise.wav',
    ),
    AudioAnchorOption(
      id: 'soft_tone',
      labelHe: 'טון נמוך רך',
      labelEn: 'Soft low tone',
      assetPath: 'assets/audio/soft_tone.wav',
      isMusic: true,
    ),
    AudioAnchorOption(
      id: 'ocean',
      labelHe: 'גלים רכים',
      labelEn: 'Soft ocean',
      assetPath: 'assets/audio/ocean.wav',
    ),
    AudioAnchorOption(
      id: 'forest',
      labelHe: 'יער בלילה',
      labelEn: 'Night forest',
      assetPath: 'assets/audio/forest.wav',
    ),
    AudioAnchorOption(
      id: 'stream',
      labelHe: 'נחל זורם',
      labelEn: 'Flowing stream',
      assetPath: 'assets/audio/stream.wav',
    ),
    AudioAnchorOption(
      id: 'wind',
      labelHe: 'רוח עדינה',
      labelEn: 'Gentle wind',
      assetPath: 'assets/audio/wind.wav',
    ),
    AudioAnchorOption(
      id: 'brown_noise',
      labelHe: 'רעש חום מרגיע',
      labelEn: 'Brown noise',
      assetPath: 'assets/audio/brown_noise.wav',
    ),
    AudioAnchorOption(
      id: 'singing_bowl',
      labelHe: 'קערת תהודה',
      labelEn: 'Singing bowl',
      assetPath: 'assets/audio/singing_bowl.wav',
      isMusic: true,
    ),
    AudioAnchorOption(
      id: 'ambient_pad',
      labelHe: 'פד אמביינט רך',
      labelEn: 'Soft ambient pad',
      assetPath: 'assets/audio/ambient_pad.wav',
      isMusic: true,
    ),
    AudioAnchorOption(
      id: 'piano_lullaby',
      labelHe: 'פסנתר מרגיע',
      labelEn: 'Calm piano',
      assetPath: 'assets/audio/piano_lullaby.wav',
      isMusic: true,
    ),
    AudioAnchorOption(
      id: 'harp_drift',
      labelHe: 'נבל עדין',
      labelEn: 'Soft harp',
      assetPath: 'assets/audio/harp_drift.wav',
      isMusic: true,
    ),
    AudioAnchorOption(
      id: 'night_crickets',
      labelHe: 'לילה שקט (חרגולים)',
      labelEn: 'Quiet crickets',
      assetPath: 'assets/audio/night_crickets.wav',
    ),
  ];

  static AudioAnchorOption? byId(String id) {
    for (final o in builtIns) {
      if (o.id == id) return o;
    }
    return null;
  }

  static String? assetPathFor(String id) => byId(id)?.assetPath;
}
