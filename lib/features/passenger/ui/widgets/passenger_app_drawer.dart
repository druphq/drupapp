import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:drup/utils/extension.dart';

class PassengerAppDrawer extends ConsumerWidget {
  const PassengerAppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final userName = (userState.user?.fullName.takeFirst) ?? 'Guest User';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Profile Header
            Container(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 70, right: 24),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to profile screen
                        context.push(AppRoutes.accountRoute);
                      },
                      child: Row(
                        children: [
                          // Profile Image Placeholder
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: AppColors.grey,
                            ),
                          ),
                          Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyles.t1.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'My Account',
                                  style: TextStyles.t1.copyWith(
                                    fontSize: FontSizes.s14,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Gap(16.0),

                  Row(
                    children: [
                      Icon(Icons.star, size: 20, color: AppColors.accent),
                      Gap(4.0),
                      Text(
                        '4.5',
                        style: TextStyles.t1.copyWith(fontSize: FontSizes.s16),
                      ),
                      Gap(4.0),
                      Text(
                        'Rating',
                        style: TextStyles.t1.copyWith(fontSize: FontSizes.s14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap(10.0),
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
                padding: EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildDrawerItem(
                            icon: AppAssets.scheduleIcon,
                            title: 'My Rides',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(AppRoutes.rideHistoryRoute);
                            },
                          ),
                          _buildDrawerItem(
                            icon: AppAssets.messageIcon,
                            title: 'Messages',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(AppRoutes.messagesRoute);
                            },
                          ),

                          _buildDrawerItem(
                            icon: AppAssets.walletIcon,
                            title: 'Payments',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(AppRoutes.paymentsRoute);
                            },
                          ),

                          _buildDrawerItem(
                            icon: AppAssets.supportIcon,
                            title: 'Support',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(AppRoutes.supportRoute);
                            },
                          ),
                          _buildDrawerItem(
                            icon: AppAssets.infoIcon,
                            title: 'About',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(AppRoutes.aboutRoute);
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: CustomButton(
                        text: 'Driver Mode',
                        onPressed: () {
                          final userRepo = ref.read(userRepositoryProvider);
                          userRepo.storeUserMode(AppStrings.driverMode);

                          context.go(AppRoutes.splashRoute);
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
      leading: Image.asset(
        icon,
        color: textColor ?? AppColors.accent,
        width: 18,
        height: 18,
      ),
      title: Text(
        title,
        style: TextStyles.t2.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }

  // void _showDeleteAccountDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Delete Account'),
  //       content: const Text(
  //         'Are you sure you want to delete your account? This action cannot be undone.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           style: TextButton.styleFrom(foregroundColor: Colors.red),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
