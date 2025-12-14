import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'coupon_channel',
    'Coupons',
    description: 'Notifications about generated coupons',
    importance: Importance.high,
  );

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('app_icon_no_background');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (Platform.isAndroid && androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.createNotificationChannel(_channel);
    }
  }

  static Future<void> showCouponGenerated(String code) async {
    await _plugin.show(
      1,
      'Coffee coupon ready',
      'Your new coupon: $code',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'app_icon_no_background',
          largeIcon: const DrawableResourceAndroidBitmap(
            'app_icon_no_background',
          ),
        ),
      ),
    );
  }
}
