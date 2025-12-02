import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About app')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/app_icon_no_background.png',
                  width: 90,
                  height: 90,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Coffee Donor helps you quickly generate a Narvesen coffee coupon after donating blood in Latvia.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 26),

            _infoCard(
              icon: Icons.favorite,
              title: 'Purpose',
              text:
                  'Created as a personal tool to save time after donation and avoid filling the coupon form manually.',
            ),

            const SizedBox(height: 16),

            _infoCard(
              icon: Icons.lock,
              title: 'Privacy',
              text:
                  'No data is shared. Everything stays on your device locally.',
            ),

            const SizedBox(height: 16),

            _infoCard(
              icon: Icons.info_outline,
              title: 'Disclaimer',
              text:
                  'This project is not affiliated with Narvesen or donor centers. Personal pet project for Flutter/Dart practice. Use at your own risk.',
            ),

            const SizedBox(height: 32),

            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.brown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
