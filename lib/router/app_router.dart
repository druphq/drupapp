import 'package:drup/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';

final GlobalKey<NavigatorState> rootNavigator = GlobalKey(debugLabel: 'root');
final GlobalKey<NavigatorState> mainShellNavigator = GlobalKey(
  debugLabel: 'main',
);
final GlobalKey<NavigatorState> driverShellNavigator = GlobalKey(
  debugLabel: 'driver',
);

class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    final isDriver = ref.read(isDriverProvider);

    // Determine initial location based on auth state
    String initialLocation = AppRoutes.splashRoute;
    if (isLoggedIn) {
      // check if user's last activity was as a driver or rider
      initialLocation = isDriver
          ? AppRoutes.driverHomeRoute
          : AppRoutes.homeRoute;
    }

    return GoRouter(
      initialLocation: initialLocation,
      navigatorKey: rootNavigator,
      redirect: (context, state) {
        final isLoggedIn = ref.read(isLoggedInProvider);
        final isDriver = ref.read(isDriverProvider);

        // Skip redirect for splash screen
        if (state.matchedLocation == AppRoutes.splashRoute) {
          return null;
        }

        // Redirect to login if not logged in
        if (!isLoggedIn && state.matchedLocation != AppRoutes.loginRoute) {
          return AppRoutes.loginRoute;
        }

        // Redirect logged-in users away from login
        if (isLoggedIn && state.matchedLocation == AppRoutes.loginRoute) {
          return isDriver ? AppRoutes.driverHomeRoute : AppRoutes.homeRoute;
        }

        return null;
      },
      routes: [
        AppScreens.splashRoute,
        AppScreens.loginRoute,
        AppScreens.mainRoute,
        AppScreens.driverMainRoute,
        AppScreens.rideRequestRoute,
        AppScreens.userTrackingRoute,
        AppScreens.riderStatusRoute,
        AppScreens.searchLocationsRoute,
      ],
    );
  }
}
