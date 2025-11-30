import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/coupons_controller.dart';

class GetCouponScreen extends StatelessWidget {
  const GetCouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsController>();

    return Center(
      child: ElevatedButton(
        onPressed: () {
          controller.addCoupon(
            'Test coupon',
            'CODE-${DateTime.now().millisecondsSinceEpoch}',
          );
        },
        child: const Text('Get Coupon'),
      ),
    );
  }
}
