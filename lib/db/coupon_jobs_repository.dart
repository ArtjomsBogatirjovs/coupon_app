import 'package:sqflite/sqflite.dart';
import '../models/coupon_job.dart';

class CouponJobsRepository {
  final Database _db;

  CouponJobsRepository(this._db);

  Future<int> insertJob(CouponJob job) =>
      _db.insert('coupon_jobs', job.toMap());

  Future<List<CouponJob>> getPendingJobs() async {
    final rows = await _db.query(
      'coupon_jobs',
      where: 'status = ?',
      whereArgs: [CouponJobStatus.pending.index],
    );
    return rows.map(CouponJob.fromMap).toList();
  }

  Future<void> deleteJob(int id) async {
    await _db.delete('coupon_jobs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementTries(CouponJob job) async {
    await _db.update(
      'coupon_jobs',
      {'tries': job.tries + 1},
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }
}
