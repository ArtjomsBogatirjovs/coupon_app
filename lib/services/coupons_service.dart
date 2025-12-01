import 'package:coupon_app/api/coupon_view_api.dart';
import 'package:coupon_app/api/generate_coupon_api.dart';
import 'package:coupon_app/core/coupon_controller.dart';
import 'package:coupon_app/db/coupon_jobs_repository.dart';
import 'package:coupon_app/db/coupons_repository.dart';
import 'package:coupon_app/jobs/coupon_jobs_runner.dart';
import 'package:html/parser.dart' as html;
import '../api/ten_minute_mail_api.dart';
import '../core/constants.dart';
import '../models/coupon.dart';
import '../models/coupon_job.dart';
import '../models/coupon_job_history.dart';
import '../models/temp_mail_address_response.dart';
import '../models/temp_mail_inbox_response.dart';

class CouponsService {
  final TenMinuteMailApi _tenMinuteMailApi;
  final GenerateCouponApi _generateCouponApi;
  final CouponJobsRepository _couponJobsRepository;
  final CouponsRepository _couponsRepository;
  final CouponJobsRunner _couponJobsRunner;
  final CouponsController _couponsController;
  final CouponViewApi _couponViewApi;

  CouponsService(
    this._tenMinuteMailApi,
    this._generateCouponApi,
    this._couponJobsRepository,
    this._couponJobsRunner,
    this._couponsController,
    this._couponsRepository,
    this._couponViewApi,
  );

  Future<void> markUsed(int id) async {
    await _couponsRepository.markUsed(id);
    await _couponsController.notifyChanged();
  }

  Future<void> deleteAllUsed() async {
    await _couponsRepository.deleteAllUsed();
    await _couponsController.notifyChanged();
  }

  Future<void> deleteAllAvailable() async {
    await _couponsRepository.deleteAllAvailable();
    await _couponsController.notifyChanged();
  }

  Future<void> requestCoupon() async {
    TempMailAddressResponse address = await _tenMinuteMailApi
        .createNewAddress();
    _startCouponJob(address);
  }

  Future<void> sendCouponToEmail(String email) async {
    await _generateCouponApi.generateCoupon(email);
  }

  Future<void> _startCouponJob(TempMailAddressResponse address) async {
    await _generateCouponApi.generateCoupon(address.address);

    final cookieHeader = await _tenMinuteMailApi.getCookies();
    final cookiesString = cookieHeader
        .map((c) => '${c.name}=${c.value}')
        .join('; ');
    final job = CouponJob(
      cookieHeader: cookiesString,
      mail: address.address,
      createdAt: DateTime.now(),
      status: CouponJobStatus.pending,
    );

    await _couponJobsRepository.insertJob(job);

    _couponJobsRunner.call(_processPendingJobs);
  }

  Future<bool> _processPendingJobs() async {
    final jobs = await _couponJobsRepository.getPendingJobs();
    if (jobs.isEmpty) {
      return false;
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

    return true;
  }

  Future<void> _processJob(CouponJob job) async {
    final startedAt = job.createdAt;
    final now = DateTime.now();

    try {
      final coupon = await _tryFetchCouponWithCookies(job);

      if (coupon == null) {
        return;
      }

      await insertCoupon(coupon);

      final history = CouponJobHistory(
        mail: job.mail,
        cookieHeader: job.cookieHeader,
        createdAt: startedAt,
        finishedAt: now,
        success: true,
        error: null,
      );
      await _couponJobsRepository.insertHistory(history);
      await _couponJobsRepository.deleteJob(job.id!);
    } catch (e) {
      final history = CouponJobHistory(
        mail: job.mail,
        cookieHeader: job.cookieHeader,
        createdAt: startedAt,
        finishedAt: now,
        success: false,
        error: e.toString(),
      );
      await _couponJobsRepository.insertHistory(history);
      await _couponJobsRepository.deleteJob(job.id!);
    }
  }

  Future<void> insertCoupon(Coupon coupon) async {
    await _couponsRepository.insert(coupon);
    _couponsController.notifyChanged();
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

    await _couponJobsRepository.insertHistory(history);
    await _couponJobsRepository.deleteJob(job.id!);
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
    final hsh = uri.queryParameters['hsh'];
    if (hsh == null) {
      throw Exception('Missing hsh in coupon URL');
    }

    print("getting html for coupon");
    print("link - $couponUrl");

    final res = await _couponViewApi.getCouponHtml(job.mail, hsh);
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
      link: couponUrl,
    );
  }
}
