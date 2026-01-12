import 'package:drup/core/constants/constants.dart';
import 'package:drup/ui/screens/driver_map_screen.dart';
import 'package:drup/ui/screens/home_screen.dart';
import 'package:drup/ui/screens/login_screen.dart';
import 'package:drup/ui/screens/ride_request_screen.dart';
import 'package:drup/ui/screens/ride_status_screen.dart';
import 'package:drup/ui/screens/splash_screen.dart';
import 'package:drup/ui/screens/user_tracking_screen.dart';
import 'package:go_router/go_router.dart';

class RoutePaths {
  static final splashPath = 'splash';
  static final loginPath = 'login';
  static final homePath = 'home';
  static final rideRequestPath = 'ride-request';
  static final driverMapPath = 'driver-map';
  static final userTrackingPath = 'user-tracking';
  static final rideStatusPath = 'ride-status';
}

class AppRoutes {
  static final splashRoute = GoRoute(
    path: AppConstants.splashRoute,
    name: RoutePaths.splashPath,
    builder: (context, state) => const SplashScreen(),
  );

  static final loginRoute = GoRoute(
    path: AppConstants.loginRoute,
    name: RoutePaths.loginPath,
    builder: (context, state) => const LoginScreen(),
  );

  static final homeRoute = GoRoute(
    path: AppConstants.homeRoute,
    name: RoutePaths.homePath,
    builder: (context, state) => const HomeScreen(),
  );

  static final rideRequestRoute = GoRoute(
    path: AppConstants.rideRequestRoute,
    name: RoutePaths.rideRequestPath,
    builder: (context, state) => const RideRequestScreen(),
  );

  static final driverMapScreen = GoRoute(
    path: AppConstants.driverMapRoute,
    name: RoutePaths.driverMapPath,
    builder: (context, state) => const DriverMapScreen(),
  );

  static final userTrackingRoute = GoRoute(
    path: AppConstants.userTrackingRoute,
    name: RoutePaths.userTrackingPath,
    builder: (context, state) => const UserTrackingScreen(),
  );

  static final riderStatusRoute = GoRoute(
    path: AppConstants.rideStatusRoute,
    name: RoutePaths.rideStatusPath,
    builder: (context, state) => const RideStatusScreen(),
  );
}
