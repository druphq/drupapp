import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Privacy Policy',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      size: 40,
                      color: AppColors.accent,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Your Privacy Matters',
                    style: TextStyles.t1.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Last updated: February 2026',
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Policy Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildPolicyCard(
                    icon: Icons.info_outline,
                    title: 'Information We Collect',
                    content:
                        'We collect information you provide directly to us, such as '
                        'when you create an account, request a ride, or contact us '
                        'for support. This may include:\n\n'
                        '• Your name, email address, and phone number\n'
                        '• Payment information\n'
                        '• Location data when you use our services\n'
                        '• Device information and usage data',
                  ),
                  _buildPolicyCard(
                    icon: Icons.settings_outlined,
                    title: 'How We Use Your Information',
                    content:
                        'We use the information we collect to:\n\n'
                        '• Provide, maintain, and improve our services\n'
                        '• Process transactions and send related information\n'
                        '• Send technical notices, updates, and support messages\n'
                        '• Respond to your comments, questions, and requests\n'
                        '• Monitor and analyze trends, usage, and activities',
                  ),
                  _buildPolicyCard(
                    icon: Icons.share_outlined,
                    title: 'Information Sharing',
                    content:
                        'We may share your information in the following circumstances:\n\n'
                        '• With drivers to facilitate your ride\n'
                        '• With third-party service providers who perform services on our behalf\n'
                        '• When required by law or to protect our rights\n'
                        '• In connection with a merger, acquisition, or sale of assets',
                  ),
                  _buildPolicyCard(
                    icon: Icons.security_outlined,
                    title: 'Data Security',
                    content:
                        'We implement appropriate technical and organizational measures '
                        'to protect your personal information against unauthorized '
                        'access, alteration, disclosure, or destruction. These measures include:\n\n'
                        '• Encryption of data in transit and at rest\n'
                        '• Regular security assessments\n'
                        '• Access controls and authentication',
                  ),
                  _buildPolicyCard(
                    icon: Icons.storage_outlined,
                    title: 'Data Retention',
                    content:
                        'We retain your personal information for as long as necessary to '
                        'fulfill the purposes for which it was collected, including to '
                        'satisfy any legal, accounting, or reporting requirements.\n\n'
                        'When you delete your account, we will delete or anonymize your '
                        'personal information within 30 days, unless we need to retain '
                        'it for legal purposes.',
                  ),
                  _buildPolicyCard(
                    icon: Icons.gavel_outlined,
                    title: 'Your Rights',
                    content:
                        'Depending on your location, you may have certain rights regarding '
                        'your personal information:\n\n'
                        '• Access your personal information\n'
                        '• Correct inaccurate information\n'
                        '• Delete your personal information\n'
                        '• Opt out of certain data collection\n'
                        '• Data portability',
                  ),
                  _buildPolicyCard(
                    icon: Icons.cookie_outlined,
                    title: 'Cookies & Tracking',
                    content:
                        'We use cookies and similar tracking technologies to collect '
                        'information about your browsing activities. You can control '
                        'cookies through your browser settings and other tools.\n\n'
                        'We also use analytics services to help us understand how '
                        'users interact with our services.',
                  ),
                  _buildPolicyCard(
                    icon: Icons.child_care_outlined,
                    title: "Children's Privacy",
                    content:
                        'Our services are not intended for children under 18 years of age. '
                        'We do not knowingly collect personal information from children. '
                        'If we learn that we have collected personal information from a '
                        'child, we will take steps to delete that information.',
                  ),
                  _buildPolicyCard(
                    icon: Icons.update_outlined,
                    title: 'Policy Updates',
                    content:
                        'We may update this Privacy Policy from time to time. We will '
                        'notify you of any changes by posting the new policy on this '
                        'page and updating the "Last updated" date.\n\n'
                        'We encourage you to review this policy periodically for any changes.',
                  ),
                  _buildPolicyCard(
                    icon: Icons.contact_mail_outlined,
                    title: 'Contact Us',
                    content:
                        'If you have any questions about this Privacy Policy or our '
                        'privacy practices, please contact us at:\n\n'
                        'Email: privacy@drup.com\n'
                        'Phone: +234 800 000 0000\n'
                        'Address: Lagos, Nigeria',
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          title: Text(
            title,
            style: TextStyles.t1.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              content,
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
