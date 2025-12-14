import 'package:coupon_app/api/api_client.dart';
import 'package:coupon_app/api/coupon_view_api.dart';
import 'package:coupon_app/api/generate_coupon_api.dart';
import 'package:coupon_app/core/logs_controller.dart';
import 'package:coupon_app/db/coupon_jobs_repository.dart';
import 'package:coupon_app/db/database.dart';
import 'package:coupon_app/jobs/coupon_jobs_runner.dart';
import 'package:coupon_app/services/background_service.dart';
import 'package:coupon_app/services/coupons_service.dart';
import 'package:coupon_app/services/email_service.dart';
import 'package:coupon_app/ui/available_coupons_screen.dart';
import 'package:coupon_app/ui/get_coupon_screen.dart';
import 'package:coupon_app/ui/logs_screen.dart';
import 'package:coupon_app/ui/settings_screen.dart';
import 'package:coupon_app/ui/used_coupons_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'api/ten_minute_mail_api.dart';
import 'core/coupon_controller.dart';
import 'core/log/logger.dart';
import 'core/log/logs_repository.dart';
import 'core/notification_service.dart';
import 'core/settings_controller.dart';
import 'db/coupons_repository.dart';
import 'db/emails_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher);
  final db = await AppDatabase.instance.database;
  final apiClient = await ApiClient.create();

  final tenMinuteMailApi = TenMinuteMailApi(apiClient);
  final generateCouponApi = GenerateCouponApi(apiClient);
  final couponViewApi = CouponViewApi(apiClient);

  final prefs = await SharedPreferences.getInstance();
  final logsRepo = LogsRepository(db);
  final LogsController logsController = LogsController(logsRepo);
  final settings = SettingsController(prefs);
  AppLogger.init(logsRepo, logsController, enabled: settings.logsEnabled);

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CouponsRepository(db)),
        Provider(create: (_) => CouponJobsRepository(db)),
        Provider(create: (_) => EmailsRepository(db)),
        Provider(create: (_) => CouponJobsRunner()),
        Provider(create: (_) => logsRepo),
        ChangeNotifierProvider(create: (_) => settings),
        ChangeNotifierProvider(
          create: (ctx) =>
              CouponsController(ctx.read<CouponsRepository>())..notifyChanged(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => logsController..notifyChanged(),
        ),
        Provider.value(value: tenMinuteMailApi),
        Provider.value(value: apiClient),
        Provider.value(value: generateCouponApi),
        Provider.value(value: couponViewApi),
        Provider(
          create: (ctx) => EmailService(ctx.read<EmailsRepository>(), settings),
        ),
        Provider(
          create: (ctx) => CouponsService.init(
            tenMinuteMailApi: tenMinuteMailApi,
            generateCouponApi: generateCouponApi,
            couponJobsRepository: ctx.read<CouponJobsRepository>(),
            couponsRepository: ctx.read<CouponsRepository>(),
            couponJobsRunner: ctx.read<CouponJobsRunner>(),
            couponsController: ctx.read<CouponsController>(),
            couponViewApi: couponViewApi,
            emailService: ctx.read<EmailService>(),
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
  MainTab _currentTab = MainTab.available;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final showUsed = settings.showUsedCoupons;
    final showLogs = settings.showLogs;

    final tabs = <MainTab>[
      MainTab.get,
      MainTab.available,
      if (showUsed) MainTab.used,
      if (showLogs) MainTab.logs,
      MainTab.settings,
    ];

    var currentIndex = tabs.indexOf(_currentTab);
    if (currentIndex == -1) {
      _currentTab = MainTab.available;
      currentIndex = tabs.indexOf(_currentTab);
    }

    final pages = tabs.map<Widget>((tab) {
      switch (tab) {
        case MainTab.get:
          return const GetCouponScreen();
        case MainTab.available:
          return const AvailableCouponsScreen();
        case MainTab.used:
          return const UsedCouponsScreen();
        case MainTab.logs:
          return LogsScreen();
        case MainTab.settings:
          return const SettingsScreen();
      }
    }).toList();

    final items = tabs.map<BottomNavigationBarItem>((tab) {
      switch (tab) {
        case MainTab.get:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Get',
          );
        case MainTab.available:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.coffee),
            label: 'Available',
          );
        case MainTab.used:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Used',
          );
        case MainTab.logs:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Logs',
          );
        case MainTab.settings:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          );
      }
    }).toList();

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() {
            _currentTab = tabs[i];
          });
        },
        items: items,
      ),
    );
  }
}

enum MainTab { get, available, used, logs, settings }
