import 'package:drup/core/animation/page_route_animation.dart';
import 'package:drup/router/app_router.dart';
import 'package:drup/features/drivers/ui/screens/driver_main_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_splash_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_onboard_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_home_screen.dart';
import 'package:drup/features/drivers/ui/screens/verify_driver_screen.dart';
import 'package:drup/features/drivers/ui/screens/driver_account_screen.dart';
import 'package:drup/features/passenger/ui/screens/home_screen.dart';
import 'package:drup/features/passenger/ui/screens/pick_location_screen.dart';
import 'package:drup/features/auth/ui/login_screen.dart';
import 'package:drup/features/auth/ui/otp_screen.dart';
import 'package:drup/features/auth/ui/email_verification_screen.dart';
import 'package:drup/features/auth/ui/complete_profile_screen.dart';
import 'package:drup/features/passenger/ui/screens/ride_request_screen.dart';
import 'package:drup/features/passenger/ui/screens/ride_status_screen.dart';
import 'package:drup/features/auth/ui/splash_screen.dart';
import 'package:drup/features/passenger/ui/screens/user_tracking_screen.dart';
import 'package:drup/features/passenger/ui/screens/main_screen.dart';
import 'package:drup/features/passenger/ui/screens/nigeria_airports_screen.dart';
import 'package:drup/features/passenger/ui/screens/ride_history_screen.dart';
import 'package:drup/features/passenger/ui/screens/messages_screen.dart';
import 'package:drup/features/passenger/ui/screens/support_screen.dart';
import 'package:drup/features/passenger/ui/screens/about_screen.dart';
import 'package:drup/features/passenger/ui/screens/account_screen.dart';
import 'package:drup/features/passenger/ui/screens/personal_info_screen.dart';
import 'package:drup/features/passenger/ui/screens/reviews_screen.dart';
import 'package:drup/features/passenger/ui/screens/privacy_policy_screen.dart';
import 'package:drup/features/passenger/ui/screens/delete_account_screen.dart';
import 'package:drup/features/passenger/ui/screens/ride_details_screen.dart';
import 'package:drup/features/passenger/ui/screens/payment_webview_screen.dart';
import 'package:drup/features/passenger/ui/screens/payments_screen.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:go_router/go_router.dart';
import 'package:drup/features/auth/model/auth.dart';
import 'package:drup/features/passenger/ui/screens/payment_detail_screen.dart';

class AppRoutes {
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';
  static const String pickLocationRoute = '/pick-locations';
  static const String emailVerificationRoute = '/email-verification';
  static const String completeProfileRoute = '/complete-profile';
  static const String homeRoute = '/home';
  static const String rideRequestRoute = '/ride-request';
  static const String driverSplashRoute = '/driver-splash';
  static const String driverOnboardRoute = '/driver-onboard';
  static const String driverHomeRoute = '/driver-home';
  static const String verifyDriverRoute = '/verify-driver';
  static const String driverAccountRoute = '/driver-account';
  static const String userTrackingRoute = '/user-tracking';
  static const String rideStatusRoute = '/ride-status';
  static const String nigeriaAirportsRoute = '/nigeria-airports';
  static const String rideHistoryRoute = '/ride-history';
  static const String messagesRoute = '/messages';
  static const String supportRoute = '/support';
  static const String aboutRoute = '/about';
  static const String accountRoute = '/account';
  static const String personalInfoRoute = '/personal-info';
  static const String reviewsRoute = '/reviews';
  static const String privacyPolicyRoute = '/privacy-policy';
  static const String deleteAccountRoute = '/delete-account';
  static const String paymentsRoute = '/payments';
  static const String rideDetailsRoute = '/ride-details';
  static const String paymentDetailRoute = '/payment-detail';
  static const String paymentWebViewRoute = '/payment-webview';
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

  static final emailVerificationRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.emailVerificationRoute,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final email = extra?['email'] as String? ?? '';

      return slideRightTransitionPage(
        key: state.pageKey,
        child: EmailVerificationScreen(email: email),
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

  static final pickLocationRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.pickLocationRoute,
    pageBuilder: (context, state) => slideUpTransitionPage(
      key: state.pageKey,
      child: const PickLocationScreen(),
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

  static final rideHistoryRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.rideHistoryRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const RideHistoryScreen(),
    ),
  );

  static final messagesRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.messagesRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const MessagesScreen(),
    ),
  );

  static final supportRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.supportRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const SupportScreen(),
    ),
  );

  static final aboutRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.aboutRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const AboutScreen(),
    ),
  );

  static final accountRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.accountRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const AccountScreen(),
    ),
  );

  static final personalInfoRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.personalInfoRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const PersonalInfoScreen(),
    ),
  );

  static final reviewsRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.reviewsRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const ReviewsScreen(),
    ),
  );

  static final privacyPolicyRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.privacyPolicyRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const PrivacyPolicyScreen(),
    ),
  );

  static final deleteAccountRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.deleteAccountRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const DeleteAccountScreen(),
    ),
  );

  static final verifyDriverRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.verifyDriverRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const VerifyDriverScreen(),
    ),
  );

  static final driverAccountRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.driverAccountRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const DriverAccountScreen(),
    ),
  );

  static final paymentsRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.paymentsRoute,
    pageBuilder: (context, state) => slideRightTransitionPage(
      key: state.pageKey,
      child: const PaymentsScreen(),
    ),
  );

  static final rideDetailsRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.rideDetailsRoute,
    pageBuilder: (context, state) {
      final ride = state.extra as BookedRide;
      return slideRightTransitionPage(
        key: state.pageKey,
        child: RideDetailsScreen(ride: ride),
      );
    },
  );

  static final paymentDetailRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.paymentDetailRoute,
    pageBuilder: (context, state) {
      final paymentInfo = state.extra as PaymentHistoryItem;
      return slideRightTransitionPage(
        key: state.pageKey,
        child: PaymentDetailScreen(paymentInfo: paymentInfo),
      );
    },
  );

  static final paymentWebViewRoute = GoRoute(
    parentNavigatorKey: rootNavigator,
    path: AppRoutes.paymentWebViewRoute,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      final authorizationUrl = extra['authorizationUrl'] as String;
      final onPaymentComplete = extra['onPaymentComplete'] as void Function();
      return slideRightTransitionPage(
        key: state.pageKey,
        child: PaymentWebViewScreen(
          authorizationUrl: authorizationUrl,
          onPaymentComplete: onPaymentComplete,
        ),
      );
    },
  );
}
