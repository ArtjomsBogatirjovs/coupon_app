import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/coupon_controller.dart';
import 'coupon_list_view.dart';

class AvailableCouponsScreen extends StatelessWidget {
  const AvailableCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsController>();

    return CouponsListView(
      loading: controller.loading,
      coupons: controller.available,
      emptyText: 'No available coupons',
      showMarkUsed: true,
      onMarkUsed: (c) => controller.markUsed(c.id!),
    );
  }
}
