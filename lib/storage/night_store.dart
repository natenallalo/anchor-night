import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/intervention_config.dart';
import '../domain/night_session.dart';
import '../domain/personal_baseline.dart';
import '../domain/priority_contact.dart';

class NightStore {
  static const _configKey = 'intervention_config_v1';
  static const _baselineKey = 'personal_baseline_v1';
  static const _voicePathKey = 'voice_anchor_path_v1';
  static const _contactsKey = 'priority_contacts_v1';
  static const _sessionsKey = 'night_sessions_v1';
  static const _onboardingKey = 'onboarding_done_v1';
  static const _disclaimerKey = 'disclaimer_accepted_v1';
  static const _localeKey = 'locale_code_v1';

  Future<InterventionConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null) return const InterventionConfig();
    return InterventionConfig.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveConfig(InterventionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    if (config.customAudioPath != null) {
      await prefs.setString(_voicePathKey, config.customAudioPath!);
    }
  }

  Future<PersonalBaseline> loadBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_baselineKey);
    if (raw == null) return const PersonalBaseline();
    return PersonalBaseline.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveBaseline(PersonalBaseline baseline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baselineKey, jsonEncode(baseline.toJson()));
  }

  Future<String?> loadVoicePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_voicePathKey);
  }

  Future<List<PriorityContact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_contactsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PriorityContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveContacts(List<PriorityContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _contactsKey,
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<NightSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => NightSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSessions(List<NightSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    // שומרים עד 30 לילות אחרונים
    final trimmed = sessions.length > 30
        ? sessions.sublist(sessions.length - 30)
        : sessions;
    await prefs.setString(
      _sessionsKey,
      jsonEncode(trimmed.map((s) => s.toJson()).toList()),
    );
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  Future<bool> isDisclaimerAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disclaimerKey) ?? false;
  }

  Future<void> setDisclaimerAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerKey, value);
  }

  Future<String> loadLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'he';
  }

  Future<void> saveLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }
}
