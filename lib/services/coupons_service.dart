import 'package:coupon_app/api/generate_coupon_api.dart';
import 'package:coupon_app/core/constants.dart';
import 'package:coupon_app/db/coupon_jobs_repository.dart';
import 'package:coupon_app/jobs/coupon_jobs_runner.dart';
import 'package:flutter/foundation.dart';
import '../api/ten_minute_mail_api.dart';
import '../db/coupons_repository.dart';
import '../models/coupon.dart';
import '../models/coupon_job.dart';
import '../models/temp_mail_address_response.dart';

class CouponsController extends ChangeNotifier {
  final CouponsRepository _couponsRepository;
  final TenMinuteMailApi _tenMinuteMailApi;
  final GenerateCouponApi _generateCouponApi;
  final CouponJobsRepository _couponJobsRepository;
  final CouponJobsRunner _couponJobsRunner;

  CouponsController(
    this._couponsRepository,
    this._tenMinuteMailApi,
    this._generateCouponApi,
    this._couponJobsRepository,
    this._couponJobsRunner,
  );

  List<Coupon> available = [];
  List<Coupon> used = [];
  bool loading = false;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();

    available = await _couponsRepository.getAvailable();
    used = await _couponsRepository.getUsed();

    loading = false;
    notifyListeners();
  }

  Future<void> requestCoupon() async {
    TempMailAddressResponse address = await _tenMinuteMailApi
        .createNewAddress();
    _startCouponJob(address);
    await loadAll();
  }

  Future<void> markUsed(int id) async {
    await _couponsRepository.markUsed(id);
    await loadAll();
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

    _couponJobsRunner.ensureRunning();
  }
}
