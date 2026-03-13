import 'package:drup/di/notifiers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/router/app_router.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/provider/auth_notifier.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final user = userState.user;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        title: Text('My Account', style: TextStyles.t1),
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
                  // Profile Image
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
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
                                size: 35,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
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
                    ],
                  ),
                  const Gap(16),

                  // Name
                  Text(
                    user?.fullName ?? 'Guest User',
                    style: TextStyles.t1.copyWith(
                      fontSize: 24,
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
                        '4.5',
                        style: TextStyles.h2.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Rating',
                        style: TextStyles.t2.copyWith(fontSize: FontSizes.s14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Menu Items
            Column(
              children: [
                _buildMenuItem(
                  iconImage: AppAssets.personIcon,
                  title: 'Personal Info',
                  onTap: () => context.push(AppRoutes.personalInfoRoute),
                ),
                _buildDivider(),
                _buildMenuItem(
                  iconImage: AppAssets.privacyIcon,
                  title: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.privacyPolicyRoute),
                ),

                _buildDivider(),

                _buildMenuItem(
                  iconImage: AppAssets.exitIcon,
                  title: 'Logout',
                  onTap: () => _handleLogout(
                    context,
                    ref.read(authNotifierProvider.notifier),
                  ),
                ),

                _buildDivider(),

                _buildMenuItem(
                  iconImage: AppAssets.deleteIcon,
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
    required String iconImage,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: ImageIcon(
        AssetImage(iconImage),
        color: iconColor ?? AppColors.accent,
        size: 18,
      ),
      title: Text(title, style: TextStyles.h3.copyWith(fontSize: 16)),
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

  void _handleLogout(BuildContext context, AuthNotifier authNotifier) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyles.t3.copyWith(
            fontSize: FontSizes.s20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyles.h3.copyWith(
            fontSize: FontSizes.s14,
            color: AppColors.surface500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s16,
                color: AppColors.accent,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Logout',
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s16,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );

    // Check if user confirmed logout
    if (shouldLogout == true) {
      // Perform logout using the captured notifier
      authNotifier.logout();

      // Use root navigator context for navigation
      final navigatorContext = rootNavigator.currentContext;
      if (navigatorContext != null && navigatorContext.mounted) {
        // Navigate to login screen
        Navigator.popUntil(navigatorContext, (route) => route.isFirst);
      }
    }
  }
}
