import 'package:coupon_app/services/coupons_service.dart';
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
          SwitchListTile(
            title: const Text('Infinite coupons for Gmail'),
            subtitle: const Text(
              'Allows generating unlimited coupons using Gmail.',
            ),
            value: settings.infiniteGmail,
            onChanged: settings.setInfiniteGmail,
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Data',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            title: const Text('Delete all available coupons'),
            subtitle: const Text('This will remove all unused coupons.'),
            trailing: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => _confirmDeleteAvailable(context),
              child: const Text('Delete'),
            ),
          ),

          ListTile(
            title: const Text('Delete all used coupons'),
            subtitle: const Text('This will clear your used coupons history.'),
            trailing: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _confirmDeleteUsed(context),
              child: const Text('Delete'),
            ),
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

  Future<void> _confirmDeleteAvailable(BuildContext context) async {
    final service = context.read<CouponsService>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Delete all available coupons?'),
              content: const Text('They will be permanently removed.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await service.deleteAllAvailable();
    messenger.showSnackBar(
      const SnackBar(content: Text('Available coupons deleted')),
    );
  }

  Future<void> _confirmDeleteUsed(BuildContext context) async {
    final service = context.read<CouponsService>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Delete all used coupons?'),
              content: const Text('This will clear your used coupons history.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await service.deleteAllUsed();
    messenger.showSnackBar(
      const SnackBar(content: Text('Used coupons deleted')),
    );
  }
}
