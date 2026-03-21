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
import '../../provider/driver_notifier.dart';

class DriverAppDrawer extends ConsumerWidget {
  const DriverAppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final user = userState.user;
    final userName = (user?.fullName.takeFirst) ?? 'Guest User';
    final driverState = ref.watch(driverNotifierProvider);
    final bool isVerified = driverState.driver?.isActive ?? false;

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
                  Stack(
                    children: [
                      ///////////////
                      Padding(
                        padding: const EdgeInsets.only(top: 70),
                        child: GestureDetector(
                          onTap: isVerified
                              ? () {
                                  Navigator.pop(context);
                                  context.push(AppRoutes.driverAccountRoute);
                                }
                              : null,
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

                      // Subtle overlay when not verified
                      if (!isVerified)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: 16.0, left: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pending-verification banner
                                if (!isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 24,
                                      bottom: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.warning.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 18,
                                            color: AppColors.warning,
                                          ),
                                          const Gap(10),
                                          Expanded(
                                            child: Text(
                                              'Your account is pending verification. '
                                              'Features will unlock once approved.',
                                              style: TextStyles.t2.copyWith(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: [
                                      _buildDrawerItem(
                                        icon: AppAssets.scheduleIcon,
                                        title: 'Ride Requests',
                                        enabled: isVerified,
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
                                        enabled: isVerified,
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
                                        enabled: isVerified,
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push(AppRoutes.messagesRoute);
                                        },
                                      ),
                                      _buildDrawerItem(
                                        icon: AppAssets.supportIcon,
                                        title: 'Support',
                                        enabled: isVerified,
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push(AppRoutes.supportRoute);
                                        },
                                      ),
                                      _buildDrawerItem(
                                        icon: AppAssets.infoIcon,
                                        title: 'About',
                                        enabled: isVerified,
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push(AppRoutes.aboutRoute);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Subtle overlay when not verified
                          if (!isVerified)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color: Colors.white10.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                        ],
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
    bool enabled = true,
    Color? color,
  }) {
    final effectiveColor = enabled
        ? (color ?? AppColors.accent)
        : AppColors.textSecondary.withValues(alpha: 0.8);
    final textColor = enabled
        ? (color ?? AppColors.accent)
        : AppColors.textSecondary.withValues(alpha: 0.8);

    return ListTile(
      leading: ImageIcon(AssetImage(icon), color: effectiveColor, size: 18),
      title: Text(
        title,
        style: TextStyles.h3.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
      onTap: onTap,
    );
  }
}
