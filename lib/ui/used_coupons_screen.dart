import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coupons_service.dart';

class UsedCouponsScreen extends StatelessWidget {
  const UsedCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsController>();

    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.used.isEmpty) {
      return const Center(child: Text('No used coupons'));
    }

    return ListView.builder(
      itemCount: controller.used.length,
      itemBuilder: (ctx, i) {
        final c = controller.used[i];
        return ListTile(title: Text(c.title), subtitle: Text(c.code));
      },
    );
  }
}
