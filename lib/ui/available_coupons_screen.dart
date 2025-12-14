import 'package:coupon_app/services/coupons_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/coupon_controller.dart';
import 'coupon_list_view.dart';

class AvailableCouponsScreen extends StatefulWidget {
  const AvailableCouponsScreen({super.key});

  @override
  State<AvailableCouponsScreen> createState() => _AvailableCouponsScreenState();
}

class _AvailableCouponsScreenState extends State<AvailableCouponsScreen>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponsController>().notifyChanged();
    });
  }

  @override
  void didPopNext() {
    context.read<CouponsController>().notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsController>();
    final service = context.read<CouponsService>();

    return SafeArea(
      child: CouponsListView(
        loading: controller.loading,
        coupons: controller.available,
        emptyText: 'No available coupons',
        showMarkUsed: true,
        onMarkUsed: (c) => service.markUsed(c.id!),
      ),
    );
  }
}
