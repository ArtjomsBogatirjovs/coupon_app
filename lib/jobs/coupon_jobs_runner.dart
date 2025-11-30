import 'dart:async';
import 'package:coupon_app/api/coupon_view_api.dart';
import 'package:coupon_app/api/ten_minute_mail_api.dart';
import 'package:coupon_app/core/constants.dart';
import 'package:html/parser.dart' as html;
import '../db/coupon_jobs_repository.dart';
import '../db/coupons_repository.dart';
import '../models/coupon.dart';
import '../models/coupon_job.dart';
import '../models/coupon_job_history.dart';
import '../models/temp_mail_inbox_response.dart';

class CouponJobsRunner {
  final CouponJobsRepository _jobsRepo;
  final CouponsRepository _couponsRepo;
  final TenMinuteMailApi _tenMinuteMailApi;
  final CouponViewApi _couponViewApi;

  Timer? _timer;
  bool _processing = false;

  CouponJobsRunner(this._jobsRepo, this._couponsRepo, this._tenMinuteMailApi, this._couponViewApi);

  void ensureRunning() {
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_processing) {
      return;
    }
    _processing = true;

    try {
      final jobs = await _jobsRepo.getPendingJobs();
      if (jobs.isEmpty) {
        stop();
        return;
      }
      final now = DateTime.now();

      final expiredJobs = <CouponJob>[];
      final jobsToRun = <CouponJob>[];

      for (final job in jobs) {
        final ageMinutes = now.difference(job.createdAt).inMinutes;

        if (job.tries >= 10 ||
            job.status != CouponJobStatus.pending ||
            ageMinutes >= AppConstants.jobExpiringInMinutes) {
          expiredJobs.add(job);
        } else {
          jobsToRun.add(job);
        }
      }

      for (final job in jobsToRun) {
        await _processJob(job);
      }

      for (final job in expiredJobs) {
        await _handleOldJob(job);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _processJob(CouponJob job) async {
    final startedAt = job.createdAt;
    final now = DateTime.now();

    try {
      final coupon = await _tryFetchCouponWithCookies(job);

      if (coupon == null) {
        return;
      }

      await _couponsRepo.insert(coupon);

      final history = CouponJobHistory(
        mail: job.mail,
        cookieHeader: job.cookieHeader,
        createdAt: startedAt,
        finishedAt: now,
        success: true,
        error: null,
      );
      await _jobsRepo.insertHistory(history);

      await _jobsRepo.deleteJob(job.id!);
    } catch (e) {
      final history = CouponJobHistory(
        mail: job.mail,
        cookieHeader: job.cookieHeader,
        createdAt: startedAt,
        finishedAt: now,
        success: false,
        error: e.toString(),
      );
      await _jobsRepo.insertHistory(history);
      await _jobsRepo.deleteJob(job.id!);
    }
  }

  Future<void> _handleOldJob(CouponJob job) async {
    final history = CouponJobHistory(
      mail: job.mail,
      cookieHeader: job.cookieHeader,
      createdAt: job.createdAt,
      finishedAt: DateTime.now(),
      success: false,
      error: 'Job expired after 10 minutes',
    );

    await _jobsRepo.insertHistory(history);
    await _jobsRepo.deleteJob(job.id!);
  }

  Future<Coupon?> _tryFetchCouponWithCookies(CouponJob job) async {
    final List<TempMailInboxResponse> inboxMails = await _tenMinuteMailApi
        .getInbox(job.cookieHeader);
    print("trying get mail");
    if (inboxMails.isEmpty) {
      return null;
    }
    print("MAIL EXIST");
    print("cookies - ${job.cookieHeader}");
    TempMailInboxResponse? couponMail;

    for (final m in inboxMails) {
      if (m.subject == AppConstants.emailSubject ||
          (m.sender != null && m.sender!.contains(AppConstants.emailSender))) {
        couponMail = m;
        break;
      }
    }

    if (couponMail == null) {
      print("Wrong mail, wrong sender");
      return null;
    }
    if (couponMail.bodyPlainText.isEmpty) {
      throw Exception("WTF");
    }
    final match = RegExp(
      r'https://api\.couponcarrier\.io/r/[^\s)]+',
    ).firstMatch(couponMail.bodyPlainText);
    if (match == null) {
      print("Wrong match in regexp");
      return null;
    }
    final couponUrl = match.group(0)!;

    final uri = Uri.parse(couponUrl);
    String? hsh = uri.queryParameters['hsh'];
    print("getting html for coupon");
    print("link - $couponUrl");
    final res = await _couponViewApi.getCouponHtml(job.mail, hsh!);
    final htmlStr = res.data as String;
    final doc = html.parse(htmlStr);
    print("HTML received");
    final h3 = doc.querySelector('h3.code-tag');
    if (h3 == null) {
      print('ERROR: Coupon code not found');
      throw Exception('Coupon code not found');
    }

    final codeText = h3.text.trim();
    return Coupon(
      id: null,
      title: 'Coffee coupon',
      code: codeText,
      createdAt: DateTime.now(),
      used: false,
    );
  }
}
