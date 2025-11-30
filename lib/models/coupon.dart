class Coupon {
  final int? id;
  final String title;
  final String code;
  final DateTime createdAt;
  final bool used;

  Coupon({
    this.id,
    required this.title,
    required this.code,
    required this.createdAt,
    required this.used,
  });
}
