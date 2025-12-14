import 'package:coupon_app/core/settings_controller.dart';
import 'package:coupon_app/db/emails_repository.dart';
import 'package:coupon_app/models/email.dart';
import 'package:coupon_app/models/send_email_result.dart';

import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';

class EmailService {
  static const int _monthMs = 62 * 24 * 60 * 60 * 1000;
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.db,
    source: 'EmailService',
  );
  final EmailsRepository _emailsRepository;
  final SettingsController _settingsController;

  EmailService(this._emailsRepository, this._settingsController);

  Future<EmailEntry?> getEmailEntry(String email, String chainId) async {
    final normalizedMail = _normalizeEmail(email);

    await _log.debug(
      'Fetching email entry',
      chainId: chainId,
      extra: {'email': email, 'normalized': normalizedMail},
    );

    try {
      final entry = await _emailsRepository.get(normalizedMail);

      await _log.debug(
        entry == null ? 'Email entry not found' : 'Email entry loaded',
        chainId: chainId,
        extra: {'normalized': normalizedMail, 'found': entry != null},
      );

      return entry;
    } catch (e, s) {
      final error = DbError(
        message: 'Failed to load email entry',
        detail: 'emails.get',
        operation: 'select',
        table: 'emails',
        cause: e,
        stackTrace: s,
      );
      await _log.errorFrom(error, chainId: chainId);

      rethrow;
    }
  }

  Future<void> createOrUpdate(EmailEntry entry, String chainId) async {
    await _log.info(
      'Creating or updating email entry',
      chainId: chainId,
      extra: {'email': entry.mail},
    );

    try {
      await _emailsRepository.upsert(entry);

      await _log.info(
        'Email entry saved',
        chainId: chainId,
        extra: {'email': entry.mail},
      );
    } catch (e, s) {
      final error = DbError(
        message: 'Failed to create or update email entry',
        detail: 'emails.upsert',
        operation: 'upsert',
        table: 'emails',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);

      rethrow;
    }
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
    if (!_isInfiniteGmailEnabled() &&
        existed != null &&
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
