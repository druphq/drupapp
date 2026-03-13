import 'package:drup/core/animation/drup_animation.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_notifier.dart';
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
    await Future.delayed(const Duration(seconds: 4));

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
        // Check for incomplete profile first
        if (updatedUser?.isEmailVerified == false ||
            updatedUser?.isPhoneVerified == false) {
          context.go(AppRoutes.completeProfileRoute);
          return;
        }

        // Handle driver mode navigation
        if (userMode == AppStrings.driverMode || isDriver) {
          await _handleDriverNavigation();
        } else {
          // Passenger mode
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

  Future<void> _handleDriverNavigation() async {
    final userRepo = ref.read(userRepositoryProvider);

    // Check if driver onboarding has been shown
    final hasSeenOnboarding = await userRepo.getDriverOnboardingShown();

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      // First time driver mode, show onboarding
      context.go(AppRoutes.driverOnboardRoute);
      return;
    }
    context.go(AppRoutes.driverHomeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: FutureBuilder(
          future: ref.watch(userRepositoryProvider).getUserMode(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: const BoxDecoration(color: AppColors.splashBg),
              );
            } else {
              final userMode = snapshot.data;
              if (userMode == AppStrings.driverMode) {
                // Show driver splash
                return _buildDriverSplash();
              } else {
                // Show passenger splash
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.splashBg,
                    // gradient: LinearGradient(
                    //   begin: Alignment.bottomCenter,
                    //   end: Alignment.topCenter,
                    //   colors: [Color(0xff253B80), Color(0xff5490D0)],
                    // ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [DrupLogoAnimation()],
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildDriverSplash() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.accent,
        // gradient: LinearGradient(
        //   begin: Alignment.bottomCenter,
        //   end: Alignment.topCenter,
        //   colors: [
        //     Color(0xff253B80),
        //     Color(0xff253B80),
        //     Color(0xff5490D0),
        //     Color(0xff5C9EDC),
        //   ],
        // ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ImageIcon(
                  AssetImage(AppAssets.drupLogoIcon),
                  size: 70,
                  color: Colors.white,
                ),
                // Animated Drup text logo sliding out from the logo icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.drupTextIcon,
                      height: 50,
                      width: 120,
                      fit: BoxFit.fill,
                      color: Colors.white,
                    ),
                    Text(
                      'Driver',
                      style: TextStyles.appTitle1.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
        
        
        //  Container(
        //   decoration: const BoxDecoration(color: AppColors.splashBg),
        //   child: Center(
        //     child: Stack(
        //       alignment: Alignment.center,
        //       children: [DrupLogoAnimation()],
        //     ),
        //   ),
        // ),
    //   ),
    // );
  // }
// }
