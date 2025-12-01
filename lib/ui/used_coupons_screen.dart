import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/coupon_controller.dart';
import 'coupon_list_view.dart';

class UsedCouponsScreen extends StatelessWidget {
  const UsedCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsController>();

    return CouponsListView(
      loading: controller.loading,
      coupons: controller.used,
      emptyText: 'No used coupons',
      showMarkUsed: false,
    );
  }
}
