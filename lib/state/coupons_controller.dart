import 'package:flutter/foundation.dart';
import '../data/coupons_repository.dart';
import '../models/coupon.dart';

class CouponsController extends ChangeNotifier {
  final CouponsRepository _repo;

  CouponsController(this._repo);

  List<Coupon> available = [];
  List<Coupon> used = [];
  bool loading = false;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();

    available = await _repo.getAvailable();
    used = await _repo.getUsed();

    loading = false;
    notifyListeners();
  }

  Future<void> addCoupon(String title, String code) async {
    await _repo.insert(
      Coupon(
        title: title,
        code: code,
        createdAt: DateTime.now(),
        used: false,
      ),
    );
    await loadAll();
  }

  Future<void> markUsed(int id) async {
    await _repo.markUsed(id);
    await loadAll();
  }
}
