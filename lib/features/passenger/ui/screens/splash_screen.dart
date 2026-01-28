import 'package:drup/core/animation/drup_animation.dart';
import 'package:drup/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/auth_notifier.dart';
import '../../../../providers/user_notifier.dart';
import '../../../../theme/app_colors.dart';

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
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);
    final isLoggedIn = ref.read(isLoggedInProvider);
    final isDriver = ref.read(isDriverProvider);

    // Check if user is logged in
    if (isLoggedIn && currentUser != null) {
      // Initialize user data
      await ref
          .read(userNotifierProvider.notifier)
          .loadUserProfile(currentUser.id);

      // Request location permission and get current location
      await ref.read(userNotifierProvider.notifier).updateUserLocation();

      // Navigate to appropriate screen
      if (mounted) {
        if (isDriver) {
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
          decoration: const BoxDecoration(
           color: AppColors.splashBg,
          ),
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
