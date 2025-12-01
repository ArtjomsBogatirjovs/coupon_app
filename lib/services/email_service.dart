import 'package:coupon_app/core/settings_controller.dart';
import 'package:coupon_app/db/emails_repository.dart';
import 'package:coupon_app/models/email.dart';
import 'package:coupon_app/models/send_email_result.dart';

class EmailService {
  static const int _monthMs = 62 * 24 * 60 * 60 * 1000;
  final EmailsRepository _emailsRepository;
  final SettingsController _settingsController;

  EmailService(this._emailsRepository, this._settingsController);

  Future<EmailEntry?> getEmailEntry(String email) async {
    final normalizedMail = _normalizeEmail(email);
    return await _emailsRepository.get(normalizedMail);
  }

  Future<void> createOrUpdate(EmailEntry entry) async {
    await _emailsRepository.upsert(entry);
  }

  bool _isGmail(String email) {
    return _normalizeEmail(email).endsWith("@gmail.com");
  }

  EmailEntry createNewEntry(String email) {
    final normalizedMail = _normalizeEmail(email);
    final now = DateTime.now().millisecondsSinceEpoch;
    final bool gmail = _isGmail(normalizedMail);
    return EmailEntry(
      mail: normalizedMail,
      isGmail: gmail,
      lastSent: now,
      lastSentBasicMail: (!_isInfiniteGmailEnabled() || !gmail) ? now : null,
      timesSent: (!_isInfiniteGmailEnabled() || !gmail) ? 0 : 1,
    );
  }

  EmailEntry incrementSendStats(EmailEntry entry) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return EmailEntry(
      mail: entry.mail,
      isGmail: entry.isGmail,
      lastSent: now,
      lastSentBasicMail: (!_isInfiniteGmailEnabled() || !entry.isGmail)
          ? now
          : entry.lastSentBasicMail,
      timesSent: (!_isInfiniteGmailEnabled() || !entry.isGmail)
          ? entry.timesSent
          : entry.timesSent + 1,
    );
  }

  SendEmailResult createResult(EmailEntry? existed, EmailEntry sent) {
    String? warningText;
    if (existed != null &&
        existed.lastSentBasicMail != null &&
        sent.lastSentBasicMail != null &&
        sent.lastSentBasicMail! - existed.lastSentBasicMail! < _monthMs) {
      warningText =
          'This e-mail received a coupon last 2 month. Unique coupon not guaranteed!';
    }
    return SendEmailResult(entry: sent, warningText: warningText);
  }

  String buildSendAddress(EmailEntry entry) {
    final bool gmail = entry.isGmail;
    final email = entry.mail;
    if (!_isInfiniteGmailEnabled() || !gmail) {
      return email;
    }

    final atIndex = email.indexOf('@');
    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    return '$local+${entry.timesSent}$domain';
  }

  bool _isInfiniteGmailEnabled() {
    return _settingsController.infiniteGmail;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}
