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
      // But skip this check if navigating to verification sscreens
      if (isLoggedIn &&
          user != null &&
          !user.isProfileComplete &&
          currentPath != AppRoutes.completeProfileRoute &&
          currentPath != AppRoutes.otpRoute &&
          currentPath != AppRoutes.emailVerificationRoute) {
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
      AppScreens.deliveryRecipientRoute,
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
      AppScreens.driverAccountRoute,
      AppScreens.rideRequestRoute,
      AppScreens.userTrackingRoute,
      AppScreens.paymentsRoute,
      AppScreens.paymentDetailRoute,
      AppScreens.rideDetailsRoute,
      AppScreens.paymentWebViewRoute,
    ],
  );
});

// class AppRouter {
//   static GoRouter createRouter(WidgetRef ref) {
//     final isLoggedIn = ref.read(isLoggedInProvider);
//     final isDriver = ref.read(isDriverProvider);

//     // Determine initial location based on auth state and
//     String initialLocation = AppRoutes.splashRoute;
//     if (isLoggedIn) {
//       // check if user's last activity was as a driver or rider
//       initialLocation = isDriver
//           ? AppRoutes.driverHomeRoute
//           : AppRoutes.homeRoute;
//     }

//     return GoRouter(
//       initialLocation: initialLocation,
//       navigatorKey: rootNavigator,
//       redirect: (context, state) {
//         final isLoggedIn = ref.read(isLoggedInProvider);
//         final isDriver = ref.read(isDriverProvider);
//         final user = ref.read(userNotifierProvider).user;

//         // Skip redirect for splash screen
//         if (state.matchedLocation == AppRoutes.splashRoute) {
//           return null;
//         }

//         // Allow access to OTP and complete
//         // profile screens without full authentication
//         if (state.matchedLocation == AppRoutes.otpRoute ||
//             state.matchedLocation == AppRoutes.completeProfileRoute) {
//           return null;
//         }

//         // Redirect to login if not logged in
//         if (!isLoggedIn && state.matchedLocation != AppRoutes.loginRoute) {
//           return AppRoutes.loginRoute;
//         }

//         // check if user has complete profile
//         if (isLoggedIn &&
//             (user?.isEmailVerified == false ||
//                 user?.isPhoneVerified == false) &&
//             state.matchedLocation != AppRoutes.completeProfileRoute) {
//           return AppRoutes.completeProfileRoute;
//         }

//         // Redirect logged-in users away from login
//         if (isLoggedIn && state.matchedLocation == AppRoutes.loginRoute) {
//           return isDriver ? AppRoutes.driverHomeRoute : AppRoutes.homeRoute;
//         }

//         return null;
//       },
//       routes: [
//         AppScreens.splashRoute,
//         AppScreens.loginRoute,
//         AppScreens.otpRoute,
//         AppScreens.completeProfileRoute,
//         AppScreens.mainRoute,
//         AppScreens.driverSplashRoute,
//         AppScreens.driverOnboardRoute,
//         AppScreens.driverMainRoute,
//         AppScreens.rideRequestRoute,
//         AppScreens.userTrackingRoute,
//         AppScreens.riderStatusRoute,
//         AppScreens.searchLocationsRoute,
//         AppScreens.nigeriaAirportsRoute,
//       ],
//     );
//   }
// }
