import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/user_notifier.dart';
import '../../../auth/provider/auth_notifier.dart';

class DriverAppDrawer extends ConsumerWidget {
  const DriverAppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final userName = userState.user?.displayName ?? 'Guest User';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [Color(0xff253B80), Color(0xff5490D0)],
        //   ),
        // ),
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
                child: Padding(
                  padding: const EdgeInsets.only(top: 100.0),
                  child: Row(
                    children: [
                      // Profile Image Placeholder
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      Gap(14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyles.t1.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 15,
                                color: AppColors.accent,
                              ),
                              Gap(5.0),
                              Text(
                                '4.5',
                                style: TextStyles.t1.copyWith(fontSize: 14),
                              ),
                              Gap(2.0),
                              Text(
                                '(208)',
                                style: TextStyles.t1.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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
                              icon: AppAssets.historyIcon,
                              title: 'Ride History',
                              onTap: () {
                                Navigator.pop(context);
                                _showMessage(
                                  context,
                                  'Ride History - Coming Soon',
                                );
                              },
                            ),
                            _buildDrawerItem(
                              icon: AppAssets.messageIcon,
                              title: 'Messages',
                              onTap: () {
                                Navigator.pop(context);
                                _showMessage(context, 'Messages - Coming Soon');
                              },
                            ),
                            _buildDrawerItem(
                              icon: AppAssets.supportIcon,
                              title: 'Support',
                              onTap: () {
                                Navigator.pop(context);
                                _showMessage(context, 'Support - Coming Soon');
                              },
                            ),
                            _buildDrawerItem(
                              icon: AppAssets.infoIcon,
                              title: 'About',
                              onTap: () {
                                Navigator.pop(context);
                                _showMessage(context, 'About - Coming Soon');
                              },
                            ),
                            _buildDrawerItem(
                              icon: AppAssets.exitIcon,
                              title: 'Logout',
                              onTap: () {
                                Navigator.pop(context);
                                _handleLogout(context, ref);
                              },
                            ),
                            _buildDrawerItem(
                              icon: AppAssets.deleteIcon,
                              title: 'Delete Account',
                              textColor: Colors.red[300],
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteAccountDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: CustomButton(
                          text: 'Passenger Mode',
                          onPressed: () {
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
        width: 24,
        height: 24,
      ),
      title: Text(title, style: TextStyles.h3.copyWith(fontSize: 18)),
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
      ref.read(authNotifierProvider.notifier).signOut();
      _showMessage(context, 'Logged out successfully');
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
