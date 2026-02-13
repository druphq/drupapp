import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Support',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyles.t1.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          "We're here to assist you 24/7",
                          style: TextStyles.t2.copyWith(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: TextStyles.t1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildFAQItem(
              context,
              'How do I book a ride?',
              'Enter your pickup and destination locations on the home screen, '
                  'select your preferred vehicle type, and confirm your booking.',
            ),

            _buildDivider(),

            _buildFAQItem(
              context,
              'How do I cancel a ride?',
              'You can cancel a ride from the ride status screen. '
                  'Note that cancellation fees may apply depending on the timing.',
            ),

            _buildDivider(),

            _buildFAQItem(
              context,
              'What payment methods are accepted?',
              'We currently accept cash payments. Card payments and mobile wallets '
                  'are coming soon.',
            ),

            _buildDivider(),

            _buildFAQItem(
              context,
              'How do I become a driver?',
              'Switch to driver mode from the menu drawer and complete the '
                  'registration process. You will need valid documents.',
            ),
            const Gap(24),

            // Contact Options
            Text(
              'Contact Us',
              style: TextStyles.t1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildContactTile(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@drup.com',
              onTap: () {
                Clipboard.setData(
                  const ClipboardData(text: 'support@drup.com'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copied to clipboard')),
                );
              },
            ),

            _buildDivider(),

            _buildContactTile(
              context: context,
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+234 800 000 0000',
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '+2348000000000'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied to clipboard'),
                  ),
                );
              },
            ),

            const Gap(24),

            // Social Media
            Text(
              'Follow Us',
              style: TextStyles.t1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildSocialButton(Icons.facebook, () {}),
                const Gap(16),
                _buildSocialButton(Icons.camera_alt_outlined, () {}),
                const Gap(16),
                _buildSocialButton(Icons.close, () {}), // X (Twitter)
              ],
            ),
            Gap(30.0),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
       
      title: Text(
        question,
        style: TextStyles.t2.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Text(
          answer,
          style: TextStyles.t2.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        title,
        style: TextStyles.t1.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyles.t2.copyWith(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.accent, size: 24),
      ),
    );
  }
}
