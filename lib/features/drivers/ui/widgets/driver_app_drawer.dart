import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/provider/auth_notifier.dart';

class DriverAppDrawer extends ConsumerWidget {
  const DriverAppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final user = userState.user;
    final userName = (user?.fullName.takeFirst) ?? 'Guest User';
    final bool isVerified = false;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Drawer Header
            Container(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Driver Profile Section
                  Padding(
                    padding: const EdgeInsets.only(top: 70),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.driverAccountRoute);
                      },
                      child: Row(
                        children: [
                          // Profile Image with status indicator
                          Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  image: user?.profileImage != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            user!.profileImage!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: user?.profileImage == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 28,
                                        color: AppColors.accent,
                                      )
                                    : null,
                              ),
                              // Online/Verification indicator
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? AppColors.success
                                        : AppColors.warning,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    isVerified
                                        ? Icons.verified
                                        : Icons.priority_high,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyles.t1.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Gap(2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: AppColors.orange400,
                                    ),
                                    const Gap(4),
                                    Text(
                                      '0.0',
                                      style: TextStyles.t1.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      '(0 trip)',
                                      style: TextStyles.t2.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Verification Status Banner
                  // if (!isVerified)
                  //   GestureDetector(
                  //     onTap: () {
                  //       Navigator.pop(context);
                  //       context.push(AppRoutes.verifyDriverRoute);
                  //     },
                  //     child: Container(
                  //       margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  //       padding: const EdgeInsets.all(16),
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(12),
                  //         border: Border.all(
                  //           color: AppColors.warning.withOpacity(0.3),
                  //           width: 1,
                  //         ),
                  //       ),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Row(
                  //             children: [
                  //               Container(
                  //                 padding: const EdgeInsets.all(8),
                  //                 decoration: BoxDecoration(
                  //                   color: AppColors.warning,
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //                 child: const Icon(
                  //                   Icons.warning_amber_rounded,
                  //                   size: 20,
                  //                   color: Colors.white,
                  //                 ),
                  //               ),
                  //               const Gap(12),
                  //               Expanded(
                  //                 child: Column(
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   children: [
                  //                     Text(
                  //                       'Complete your profile',
                  //                       style: TextStyles.t1.copyWith(
                  //                         fontSize: 14,
                  //                         fontWeight: FontWeight.w600,
                  //                         color: AppColors.textPrimary,
                  //                       ),
                  //                     ),
                  //                     const Gap(2),
                  //                     Text(
                  //                       'Verify to start accepting rides',
                  //                       style: TextStyles.t2.copyWith(
                  //                         fontSize: 12,
                  //                         color: AppColors.textSecondary,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //               Icon(
                  //                 Icons.arrow_forward_ios,
                  //                 size: 14,
                  //                 color: AppColors.warning,
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),

                  // Verified badge (shown when verified)
                  // if (isVerified)
                  // Container(
                  //   margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 12,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.success.withOpacity(0.1),
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(
                  //       color: AppColors.success.withOpacity(0.3),
                  //       width: 1,
                  //     ),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: Text(
                  //           'Verified Driver',
                  //           style: TextStyles.t1.copyWith(
                  //             fontSize: 14,
                  //             fontWeight: FontWeight.w600,
                  //             color: AppColors.success,
                  //           ),
                  //         ),
                  //       ),
                  //       const Icon(
                  //         Icons.verified,
                  //         size: 16,
                  //         color: Colors.green,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            const Gap(10.0),
            // Menu Items
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15.0),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(top: 16.0, left: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildDrawerItem(
                                    icon: AppAssets.scheduleIcon,
                                    title: 'Ride Requests',
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.push(
                                        AppRoutes.driverRideRequestsRoute,
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: AppAssets.historyIcon,
                                    title: 'Ride History',
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.push(
                                        AppRoutes.driverRideHistoryRoute,
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: AppAssets.messageIcon,
                                    title: 'Messages',
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showMessage(
                                        context,
                                        'Messages - Coming Soon',
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: AppAssets.supportIcon,
                                    title: 'Support',
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showMessage(
                                        context,
                                        'Support - Coming Soon',
                                      );
                                    },
                                  ),
                                  _buildDrawerItem(
                                    icon: AppAssets.infoIcon,
                                    title: 'About',
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showMessage(
                                        context,
                                        'About - Coming Soon',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: CustomButton(
                        text: 'Passenger Mode',
                        onPressed: () {
                          final userRepo = ref.read(userRepositoryProvider);
                          userRepo.storeUserMode(AppStrings.passengerMode);

                          context.go(AppRoutes.homeRoute);
                        },
                      ),
                    ),
                    Gap(50.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: ImageIcon(
        AssetImage(icon),
        color: textColor ?? AppColors.accent,
        size: 18,
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

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Perform logout
      ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        _showMessage(context, 'Logged out successfully');
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage(context, 'Delete Account - Coming Soon');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
