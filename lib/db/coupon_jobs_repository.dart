import 'package:sqflite/sqflite.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';
import '../models/coupon_job.dart';

class CouponJobsRepository {
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.db,
    source: 'CouponJobsRepository',
  );

  final Database _db;

  CouponJobsRepository(this._db);

  Future<int> insertJob(CouponJob job, String chainId) async {
    await _log.info(
      'Inserting coupon job',
      chainId: chainId,
      details: 'INSERT INTO coupon_jobs',
      extra: job.toMap(),
    );

    try {
      final id = await _db.insert(
        'coupon_jobs',
        job.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _log.debug(
        'Coupon job inserted successfully',
        chainId: chainId,
        extra: {'id': id},
      );

      return id;
    } catch (e, st) {
      final error = DbError(
        message: 'Failed to insert coupon job',
        detail: 'coupon_jobs INSERT',
        operation: 'insert',
        table: 'coupon_jobs',
        cause: e,
        stackTrace: st,
      );

      await _log.errorFrom(error, chainId: chainId, extra: job.toMap());

      rethrow;
    }
  }

  Future<List<CouponJob>> getPendingJobs(String chainId) async {
    await _log.info(
      'Querying pending coupon jobs',
      chainId: chainId,
      details: 'SELECT * FROM coupon_jobs WHERE status = pending',
    );

    try {
      final rows = await _db.query(
        'coupon_jobs',
        where: 'status = ?',
        whereArgs: [CouponJobStatus.pending.index],
      );

      final jobs = rows.map(CouponJob.fromMap).toList();

      await _log.debug(
        'Pending jobs loaded',
        chainId: chainId,
        extra: {'count': jobs.length},
      );

      return jobs;
    } catch (e, s) {
      final error = DbError(
        message: 'Failed to load pending coupon jobs',
        detail: 'coupon_jobs SELECT pending',
        operation: 'query',
        table: 'coupon_jobs',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);

      rethrow;
    }
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
