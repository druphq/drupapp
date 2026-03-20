import 'package:drup/di/notifiers.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/provider/auth_notifier.dart';

class DriverAccountScreen extends ConsumerStatefulWidget {
  const DriverAccountScreen({super.key});

  @override
  ConsumerState<DriverAccountScreen> createState() =>
      _DriverAccountScreenState();
}

class _DriverAccountScreenState extends ConsumerState<DriverAccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverNotifierProvider.notifier).loadDriverProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final user = userState.user;
    final driverState = ref.watch(driverNotifierProvider);
    final driver = driverState.driver;

    final rating = driver?.rating.average ?? 0.0;
    final totalTrips = driver?.stats.completedRides ?? 0;
    final profilePhoto = driver?.profilePhoto ?? user?.profileImage;

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
                          color: AppColors.accent.withValues(alpha: 0.1),
                          image: profilePhoto != null
                              ? DecorationImage(
                                  image: NetworkImage(profilePhoto),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profilePhoto == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      // Verification badge
                      if (driver?.isActive == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.verified,
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
                    driver?.fullName ?? user?.fullName ?? 'Guest User',
                    style: TextStyles.t1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Gap(4),

                  // Rating
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 20, color: AppColors.accent),
                      const Gap(4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyles.t1.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '($totalTrips trips)',
                        style: TextStyles.h2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const Gap(8),
                ],
              ),
            ),

            const Gap(16),

            // Menu Items
            Column(
              children: [
                _buildMenuItem(
                  icon: AppAssets.personIcon,
                  title: 'Personal Info',
                  onTap: () => context.push(AppRoutes.personalInfoRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: AppAssets.vehicleIcon,
                  title: 'Vehicle Info',
                  onTap: () => context.push(AppRoutes.vehicleInfoRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: AppAssets.fileIcon,
                  title: 'Documents',
                  onTap: () => context.push(AppRoutes.documentsRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: AppAssets.bankIcon,
                  title: 'Bank Details',
                  onTap: () => context.push(AppRoutes.bankDetailRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: AppAssets.privacyIcon,
                  title: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.privacyPolicyRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: AppAssets.exitIcon,
                  title: 'Logout',
                  onTap: () => _handleLogout(context, ref),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: AppAssets.deleteIcon,
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
    required String icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: ImageIcon(
        AssetImage(icon),
        color: iconColor ?? AppColors.accent,
        size: 18.0,
      ),
      title: Text(
        title,
        style: TextStyles.h3.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 20,
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
