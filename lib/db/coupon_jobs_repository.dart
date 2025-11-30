import 'package:sqflite/sqflite.dart';

import '../models/coupon_job.dart';
import '../models/coupon_job_history.dart';


class CouponJobsRepository {
  final Database db;

  CouponJobsRepository(this.db);

  Future<int> insertJob(CouponJob job) =>
      db.insert('coupon_jobs', job.toMap());

  Future<List<CouponJob>> getPendingJobs() async {
    final rows = await db.query(
      'coupon_jobs',
      where: 'status = ?',
      whereArgs: [CouponJobStatus.pending.index],
    );
    return rows.map(CouponJob.fromMap).toList();
  }

  Future<void> deleteJob(int id) async {
    await db.delete(
      'coupon_jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertHistory(CouponJobHistory history) async {
    await db.insert('coupon_jobs_history', history.toMap());
  }
}