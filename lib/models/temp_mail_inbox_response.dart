import 'package:json_annotation/json_annotation.dart';

part 'temp_mail_inbox_response.g.dart';

@JsonSerializable()
class TempMailInboxResponse {
  final bool read;
  final bool expanded;
  final bool forwarded;
  final bool repliedTo;
  final DateTime sentDate;
  final String sentDateFormatted;
  final String? sender;
  final String? from;
  final String subject;
  final String bodyPlainText;
  final String bodyHtmlContent;
  final String contentType;
  final String bodyPreview;
  final String id;
  final String recipient;
  final List<dynamic> attachments;

  TempMailInboxResponse({
    required this.read,
    required this.expanded,
    required this.forwarded,
    required this.repliedTo,
    required this.sentDate,
    required this.sentDateFormatted,
    required this.sender,
    required this.from,
    required this.subject,
    required this.bodyPlainText,
    required this.bodyHtmlContent,
    required this.contentType,
    required this.bodyPreview,
    required this.id,
    required this.recipient,
    required this.attachments,
  });

  factory TempMailInboxResponse.fromJson(Map<String, dynamic> json) =>
      _$TempMailInboxResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TempMailInboxResponseToJson(this);
}
