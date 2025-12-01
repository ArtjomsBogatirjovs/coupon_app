enum CouponJobStatus { pending, completed, failed }

class CouponJob {
  final int? id;
  final String cookieHeader;
  final String mail;
  final DateTime createdAt;
  final CouponJobStatus status;
  int tries;

  CouponJob({
    this.id,
    required this.mail,
    required this.cookieHeader,
    required this.createdAt,
    required this.status,
    this.tries = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mail': mail,
    'cookie_header': cookieHeader,
    'created_at': createdAt.millisecondsSinceEpoch,
    'status': status.index,
    'tries': tries,
  };

  factory CouponJob.fromMap(Map<String, dynamic> map) => CouponJob(
    id: map['id'] as int?,
    mail: map['mail'] as String,
    cookieHeader: map['cookie_header'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    status: CouponJobStatus.values[map['status'] as int],
    tries: map['tries'] as int? ?? 0,
  );
}
