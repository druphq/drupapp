import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../passenger/provider/user_notifier.dart';
import '../../../auth/provider/auth_notifier.dart';

class DriverAccountScreen extends ConsumerWidget {
  const DriverAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final user = userState.user;
    final bool isVerified = false;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        title: Text('Driver Account', style: TextStyles.t1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Image with verification badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withOpacity(0.1),
                          image: user?.profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(user!.profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      // Camera button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Change photo coming soon!'),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Verification badge
                      Positioned(
                        top: 0,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.success
                                : AppColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            isVerified ? Icons.check : Icons.priority_high,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Name
                  Text(
                    user?.fullName ?? 'Guest User',
                    style: TextStyles.t1.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Gap(4),

                  // Rating
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 20, color: AppColors.orange400),
                      const Gap(4),
                      Text(
                        '4.5',
                        style: TextStyles.t1.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '(50 trips)',
                        style: TextStyles.h2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const Gap(8),

                  // Verification status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.pending,
                          size: 16,
                          color: isVerified
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const Gap(6),
                        Text(
                          isVerified
                              ? 'Verified Driver'
                              : 'Pending Verification',
                          style: TextStyles.t2.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Verification Banner (if not verified)
            if (!isVerified)
              GestureDetector(
                onTap: () => context.push(AppRoutes.verifyDriverRoute),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Verification',
                              style: TextStyles.t1.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Verify your identity to start driving',
                              style: TextStyles.t2.copyWith(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

            const Gap(16),

            // Menu Items
            Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () => context.push(AppRoutes.personalInfoRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle Information',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vehicle Information coming soon!'),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Documents coming soon!')),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Bank Details',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bank Details coming soon!'),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'Reviews',
                  onTap: () => context.push(AppRoutes.reviewsRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.privacyPolicyRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _handleLogout(context, ref),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  onTap: () => context.push(AppRoutes.deleteAccountRoute),
                ),
              ],
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: iconColor ?? AppColors.accent),
      title: Text(title, style: TextStyles.h3.copyWith(fontSize: 18)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: textColor ?? AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 70,
      endIndent: 20,
      color: AppColors.divider,
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyles.t2.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.t2.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.loginRoute);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
