import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/settings_controller.dart';
import '../services/coupons_service.dart';

class GetCouponScreen extends StatefulWidget {
  const GetCouponScreen({super.key});

  @override
  State<GetCouponScreen> createState() => _GetCouponScreenState();
}

class _GetCouponScreenState extends State<GetCouponScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    final saved = settings.savedEmail;
    if (settings.rememberEmail && saved != null && saved.isNotEmpty) {
      _emailController.text = saved;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => EmailValidator.validate(email);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final settings = context.watch<SettingsController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Get coupon into the app',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'App will create a coupon and save it in “Available” automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildGenerateCard(theme, primary),

              const SizedBox(height: 32),

              Text('Send coupon to e-mail', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildInfoRow(theme),
              const SizedBox(height: 12),
              _buildEmailCard(theme, primary, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateCard(ThemeData theme, Color primary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  child: Icon(Icons.coffee, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Generate coffee coupon',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final service = context.read<CouponsService>();
                service.requestCoupon();
              },
              child: const Text('Generate coupon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'We will send the coupon directly to the address you provide.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _showHowItWorksDialog(context),
          child: const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 20, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailCard(
    ThemeData theme,
    Color primary,
    SettingsController settings,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: settings.rememberEmail,
                  onChanged: (v) {
                    if (v == null) return;
                    settings.setRememberEmail(v);
                    if (v) {
                      settings.setSavedEmail(_emailController.text.trim());
                    } else {
                      settings.setSavedEmail(null);
                    }
                  },
                ),
                const Text('Remember e-mail'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.send),
                label: _sending
                    ? const Text('Sending...')
                    : const Text('Send coupon'),
                onPressed: _sending ? null : () => _onSendPressed(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return const AlertDialog(
          title: Text('How it works'),
          content: Text(
            'We will send the coupon to the e-mail address you enter. '
            'Normally, one e-mail address can receive only one coupon. '
            'However, if you use a Gmail address, you can enable the '
            '“Infinite coupons for Gmail” option in Settings. '
            'With this option, a single Gmail account can generate unlimited coupons',
          ),
        );
      },
    );
  }

  Future<void> _onSendPressed(BuildContext context) async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<CouponsService>();
    final settings = context.read<SettingsController>();

    if (!_isValidEmail(email)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid e-mail address')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await service.sendCouponToEmail(email);
      if (result.warningText != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.warningText!),
            backgroundColor: Colors.orange,
          ),
        );
      }
      if (settings.rememberEmail) {
        await settings.setSavedEmail(email);
      }

      messenger.showSnackBar(SnackBar(content: Text('Coupon sent to $email')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send coupon: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }
}
