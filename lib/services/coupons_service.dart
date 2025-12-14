import 'package:coupon_app/api/coupon_view_api.dart';
import 'package:coupon_app/api/generate_coupon_api.dart';
import 'package:coupon_app/core/coupon_controller.dart';
import 'package:coupon_app/db/coupon_jobs_repository.dart';
import 'package:coupon_app/db/coupons_repository.dart';
import 'package:coupon_app/jobs/coupon_jobs_runner.dart';
import 'package:coupon_app/models/email.dart';
import 'package:html/parser.dart' as html;
import 'package:workmanager/workmanager.dart';
import '../api/ten_minute_mail_api.dart';
import '../core/constants.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';
import '../core/notification_service.dart';
import '../models/coupon.dart';
import '../models/coupon_job.dart';
import '../models/send_email_result.dart';
import '../models/temp_mail_address_response.dart';
import '../models/temp_mail_inbox_response.dart';
import 'email_service.dart';

class CouponsService {
  static CouponsService? _instance;
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.job,
    source: 'CouponsService',
  );

  final TenMinuteMailApi _tenMinuteMailApi;
  final GenerateCouponApi _generateCouponApi;
  final CouponJobsRepository _couponJobsRepository;
  final CouponsRepository _couponsRepository;
  final CouponJobsRunner _couponJobsRunner;
  final CouponsController _couponsController;
  final CouponViewApi _couponViewApi;
  final EmailService _emailService;

  CouponsService._internal(
    this._tenMinuteMailApi,
    this._generateCouponApi,
    this._couponJobsRepository,
    this._couponJobsRunner,
    this._couponsController,
    this._couponsRepository,
    this._couponViewApi,
    this._emailService,
  );

  static CouponsService init({
    required TenMinuteMailApi tenMinuteMailApi,
    required GenerateCouponApi generateCouponApi,
    required CouponJobsRepository couponJobsRepository,
    required CouponsRepository couponsRepository,
    required CouponJobsRunner couponJobsRunner,
    required CouponsController couponsController,
    required CouponViewApi couponViewApi,
    required EmailService emailService,
  }) {
    _instance ??= CouponsService._internal(
      tenMinuteMailApi,
      generateCouponApi,
      couponJobsRepository,
      couponJobsRunner,
      couponsController,
      couponsRepository,
      couponViewApi,
      emailService,
    );
    return _instance!;
  }

  static CouponsService get instance {
    if (_instance == null) {
      throw StateError('CouponsService must be initialized via init()');
    }
    return _instance!;
  }

  Future<void> markUsed(int id) async {
    await _couponsRepository.markUsed(id);
    await _couponsController.notifyChanged();
  }

  Future<int> deleteAllUsed() async {
    final deleted = await _couponsRepository.deleteAllUsed();
    await _couponsController.notifyChanged();
    return deleted;
  }

  Future<void> deleteAllAvailable() async {
    await _couponsRepository.deleteAllAvailable();
    await _couponsController.notifyChanged();
  }

  Future<void> requestCoupon() async {
    _createCouponJob();
  }

  void _createCouponJob() {
    _couponJobsRunner.addJob(_createCoupon, null, runJob: true);
  }

  void processCouponJob(String chainId) {
    _couponJobsRunner.addJob(processPendingJobs, chainId);
  }

  Future<bool> _createCoupon(String chainId) async {
    await _log.info('Starting coupon creation', chainId: chainId);
    try {
      TempMailAddressResponse address = await _tenMinuteMailApi
          .createNewAddress(chainId);

      await _generateCouponApi.generateCoupon(address.address, chainId);
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

      await _couponJobsRepository.insertJob(job, chainId);

      processCouponJob(chainId);
      await Workmanager().registerOneOffTask(
        'coupon_job_${job.createdAt.millisecondsSinceEpoch}',
        AppConstants.backgroundProcessCouponJobs,
        inputData: {'chainId': chainId},
        initialDelay: const Duration(seconds: 30),
        constraints: Constraints(networkType: NetworkType.connected),
      );
      return false;
    } catch (e, s) {
      final error = UnknownError(
        message: 'Failed to create coupon',
        detail: '_createCoupon',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);

      return true;
    } finally {
      _tenMinuteMailApi.deleteCookies();
    }
  }

  Future<SendEmailResult> sendCouponToEmail(String email) async {
    final chainId = 'email:$email:${DateTime.now().microsecondsSinceEpoch}';

    await _log.info(
      'Starting send coupon to email',
      chainId: chainId,
      extra: {'email': email},
    );

    try {
      final EmailEntry? existedEntry = await _emailService.getEmailEntry(
        email,
        chainId,
      );

      EmailEntry emailEntry;

      if (existedEntry == null) {
        await _log.debug(
          'Email entry not found, creating new',
          chainId: chainId,
        );
        emailEntry = _emailService.createNewEntry(email);
      } else {
        await _log.debug(
          'Email entry found, incrementing stats',
          chainId: chainId,
          extra: {'sentCount': existedEntry.timesSent},
        );
        emailEntry = _emailService.incrementSendStats(existedEntry);
      }

      final emailToSend = _emailService.buildSendAddress(emailEntry);

      await _log.info(
        'Sending coupon request',
        chainId: chainId,
        extra: {'emailToSend': emailToSend},
      );

      await _generateCouponApi.generateCoupon(emailToSend, chainId);

      await _emailService.createOrUpdate(emailEntry, chainId);

      await _log.info(
        'Coupon successfully sent to email',
        chainId: chainId,
        extra: {'email': email, 'finalSendCount': emailEntry.timesSent},
      );

      return _emailService.createResult(existedEntry, emailEntry);
    } catch (e, s) {
      final error = UnknownError(
        message: 'Failed to send coupon to email',
        detail: 'sendCouponToEmail',
        cause: e,
        stackTrace: s,
      );
      await _log.errorFrom(error, chainId: chainId);

      rethrow;
    }
  }

  Future<bool> processPendingJobs(String chainId) async {
    await _log.info('Processing pending jobs started', chainId: chainId);
    final jobs = await _couponJobsRepository.getPendingJobs(chainId);
    await _log.debug(
      'Pending jobs loaded',
      chainId: chainId,
      extra: {'count': jobs.length},
    );
    if (jobs.isEmpty) {
      await _log.info('No pending jobs to process', chainId: chainId);
      return true;
    }

    final now = DateTime.now();

    final expiredJobs = <CouponJob>[];
    final jobsToRun = <CouponJob>[];

    for (final job in jobs) {
      final ageMinutes = now.difference(job.createdAt).inMinutes;

      final isExpired =
          job.tries >= AppConstants.maxTries ||
          job.status != CouponJobStatus.pending ||
          ageMinutes >= AppConstants.jobExpiringInMinutes;

      if (isExpired) {
        expiredJobs.add(job);
        await _log.info(
          'Job added to expired',
          chainId: chainId,
          extra: {
            'jobId': job.id,
            'status': job.status,
            'diffInMinutes': ageMinutes,
          },
        );
      } else {
        jobsToRun.add(job);
      }
    }
    await _log.info(
      'Jobs classified',
      chainId: chainId,
      extra: {
        'toRun': jobsToRun.length,
        'expired': expiredJobs.length,
        'maxTries': AppConstants.maxTries,
        'jobExpiringInMinutes': AppConstants.jobExpiringInMinutes,
      },
    );
    Object? error;
    for (final job in jobsToRun) {
      await _log.debug(
        'Processing job',
        chainId: chainId,
        extra: {
          'jobId': job.id,
          'tries': job.tries,
          'createdAt': job.createdAt.toIso8601String(),
        },
      );

      try {
        await _processJob(job, chainId);

        await _log.debug(
          'Job processed',
          chainId: chainId,
          extra: {'jobId': job.id},
        );
      } catch (e, s) {
        await _log.errorFrom(
          UnknownError(
            message: 'Job processing failed',
            detail: 'processPendingJobs -> _processJob',
            cause: e,
            stackTrace: s,
          ),
          chainId: chainId,
          extra: {'jobId': job.id},
        );
        error = e;
      }
    }

    for (final job in expiredJobs) {
      await _log.warning(
        'Handling expired job',
        chainId: chainId,
        extra: {
          'jobId': job.id,
          'tries': job.tries,
          'createdAt': job.createdAt.toIso8601String(),
          'ageMinutes': now.difference(job.createdAt).inMinutes,
          'status': job.status.name,
        },
      );

      try {
        await _handleOldJob(job);

        await _log.info(
          'Expired job handled',
          chainId: chainId,
          extra: {'jobId': job.id},
        );
      } catch (e, s) {
        await _log.errorFrom(
          UnknownError(
            message: 'Failed to handle expired job',
            detail: 'processPendingJobs -> _handleOldJob',
            cause: e,
            stackTrace: s,
          ),
          chainId: chainId,
          extra: {'jobId': job.id},
        );
        error = e;
      }
    }

    await _log.info(
      'Processing pending jobs finished',
      chainId: chainId,
      extra: {
        'processed': jobsToRun.length,
        'expiredHandled': expiredJobs.length,
        'noErrors': error == null,
      },
    );

    return error == null;
  }

  Future<void> _processJob(CouponJob job, String chainId) async {
    try {
      await _log.debug(
        'Trying to fetch coupon from inbox',
        chainId: chainId,
        extra: {'jobId': job.id, 'tries': job.tries},
      );

      final coupon = await _tryFetchCouponWithCookies(job, chainId);

      if (coupon == null) {
        await _log.warning(
          'Coupon not found in inbox, will retry',
          chainId: chainId,
          extra: {'jobId': job.id, 'triesBefore': job.tries},
        );
        await _couponJobsRepository.incrementTries(job);

        return;
      }

      await _log.info(
        'Coupon fetched successfully',
        chainId: chainId,
        extra: {'jobId': job.id, 'couponCode': coupon.code},
      );

      await insertCoupon(coupon);

      await _log.info(
        'Coupon inserted successfully',
        chainId: chainId,
        extra: {'jobId': job.id, 'couponCode': coupon.code},
      );

      await _couponJobsRepository.deleteJob(job.id!);

      await _log.info(
        'Coupon job completed and removed',
        chainId: chainId,
        extra: {'jobId': job.id},
      );
    } catch (e, s) {
      await _log.errorFrom(
        UnknownError(
          message: 'Failed to process coupon job',
          detail: '_processJob',
          cause: e,
          stackTrace: s,
        ),
        chainId: chainId,
        extra: {
          'jobId': job.id,
          'triesBefore': job.tries,
          'cause': e.toString(),
        },
      );
      await _couponJobsRepository.incrementTries(job);
      rethrow;
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

  Future<Coupon?> _tryFetchCouponWithCookies(
    CouponJob job,
    String chainId,
  ) async {
    await _log.info(
      'Fetching inbox with cookies',
      chainId: chainId,
      extra: {'jobId': job.id, 'email': job.mail},
    );

    try {
      final inboxMails = await _tenMinuteMailApi.getInbox(
        job.cookieHeader,
        chainId: chainId,
      );

      if (inboxMails.isEmpty) {
        await _log.debug('Inbox is empty', chainId: chainId);
        return null;
      }

      TempMailInboxResponse? couponMail;

      for (final m in inboxMails) {
        if (m.subject == AppConstants.emailSubject ||
            (m.sender != null &&
                m.sender!.contains(AppConstants.emailSender))) {
          couponMail = m;
          break;
        }
      }

      if (couponMail == null) {
        await _log.warning(
          'No coupon email found in inbox',
          chainId: chainId,
          extra: {'messagesCount': inboxMails.length},
        );
        return null;
      }

      if (couponMail.bodyPlainText.isEmpty) {
        await _log.warning('Coupon email body is empty', chainId: chainId);
        return null;
      }

      final match = RegExp(
        r'https://api\.couponcarrier\.io/r/[^\s)]+',
      ).firstMatch(couponMail.bodyPlainText);

      if (match == null) {
        await _log.warning(
          'Coupon URL not found in email body',
          chainId: chainId,
          extra: {'subject': couponMail.subject},
        );
        return null;
      }

      final couponUrl = match.group(0)!;

      final uri = Uri.parse(couponUrl);
      final hsh = uri.queryParameters['hsh'];
      if (hsh == null) {
        await _log.warning(
          'Missing hsh parameter in coupon URL',
          chainId: chainId,
          extra: {'url': couponUrl},
        );
        return null;
      }

      await _log.info(
        'Fetching coupon HTML',
        chainId: chainId,
        extra: {'url': couponUrl},
      );

      final res = await _couponViewApi.getCouponHtml(job.mail, hsh, chainId);

      final htmlStr = res.data as String;
      final doc = html.parse(htmlStr);

      final h3 = doc.querySelector('h3.code-tag');
      if (h3 == null) {
        await _log.warning(
          'Coupon code element not found in HTML',
          chainId: chainId,
          extra: {'url': couponUrl},
        );
        return null;
      }

      final codeText = h3.text.trim();

      await _log.info(
        'Coupon successfully parsed',
        chainId: chainId,
        extra: {'code': codeText},
      );

      return Coupon(
        id: null,
        title: 'Coffee coupon',
        code: codeText,
        createdAt: DateTime.now(),
        used: false,
        link: couponUrl,
      );
    } catch (e, s) {
      final error = UnknownError(
        message: 'Failed to fetch coupon using cookies',
        detail: '_tryFetchCouponWithCookies',
        cause: e,
        stackTrace: s,
      );

      await _log.errorFrom(error, chainId: chainId);

      return null;
    }
  }
}
