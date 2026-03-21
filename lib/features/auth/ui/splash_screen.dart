import 'package:drup/core/animation/drup_animation.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/features/drivers/model/driver.dart';
import 'package:drup/features/drivers/provider/driver_notifier.dart';
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
    await Future.delayed(const Duration(seconds: 1));
    final currentUser = ref.read(currentUserProvider);
    final isLoggedIn = ref.read(isLoggedInProvider);
    
    // Not logged in → login screen
    if (!isLoggedIn || currentUser == null) {
      if (mounted) context.go(AppRoutes.loginRoute);
      return;
    }

    if (!mounted) return;
    final driverNotifier = ref.read(driverNotifierProvider.notifier);
    // Fetch driver application status
    await driverNotifier.fetchApplicationStatus();
    final userRepo = ref.read(userRepositoryProvider);
    final userMode = await userRepo.getUserMode();

    final appStatus = ref.read(driverNotifierProvider).applicationStatus;
    final rawStatus = appStatus?['status'] as String?;
    final status = DriverApplicationStatus.fromString(rawStatus);

    // Route based on stored user mode
    if (userMode == AppStrings.driverMode) {
      await _handleDriverNavigation(status);
    } else {
      await _handlePassengerNavigation(status);
    }
  }

  /// Passenger flow: switch role to 'user' and navigate home.
  Future<void> _handlePassengerNavigation(
    DriverApplicationStatus? status,
  ) async {
    final driverNotifier = ref.read(driverNotifierProvider.notifier);

    // Has an application — switch to driver mode
    final switched = await driverNotifier.switchRole(AppStrings.passengerRole);
    if (!mounted) return;

    if (switched) {
      // Load user profile
      await ref.read(userNotifierProvider.notifier).loadUserProfile();
      if (!mounted) return;

      // Check for incomplete profile
      final updatedUser = ref.read(currentUserProvider);
      if (updatedUser?.isEmailVerified == false ||
          updatedUser?.isPhoneVerified == false) {
        context.go(AppRoutes.completeProfileRoute);
        return;
      }
      if (mounted) context.go(AppRoutes.homeRoute);
      //////////////////
    } else {
      // Switch failed (suspended/banned) — log out and route to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account is currently suspended.')),
      );
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.loginRoute);
    }

    // final driverNotifier = ref.read(driverNotifierProvider.notifier);
    // if (status != null) {
    //   await driverNotifier.switchRole(AppStrings.passengerRole);
    // }
  }

  Future<void> _handleDriverNavigation(DriverApplicationStatus? status) async {
    final driverNotifier = ref.read(driverNotifierProvider.notifier);
    final userRepo = ref.read(userRepositoryProvider);

    if (!mounted) return;

    if (status == null) {
      final hasSeenOnboarding = await userRepo.getDriverOnboardingShown();
      if (!mounted) return;
      context.go(
        hasSeenOnboarding
            ? AppRoutes.verifyDriverRoute
            : AppRoutes.driverOnboardRoute,
      );
      return;
    }

    // Has an application — switch to driver mode
    final switched = await driverNotifier.switchRole(AppStrings.driverRole);
    if (!mounted) return;

    if (switched) {
      // Load driver profile early so drawer/UI has the name for all paths
      await driverNotifier.loadDriverProfile();
      if (!mounted) return;
      // If the driver is approved/active and hasn't seen the congrats screen,
      // route them to verify screen which shows the approval view.
      if (status == DriverApplicationStatus.approved ||
          status == DriverApplicationStatus.active) {
        final hasSeenApproval = await userRepo.getDriverApprovalSeen();
        if (!hasSeenApproval) {
          if (mounted) context.go(AppRoutes.verifyDriverRoute);
          return;
        }
      }
      if (!mounted) return;
      context.go(AppRoutes.driverHomeRoute);
      ////////////////
    } else {
      // Switch failed (suspended/banned) — fall back to passenger
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your driver account is currently suspended.'),
        ),
      );
      context.go(AppRoutes.homeRoute);
    }
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
