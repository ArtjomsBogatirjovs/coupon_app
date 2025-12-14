import 'package:coupon_app/core/coupon_controller.dart';
import 'package:coupon_app/core/log/logger.dart';
import 'package:coupon_app/core/log/logs_repository.dart';
import 'package:coupon_app/core/logs_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/coupon_view_api.dart';
import '../api/generate_coupon_api.dart';
import '../api/ten_minute_mail_api.dart';
import '../core/constants.dart';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/settings_controller.dart';
import '../db/coupon_jobs_repository.dart';
import '../db/coupons_repository.dart';
import '../db/database.dart';
import '../db/emails_repository.dart';
import '../jobs/coupon_jobs_runner.dart';
import 'coupons_service.dart';
import 'email_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = await AppDatabase.instance.database;
    final logRepo = LogsRepository(db);

    AppLogger.init(logRepo, LogsController(logRepo));

    final log = AppLogger.instance.getLogger(
      category: LogCategory.background,
      source: 'Workmanager',
    );

    try {
      final chainId = (inputData != null && inputData['chainId'] is String)
          ? inputData['chainId'] as String
          : 'task:$task-${DateTime.now().microsecondsSinceEpoch}';
      await log.info(
        'Background task started',
        chainId: chainId,
        extra: {'task': task},
      );
      if (AppConstants.backgroundProcessCouponJobs == task) {
        WidgetsFlutterBinding.ensureInitialized();

        final apiClient = await ApiClient.create();

        final tenMinuteMailApi = TenMinuteMailApi(apiClient);
        final generateCouponApi = GenerateCouponApi(apiClient);
        final couponViewApi = CouponViewApi(apiClient);

        final jobsRepo = CouponJobsRepository(db);
        final couponsRepo = CouponsRepository(db);
        final emailsRepo = EmailsRepository(db);

        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsController(prefs);
        final emailService = EmailService(emailsRepo, settings);

        final couponsService = CouponsService.init(
          tenMinuteMailApi: tenMinuteMailApi,
          generateCouponApi: generateCouponApi,
          couponJobsRepository: jobsRepo,
          couponsRepository: couponsRepo,
          couponJobsRunner: CouponJobsRunner(),
          couponsController: CouponsController(couponsRepo),
          couponViewApi: couponViewApi,
          emailService: emailService,
        );

        final failed = await couponsService.processPendingJobs(chainId);
        await log.debug(
          'processPendingJobsOnce finished in background',
          chainId: chainId,
          extra: {'failed': failed},
        );
        return Future.value(failed);
      }
      await log.warning(
        'Unknown background task',
        chainId: chainId,
        extra: {'task': task},
      );
      return Future.value(true);
    } catch (e, s) {
      final error = BackgroundTaskError(
        message: 'Background task failed',
        taskName: task,
        cause: e,
        stackTrace: s,
      );

      await log.errorFrom(error, chainId: 'task:$task');

      return Future.value(false);
    }
  });
}
