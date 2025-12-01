import 'package:sqflite/sqflite.dart';
import '../models/coupon.dart';

class CouponsRepository {
  final Database _db;

  CouponsRepository(this._db);

  Future<List<Coupon>> getAvailable() async {
    final result = await _db.query(
      'coupons',
      where: 'used = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return result.map(_fromRow).toList();
  }

  Future<List<Coupon>> getUsed() async {
    final result = await _db.query(
      'coupons',
      where: 'used = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map(_fromRow).toList();
  }

  Future<int> insert(Coupon coupon) async {
    print("coupon added");
    return _db.insert('coupons', {
      'title': coupon.title,
      'code': coupon.code,
      'created_at': coupon.createdAt.toIso8601String(),
      'used': coupon.used ? 1 : 0,
      'link': coupon.link,
    });
  }

  Future<void> markUsed(int id) async {
    await _db.update('coupons', {'used': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Coupon _fromRow(Map<String, Object?> row) {
    return Coupon(
      id: row['id'] as int,
      title: row['title'] as String,
      code: row['code'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      used: (row['used'] as int) == 1,
      link: (row['link'] as String?),
    );
  }
}
