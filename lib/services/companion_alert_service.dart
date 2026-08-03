import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

/// התראת מלווה עם עיכוב — מתבטלת בלחיצת "אני בסדר".
class CompanionAlertService {
  Timer? _timer;
  bool _pending = false;
  DateTime? _firesAt;

  bool get isPending => _pending;
  DateTime? get firesAt => _firesAt;

  Duration? get remaining {
    if (!_pending || _firesAt == null) return null;
    final left = _firesAt!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void schedule({
    required String phone,
    required String userDisplayName,
    required int delaySeconds,
    void Function()? onFired,
  }) {
    cancel();
    _pending = true;
    _firesAt = DateTime.now().add(Duration(seconds: delaySeconds));
    _timer = Timer(Duration(seconds: delaySeconds), () async {
      _pending = false;
      _firesAt = null;
      await _sendSms(
        phone: phone,
        body:
            'הודעה מעוגן לילה: ייתכן ש־$userDisplayName זקוק/ה לתמיכה כרגע. '
            'זו התראה אוטומטית — בדקו שהכול בסדר.',
      );
      onFired?.call();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = false;
    _firesAt = null;
  }

  Future<void> _sendSms({required String phone, required String body}) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleaned,
      queryParameters: {'body': body},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void dispose() => cancel();
}
