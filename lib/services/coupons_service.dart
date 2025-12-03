import 'package:coupon_app/api/coupon_view_api.dart';
import 'package:coupon_app/api/generate_coupon_api.dart';
import 'package:coupon_app/core/coupon_controller.dart';
import 'package:coupon_app/db/coupon_jobs_repository.dart';
import 'package:coupon_app/db/coupons_repository.dart';
import 'package:coupon_app/jobs/coupon_jobs_runner.dart';
import 'package:coupon_app/models/email.dart';
import 'package:html/parser.dart' as html;
import '../api/ten_minute_mail_api.dart';
import '../core/constants.dart';
import '../core/notification_service.dart';
import '../models/coupon.dart';
import '../models/coupon_job.dart';
import '../models/send_email_result.dart';
import '../models/temp_mail_address_response.dart';
import '../models/temp_mail_inbox_response.dart';
import 'email_service.dart';

class CouponsService {
  final TenMinuteMailApi _tenMinuteMailApi;
  final GenerateCouponApi _generateCouponApi;
  final CouponJobsRepository _couponJobsRepository;
  final CouponsRepository _couponsRepository;
  final CouponJobsRunner _couponJobsRunner;
  final CouponsController _couponsController;
  final CouponViewApi _couponViewApi;
  final EmailService _emailService;

  CouponsService(
    this._tenMinuteMailApi,
    this._generateCouponApi,
    this._couponJobsRepository,
    this._couponJobsRunner,
    this._couponsController,
    this._couponsRepository,
    this._couponViewApi,
    this._emailService,
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
    _tenMinuteMailApi.deleteCookies();
  }

  Future<SendEmailResult> sendCouponToEmail(String email) async {
    final EmailEntry? existedEntry = await _emailService.getEmailEntry(email);
    EmailEntry emailEntry;
    if (existedEntry == null) {
      emailEntry = _emailService.createNewEntry(email);
    } else {
      emailEntry = _emailService.incrementSendStats(existedEntry);
    }
    final emailToSent = _emailService.buildSendAddress(emailEntry);
    await _generateCouponApi.generateCoupon(emailToSent);
    await _emailService.createOrUpdate(emailEntry);
    return _emailService.createResult(existedEntry, emailEntry);
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

      if (job.tries >= AppConstants.maxTries ||
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
    try {
      final coupon = await _tryFetchCouponWithCookies(job);

      if (coupon == null) {
        _couponJobsRepository.incrementTries(job);
        return;
      }

      await insertCoupon(coupon);

      await _couponJobsRepository.deleteJob(job.id!);
    } catch (e) {
      await _couponJobsRepository.deleteJob(job.id!);
    }
  }

  Future<void> insertCoupon(Coupon coupon) async {
    await _couponsRepository.insert(coupon);
    _couponsController.notifyChanged();
    await NotificationService.showCouponGenerated(coupon.code);
  }

  Future<void> _handleOldJob(CouponJob job) async {
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
