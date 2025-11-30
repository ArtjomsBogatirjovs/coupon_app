import 'package:coupon_app/ui/available_coupons_screen.dart';
import 'package:coupon_app/ui/get_coupon_screen.dart';
import 'package:coupon_app/ui/used_coupons_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/coupons_repository.dart';
import 'state/coupons_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CouponsRepository()),
        ChangeNotifierProvider(
          create: (ctx) =>
          CouponsController(ctx.read<CouponsRepository>())..loadAll(),
        ),
      ],
      child: const CouponsApp(),
    ),
  );
}

class CouponsApp extends StatelessWidget {
  const CouponsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const GetCouponScreen(),
      const AvailableCouponsScreen(),
      const UsedCouponsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Get a coupon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Used',
          ),
        ],
      ),
    );
  }
}
