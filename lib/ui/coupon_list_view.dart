import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/settings_controller.dart';
import '../models/coupon.dart';

class CouponsListView extends StatelessWidget {
  final bool loading;
  final List<Coupon> coupons;
  final String emptyText;
  final bool showMarkUsed;
  final void Function(Coupon coupon)? onMarkUsed;

  const CouponsListView({
    super.key,
    required this.loading,
    required this.coupons,
    required this.emptyText,
    this.showMarkUsed = false,
    this.onMarkUsed,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (coupons.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: coupons.length,
      itemBuilder: (ctx, i) {
        final c = coupons[i];
        return _CouponTile(
          coupon: c,
          showMarkUsed: showMarkUsed,
          onMarkUsed: onMarkUsed,
        );
      },
    );
  }
}

class _CouponTile extends StatelessWidget {
  final Coupon coupon;
  final bool showMarkUsed;
  final void Function(Coupon coupon)? onMarkUsed;

  const _CouponTile({
    required this.coupon,
    required this.showMarkUsed,
    this.onMarkUsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.read<SettingsController>();
    final primary = theme.colorScheme.primary;

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(coupon.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (settings.openOnTap && coupon.link != null) {
              await launchUrl(Uri.parse(coupon.link!));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        coupon.code,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (showMarkUsed && onMarkUsed != null) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Used'),
                    onPressed: () async {
                      final confirmed = await _confirm(context);
                      if (confirmed) {
                        onMarkUsed!(coupon);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Mark coupon as used?'),
              content: const Text('It will be moved to the used coupons list.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
