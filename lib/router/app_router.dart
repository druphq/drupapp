import 'package:drup/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';
import '../core/constants/constants.dart';

class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    final isDriver = ref.read(isDriverProvider);

    // Determine initial location based on auth state
    String initialLocation = AppConstants.splashRoute;
    if (isLoggedIn) {
      // check if user's last activity was as a driver or rider
      initialLocation = isDriver
          ? AppConstants.driverMapRoute
          : AppConstants.homeRoute;
    }

    return GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) {
        final isLoggedIn = ref.read(isLoggedInProvider);
        final isDriver = ref.read(isDriverProvider);

        print(
          'Redirect check: isLoggedIn=$isLoggedIn, isDriver=$isDriver, location=${state.matchedLocation}',
        );

        // Skip redirect for splash screen
        if (state.matchedLocation == AppConstants.splashRoute) {
          return null;
        }

        // Redirect to login if not logged in
        if (!isLoggedIn && state.matchedLocation != AppConstants.loginRoute) {
          return AppConstants.loginRoute;
        }

        // Redirect logged-in users away from login
        if (isLoggedIn && state.matchedLocation == AppConstants.loginRoute) {
          return isDriver
              ? AppConstants.driverMapRoute
              : AppConstants.homeRoute;
        }

        return null;
      },
      routes: [
        AppRoutes.splashRoute,
        AppRoutes.loginRoute,
        AppRoutes.homeRoute,
        AppRoutes.rideRequestRoute,
        AppRoutes.driverMapScreen,
        AppRoutes.userTrackingRoute,
        AppRoutes.riderStatusRoute,
      ],
    );
  }
}
