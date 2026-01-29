import 'package:drup/core/animation/page_route_animation.dart';
import 'package:drup/router/app_router.dart';
import 'package:drup/features/drivers/ui/screens/driver_main_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_splash_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_onboard_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_home_screen.dart';
import 'package:drup/features/passenger/ui/screens/home_screen.dart';
import 'package:drup/features/passenger/ui/screens/location_search_screen.dart';
import 'package:drup/features/auth/ui/login_screen.dart';
import 'package:drup/features/auth/ui/otp_screen.dart';
import 'package:drup/features/auth/ui/complete_profile_screen.dart';
import 'package:drup/features/passenger/ui/screens/ride_request_screen.dart';
import 'package:drup/features/passenger/ui/screens/ride_status_screen.dart';
import 'package:drup/features/passenger/ui/screens/splash_screen.dart';
import 'package:drup/features/passenger/ui/screens/user_tracking_screen.dart';
import 'package:drup/features/passenger/ui/screens/main_screen.dart';
import 'package:drup/features/passenger/ui/screens/nigeria_airports_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:drup/features/auth/model/auth.dart';

class AppRoutes {
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';
  static const String completeProfileRoute = '/complete-profile';
  static const String homeRoute = '/home';
  static const String rideRequestRoute = '/ride-request';
  static const String driverSplashRoute = '/driver-splash';
  static const String driverOnboardRoute = '/driver-onboard';
  static const String driverHomeRoute = '/driver-home';
  static const String userTrackingRoute = '/user-tracking';
  static const String rideStatusRoute = '/ride-status';
  static const String searchLocationsRoute = '/pick-locations';
  static const String nigeriaAirportsRoute = '/nigeria-airports';
}

class AppScreens {
  static final splashRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.splashRoute,
    pageBuilder: (context, state) =>
        fadeTransitionPage(key: state.pageKey, child: const SplashScreen()),
  );

  static final loginRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.loginRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const LoginScreen(),
    ),
  );

  static final otpRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.otpRoute,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final phoneNumber = extra?['phoneNumber'] as String? ?? '';
      final isGoogleSignIn = extra?['isGoogleSignIn'] as bool? ?? false;
      final googleDataMap = extra?['googleData'] as Map<String, dynamic>?;

      GoogleData? googleData;
      if (googleDataMap != null) {
        googleData = GoogleData(
          googleId: googleDataMap['googleId'] as String? ?? '',
          email: googleDataMap['email'] as String? ?? '',
          firstName: googleDataMap['firstName'] as String?,
          lastName: googleDataMap['lastName'] as String?,
          profileImage: googleDataMap['profileImage'] as String?,
        );
      }

      return slideRightTransitionPage(
        key: state.pageKey,
        child: OTPScreen(
          phoneNumber: phoneNumber,
          googleData: googleData,
          isGoogleSignIn: isGoogleSignIn,
        ),
      );
    },
  );

  static final completeProfileRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.completeProfileRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const CompleteProfileScreen(),
    ),
  );

  //! User routes
  static final mainRoute = ShellRoute(
    navigatorKey: mainShellNavigator,
    pageBuilder: (context, state, child) {
      return slideRightTransitionPage(
        key: state.pageKey,
        child: MainScreen(child: child),
      );
    },
    routes: [homeRoute],
  );

  // user home route
  static final homeRoute = GoRoute(
    path: AppRoutes.homeRoute,
    builder: (context, state) => const HomeScreen(),
  );

  //! Driver routes
  static final driverSplashRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.driverSplashRoute,
    pageBuilder: (context, state) => fadeTransitionPage(
      key: state.pageKey,
      child: const DriverSplashScreen(),
    ),
  );

  static final driverOnboardRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.driverOnboardRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const DriverOnboardScreen(),
    ),
  );

  static final driverMainRoute = ShellRoute(
    navigatorKey: driverShellNavigator,
    pageBuilder: (context, state, child) {
      return slideRightTransitionPage(
        key: state.pageKey,
        child: DriverMainScreen(child: child),
      );
    },
    routes: [driverHomeScreen],
  );

  // driver map route
  static final driverHomeScreen = GoRoute(
    path: AppRoutes.driverHomeRoute,
    builder: (context, state) => const DriverHomeScreen(),
  );

  // other user's routes
  static final rideRequestRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.rideRequestRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const RideRequestScreen(),
    ),
  );

  // other driver's routes
  static final userTrackingRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.userTrackingRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const UserTrackingScreen(),
    ),
  );

  static final riderStatusRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.rideStatusRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const RideStatusScreen(),
    ),
  );

  static final searchLocationsRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.searchLocationsRoute,
    pageBuilder: (context, state) => slideUpTransitionPage(
      key: state.pageKey,
      child: const LocationSearchScreen(),
    ),
  );

  static final nigeriaAirportsRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.nigeriaAirportsRoute,
    pageBuilder: (context, state) {
      final isPickupLocation = state.uri.queryParameters['isPickup'] == 'true';
      return slideRightTransitionPage(
        key: state.pageKey,
        child: NigeriaAirportsScreen(isPickupLocation: isPickupLocation),
      );
    },
  );
}
