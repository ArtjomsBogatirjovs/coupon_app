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
import 'package:shared_preferences/shared_preferences.dart';
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

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CouponsRepository(db)),
        Provider(create: (_) => CouponJobsRepository(db)),
        Provider(create: (_) => CouponJobsRunner()),
        ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
        ChangeNotifierProvider(
          create: (ctx) =>
              CouponsController(ctx.read<CouponsRepository>())..notifyChanged(),
        ),
        Provider.value(value: tenMinuteMailApi),
        Provider.value(value: apiClient),
        Provider.value(value: generateCouponApi),
        Provider.value(value: couponViewApi),
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
    final settings = context.watch<SettingsController>();
    final showUsed = settings.showUsedCoupons;

    final effectiveIndex = _effectiveIndexFromLogical(_index, showUsed);

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Get'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.coffee),
        label: 'Available',
      ),
      if (showUsed)
        const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Used'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: _buildBody(showUsed),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: effectiveIndex,
        onTap: (i) {
          final logical = _logicalIndexFromEffective(i, showUsed);
          setState(() {
            _index = logical;
          });
        },
        items: items,
      ),
    );
  }

  Widget _buildBody(bool showUsed) {
    switch (_index) {
      case 0:
        return const GetCouponScreen();
      case 1:
        return const AvailableCouponsScreen();
      case 2:
        if (showUsed) {
          return const UsedCouponsScreen();
        }
        return const AvailableCouponsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const GetCouponScreen();
    }
  }

  int _effectiveIndexFromLogical(int logical, bool showUsed) {
    if (showUsed) {
      if (logical < 0 || logical > 3) return 0;
      return logical;
    } else {
      switch (logical) {
        case 0:
          return 0;
        case 1:
          return 1;
        case 2:
          return 1;
        case 3:
          return 2;
        default:
          return 0;
      }
    }
  }

  int _logicalIndexFromEffective(int effective, bool showUsed) {
    if (showUsed) {
      return effective;
    } else {
      switch (effective) {
        case 0:
          return 0;
        case 1:
          return 1;
        case 2:
          return 3;
        default:
          return 0;
      }
    }
  }
}
