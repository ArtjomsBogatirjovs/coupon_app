import 'package:sqflite/sqflite.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';
import '../models/coupon.dart';

class CouponsRepository {
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.db,
    source: 'CouponsRepository',
  );
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
    return _db.insert('coupons', {
      'title': coupon.title,
      'code': coupon.code,
      'created_at': coupon.createdAt.toIso8601String(),
      'used': coupon.used ? 1 : 0,
      'link': coupon.link,
    });
  }

  Future<int> deleteAllUsed() async {
    final chainId = 'cleanup:used:${DateTime.now().microsecondsSinceEpoch}';

    await _log.info(
      'Deleting all used coupons',
      chainId: chainId,
      details: 'DELETE FROM coupons WHERE used = 1',
    );

    try {
      final deleted = await _db.delete(
        'coupons',
        where: 'used = ?',
        whereArgs: [1],
      );

      await _log.info(
        'Used coupons deleted',
        chainId: chainId,
        extra: {'deletedCount': deleted},
      );

      return deleted;
    } catch (e, s) {
      final error = DbError(
        message: 'Failed to delete used coupons',
        detail: 'DELETE coupons used=1',
        operation: 'delete',
        table: 'coupons',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);
      rethrow;
    }
  }

  Future<int> deleteAllAvailable() async {
    final chainId =
        'cleanup:available:${DateTime.now().microsecondsSinceEpoch}';

    await _log.info(
      'Deleting all available coupons',
      chainId: chainId,
      details: 'DELETE FROM coupons WHERE used = 0',
    );

    try {
      final deleted = await _db.delete(
        'coupons',
        where: 'used = ?',
        whereArgs: [0],
      );

      await _log.info(
        'Available coupons deleted',
        chainId: chainId,
        extra: {'deletedCount': deleted},
      );

      return deleted;
    } catch (e, s) {
      final error = DbError(
        message: 'Failed to delete available coupons',
        detail: 'DELETE coupons used=0',
        operation: 'delete',
        table: 'coupons',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);
      rethrow;
    }
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
