class EmailEntry {
  final String mail;
  final int lastSent;
  final int? lastSentBasicMail;
  final int timesSent;
  final bool isGmail;

  EmailEntry({
    required this.mail,
    required this.lastSent,
    required this.lastSentBasicMail,
    required this.timesSent,
    required this.isGmail,
  });

  factory EmailEntry.fromMap(Map<String, Object?> map) {
    return EmailEntry(
      mail: map['mail'] as String,
      lastSent: map['last_sent'] as int,
      lastSentBasicMail: map['last_sent_basic_mail'] as int?,
      timesSent: map['times_sent'] as int,
      isGmail: (map['is_gmail'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'mail': mail,
      'last_sent': lastSent,
      'last_sent_basic_mail': lastSentBasicMail,
      'times_sent': timesSent,
      'is_gmail': isGmail ? 1 : 0,
    };
  }
}
