class CouponJobHistory {
  final int? id;
  final String cookieHeader;
  final DateTime createdAt;
  final DateTime finishedAt;
  final bool success;
  final String? error;
  final String mail;

  CouponJobHistory({
    this.id,
    required this.mail,
    required this.cookieHeader,
    required this.createdAt,
    required this.finishedAt,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mail': mail,
    'cookie_header': cookieHeader,
    'created_at': createdAt.millisecondsSinceEpoch,
    'finished_at': finishedAt.millisecondsSinceEpoch,
    'success': success ? 1 : 0,
    'error': error,
  };
}
