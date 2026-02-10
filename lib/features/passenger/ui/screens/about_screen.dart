import 'package:drup/resources/app_strings.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  // App version - update manually or use package_info_plus later
  final String _appVersion = '1.0.0';
  final String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'About',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo and Info
            const Gap(20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                AppStrings.appNameTxt.substring(0, 1).toUpperCase(),
                style: TextStyles.t1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(16),
            Text(
              AppStrings.appNameTxt,
              style: TextStyles.t1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(4),
            Text(
              'Version $_appVersion (Build $_buildNumber)',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              'Your reliable ride-hailing companion',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(32),

            // About Section
            _buildInfoCard(
              title: 'About Drup',
              content:
                  'Drup is a ride-hailing platform designed to connect passengers '
                  'with reliable drivers across Nigeria. Our mission is to make '
                  'transportation safe, affordable, and convenient for everyone.',
            ),
            const Gap(16),

            // Legal Section
            Text(
              'Legal',
              style: TextStyles.t1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildLinkTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms of Service - Coming soon'),
                  ),
                );
              },
            ),
            _buildLinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy - Coming soon')),
                );
              },
            ),
            _buildLinkTile(
              icon: Icons.gavel_outlined,
              title: 'Licenses',
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: AppStrings.appNameTxt,
                  applicationVersion: _appVersion,
                );
              },
            ),
            const Gap(24),

            // Connect Section
            Text(
              'Connect With Us',
              style: TextStyles.t1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _buildLinkTile(
              icon: Icons.language_outlined,
              title: 'Website',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Website - Coming soon')),
                );
              },
            ),
            _buildLinkTile(
              icon: Icons.star_outline,
              title: 'Rate Us on App Store',
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
              },
            ),
            _buildLinkTile(
              icon: Icons.share_outlined,
              title: 'Share App',
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
              },
            ),
            const Gap(32),

            // Footer
            Text(
              '© ${DateTime.now().year} Drup. All rights reserved.',
              style: TextStyles.t2.copyWith(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            const Gap(4),
            Text(
              'Made with ❤️ in Nigeria',
              style: TextStyles.t2.copyWith(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.t1.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            content,
            style: TextStyles.t2.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        title: Text(
          title,
          style: TextStyles.t1.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
