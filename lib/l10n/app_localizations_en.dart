// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AnchorNight';

  @override
  String get nightGuardTab => 'Night guard';

  @override
  String get morningTab => 'My morning';

  @override
  String get groundingTab => 'Grounding';

  @override
  String get imOkay => 'I\'m okay — stop now';

  @override
  String get enterSleep => 'Enter sleep protection';

  @override
  String get supportToolOnly =>
      'Support tool only — not a substitute for care.';

  @override
  String get bedPartnerMode => 'Bed partner mode';

  @override
  String get companionAlert => 'Companion alert';

  @override
  String get exportTherapist => 'Export therapist summary';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get clinicalSafety => 'Safety guidelines';

  @override
  String get analyticsOptIn => 'Local analytics (opt-in)';

  @override
  String get language => 'Language';
}
