import 'package:drup/core/animation/page_route_animation.dart';
import 'package:drup/router/app_router.dart';
import 'package:drup/ui/driver/driver_main_screen.dart';
import 'package:drup/ui/screens/driver_map_screen.dart';
import 'package:drup/ui/screens/home_screen.dart';
import 'package:drup/ui/screens/location_search_screen.dart';
import 'package:drup/ui/screens/login_screen.dart';
import 'package:drup/ui/screens/ride_request_screen.dart';
import 'package:drup/ui/screens/ride_status_screen.dart';
import 'package:drup/ui/screens/splash_screen.dart';
import 'package:drup/ui/screens/user_tracking_screen.dart';
import 'package:drup/ui/user/main_screen.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String rideRequestRoute = '/ride-request';
  static const String driverMapRoute = '/driver-map';
  static const String userTrackingRoute = '/user-tracking';
  static const String rideStatusRoute = '/ride-status';
  static const String searchLocationsRoute = '/pick-locations';
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
  static final driverMainRoute = ShellRoute(
    navigatorKey: driverShellNavigator,
    pageBuilder: (context, state, child) {
      return slideRightTransitionPage(
        key: state.pageKey,
        child: DriverMainScreen(child: child),
      );
    },
    routes: [driverMapScreen],
  );

  // driver map route
  static final driverMapScreen = GoRoute(
    path: AppRoutes.driverMapRoute,
    builder: (context, state) => const DriverMapScreen(),
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
}
