import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coupons_service.dart';

class AvailableCouponsScreen extends StatefulWidget {
  const AvailableCouponsScreen({super.key});

  @override
  State<AvailableCouponsScreen> createState() => _AvailableCouponsScreenState();
}

class _AvailableCouponsScreenState extends State<AvailableCouponsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<CouponsController>();
      controller.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CouponsController>();

    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.available.isEmpty) {
      return const Center(child: Text('No available coupons'));
    }

    return ListView.builder(
      itemCount: controller.available.length,
      itemBuilder: (ctx, i) {
        final c = controller.available[i];
        return ListTile(
          title: Text(c.title),
          subtitle: Text(c.code),
          trailing: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => controller.markUsed(c.id!),
          ),
        );
      },
    );
  }
}
