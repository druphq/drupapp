import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';

class DriverSplashScreen extends ConsumerStatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  ConsumerState<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends ConsumerState<DriverSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // check if driver is verified
    final isVerified = await ref
        .read(userNotifierProvider.notifier)
        .isDriverVerified();

    if (!mounted) return;

    // Check if driver onboarding has been shown
    final hasSeenOnboarding = await ref
        .read(userRepositoryProvider)
        .getDriverOnboardingShown();

    // Navigate to appropriate screen
    if (mounted) {
      if (hasSeenOnboarding) {
        if (isVerified) {
          context.go(AppRoutes.driverHomeRoute);
        } else {
          context.go(AppRoutes.verifyDriverRoute);
        }
      } else {
        // First time driver mode, show onboarding
        context.go(AppRoutes.driverOnboardRoute);
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
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xff253B80),
                Color(0xff253B80),
                Color(0xff5490D0),
                Color(0xff5C9EDC),
              ],
            ),
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
        ),
      ),
    );
  }
}
