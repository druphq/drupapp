import 'package:drup/core/animation/drup_animation.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_notifier.dart';
import '../../passenger/provider/user_notifier.dart';
import '../../../theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);
    final isLoggedIn = ref.read(isLoggedInProvider);
    final isDriver = ref.read(isDriverProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final userMode = await userRepo.getUserMode();

    // Check if user is logged in
    if (isLoggedIn && currentUser != null) {
      // Initialize user data
      await ref.read(userNotifierProvider.notifier).loadUserProfile();

      // Re-read user after loadUserProfile to get updated data
      final updatedUser = ref.read(currentUserProvider);

      // Navigate to appropriate screen
      if (mounted) {
        if (updatedUser?.isEmailVerified == false ||
            updatedUser?.isPhoneVerified == false) {
          context.go(AppRoutes.completeProfileRoute);
          return;
        }

        if (userMode == AppStrings.driverMode || isDriver) {
          context.go(AppRoutes.driverHomeRoute);
        } else {
          context.go(AppRoutes.homeRoute);
        }
      }
    } else {
      // Navigate to login
      if (mounted) {
        context.go(AppRoutes.loginRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.splashBg),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [DrupLogoAnimation()],
            ),
          ),
        ),
      ),
    );
  }
}
