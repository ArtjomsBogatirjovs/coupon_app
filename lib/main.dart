import 'package:coupon_app/api/api_client.dart';
import 'package:coupon_app/api/coupon_view_api.dart';
import 'package:coupon_app/api/generate_coupon_api.dart';
import 'package:coupon_app/db/coupon_jobs_repository.dart';
import 'package:coupon_app/db/database.dart';
import 'package:coupon_app/jobs/coupon_jobs_runner.dart';
import 'package:coupon_app/services/coupons_service.dart';
import 'package:coupon_app/ui/available_coupons_screen.dart';
import 'package:coupon_app/ui/get_coupon_screen.dart';
import 'package:coupon_app/ui/settings_screen.dart';
import 'package:coupon_app/ui/used_coupons_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/ten_minute_mail_api.dart';
import 'core/coupon_controller.dart';
import 'core/settings_controller.dart';
import 'db/coupons_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.instance.database;

  final apiClient = await ApiClient.create();
  final tenMinuteMailApi = TenMinuteMailApi(apiClient);
  final generateCouponApi = GenerateCouponApi(apiClient);
  final couponViewApi = CouponViewApi(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: tenMinuteMailApi),
        Provider.value(value: apiClient),
        Provider.value(value: generateCouponApi),
        Provider.value(value: couponViewApi),

        Provider(create: (_) => CouponsRepository(db)),
        Provider(create: (_) => CouponJobsRepository(db)),
        Provider(create: (_) => CouponJobsRunner()),
        ChangeNotifierProvider(
          create: (ctx) =>
              CouponsController(ctx.read<CouponsRepository>())..notifyChanged(),
        ),
        Provider(
          create: (ctx) => CouponsService(
            tenMinuteMailApi,
            generateCouponApi,
            ctx.read<CouponJobsRepository>(),
            ctx.read<CouponJobsRunner>(),
            ctx.read<CouponsController>(),
            ctx.read<CouponsRepository>(),
            couponViewApi,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SettingsController()),
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
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Coupons')),
      body: tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Get'),
          BottomNavigationBarItem(icon: Icon(Icons.coffee), label: 'Available'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Used'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
