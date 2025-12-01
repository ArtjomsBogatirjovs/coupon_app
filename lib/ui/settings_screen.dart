import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Coupons',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Open coupon when tapped'),
            value: settings.openOnTap,
            onChanged: settings.setOpenOnTap,
          ),
          SwitchListTile(
            title: const Text('Show used coupons'),
            value: settings.showUsedCoupons,
            onChanged: settings.setShowUsedCoupons,
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark theme'),
            value: settings.darkTheme,
            onChanged: settings.setDarkTheme,
          ),

          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Other',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: const Text('About app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
