import 'email.dart';

class SendEmailResult {
  final EmailEntry entry;
  final String? warningText;

  SendEmailResult({
    required this.entry,
    this.warningText,
  });
}
