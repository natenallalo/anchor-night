import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// אנליטיקס מקומי מינימלי — רק עם opt-in, בלי שליחה לשרת.
class SoftAnalytics {
  static const _optInKey = 'analytics_opt_in_v1';
  static const _eventsKey = 'analytics_events_v1';

  Future<bool> isOptedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_optInKey) ?? false;
  }

  Future<void> setOptIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optInKey, value);
  }

  Future<void> track(String name, [Map<String, Object?> props = const {}]) async {
    if (!await isOptedIn()) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    final list = raw == null || raw.isEmpty
        ? <dynamic>[]
        : (jsonDecode(raw) as List<dynamic>);
    list.add({
      'name': name,
      'at': DateTime.now().toIso8601String(),
      'props': props,
    });
    final trimmed = list.length > 200 ? list.sublist(list.length - 200) : list;
    await prefs.setString(_eventsKey, jsonEncode(trimmed));
  }

  Future<List<Map<String, dynamic>>> exportLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
}
