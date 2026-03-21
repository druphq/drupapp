import 'package:drup/di/notifiers.dart';
import 'package:drup/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/provider/auth_notifier.dart';

final GlobalKey<NavigatorState> rootNavigator = GlobalKey(debugLabel: 'root');
final GlobalKey<NavigatorState> mainShellNavigator = GlobalKey(
  debugLabel: 'main',
);
final GlobalKey<NavigatorState> driverShellNavigator = GlobalKey(
  debugLabel: 'driver',
);

// Listenable to trigger router refresh without recreating the router
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    // Listen to auth changes and notify router to re-evaluate redirects
    ref.listen(isLoggedInProvider, (_, __) => notifyListeners());
    ref.listen(isDriverProvider, (_, __) => notifyListeners());
    // ref.listen(userNotifierProvider, (_, __) => notifyListeners());
  }
}

// Provider for the router - ensures single instance across rebuilds
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  // Initial location is always splash - it will handle mode-based navigation
  return GoRouter(
    initialLocation: AppRoutes.splashRoute,
    navigatorKey: rootNavigator,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final isDriver = ref.read(isDriverProvider);
      final user = ref.read(userNotifierProvider).user;
      final currentPath = state.matchedLocation;

      // Skip redirect for splash screen
      if (currentPath == AppRoutes.splashRoute) {
        return null;
      }

      // Allow access full authentication
      if (currentPath == AppRoutes.otpRoute ||
          currentPath == AppRoutes.emailVerificationRoute ||
          currentPath == AppRoutes.completeProfileRoute) {
        return null;
      }

      // Redirect to login if not logged in
      if (!isLoggedIn && currentPath != AppRoutes.loginRoute) {
        return AppRoutes.loginRoute;
      }

      // Redirect to complete profile if profile is incomplete
      // Skip this check for auth screens, driver-mode screens, and when
      // the user is currently operating in driver mode.
      if (isLoggedIn &&
          !isDriver &&
          user != null &&
          !user.isProfileComplete &&
          currentPath != AppRoutes.completeProfileRoute &&
          currentPath != AppRoutes.otpRoute &&
          currentPath != AppRoutes.emailVerificationRoute &&
          !currentPath.startsWith('/driver') &&
          currentPath != AppRoutes.verifyDriverRoute &&
          currentPath != AppRoutes.applyDriverRoute &&
          currentPath != AppRoutes.documentsRoute &&
          currentPath != AppRoutes.vehicleInfoRoute) {
        return AppRoutes.completeProfileRoute;
      }

      // Redirect logged-in users away from login
      if (isLoggedIn && currentPath == AppRoutes.loginRoute) {
        return isDriver ? AppRoutes.driverHomeRoute : AppRoutes.homeRoute;
      }

      return null;
    },
    routes: [
      AppScreens.splashRoute,
      AppScreens.loginRoute,
      AppScreens.otpRoute,
      AppScreens.emailVerificationRoute,
      AppScreens.completeProfileRoute,
      AppScreens.mainRoute,
      AppScreens.pickRideLocationRoute,
      AppScreens.pickDeliveryLocationRoute,
      AppScreens.registerDeliveryRoute,
      AppScreens.nigeriaAirportsRoute,
      AppScreens.rideHistoryRoute,
      AppScreens.messagesRoute,
      AppScreens.supportRoute,
      AppScreens.aboutRoute,
      AppScreens.accountRoute,
      AppScreens.personalInfoRoute,
      AppScreens.reviewsRoute,
      AppScreens.privacyPolicyRoute,
      AppScreens.deleteAccountRoute,
      AppScreens.driverSplashRoute,
      AppScreens.driverOnboardRoute,
      AppScreens.driverMainRoute,
      AppScreens.verifyDriverRoute,
      AppScreens.applyDriverRoute,
      AppScreens.driverAccountRoute,
      AppScreens.rideRequestRoute,
      AppScreens.userTrackingRoute,
      AppScreens.paymentsRoute,
      AppScreens.paymentDetailRoute,
      AppScreens.rideDetailsRoute,
      AppScreens.deliveryDetailsRoute,
      AppScreens.paymentReceiptRoute,
      AppScreens.paymentWebViewRoute,
      AppScreens.vehicleInfoRoute,
      AppScreens.documentsRoute,
      AppScreens.bankDetailRoute,
      AppScreens.driverRideHistoryRoute,
      AppScreens.driverRideDetailRoute,
      AppScreens.driverRideRequestsRoute,
      AppScreens.rideRequestDetailRoute,
    ],
  );
});

