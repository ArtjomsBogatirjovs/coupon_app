import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coupons_service.dart';

class GetCouponScreen extends StatelessWidget {
  const GetCouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsService>();

    return Center(
      child: ElevatedButton(
        onPressed: () {
          controller.requestCoupon();
        },
        child: const Text('Get Coupon'),
      ),
    );
  }
}
