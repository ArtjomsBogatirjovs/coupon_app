import 'package:flutter/cupertino.dart';
import '../db/coupons_repository.dart';
import '../models/coupon.dart';

class CouponsController extends ChangeNotifier {
  final CouponsRepository _couponsRepository;

  CouponsController(this._couponsRepository);

  List<Coupon> available = [];
  List<Coupon> used = [];
  bool loading = false;

  Future<void> notifyChanged() async {
    loading = true;
    notifyListeners();

    available = await _couponsRepository.getAvailable();
    used = await _couponsRepository.getUsed();

    loading = false;
    notifyListeners();
  }

  Future<void> markUsed(int id) async {
    await _couponsRepository.markUsed(id);
    await notifyChanged();
  }
}
