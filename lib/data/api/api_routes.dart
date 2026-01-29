/// API Routes for DRUP Application
class ApiRoutes {
  ApiRoutes._();

  // ============== AUTH ROUTES ==============
  static const String signIn = '/auth/user/sign-in';
  static const String verifyOtp = '/auth/user/verify-otp';
  static const String googleSignIn = '/auth/user/google';
  static const String googleComplete = '/auth/user/google/complete';
  static const String refreshToken = '/auth/user/refresh-token';
  static const String logout = '/auth/user/logout';

  // ============== USER ROUTES ==============
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadProfilePhoto = '/users/profile/photo';
  static const String deviceToken = '/users/device-token';
  static const String deleteAccount = '/users/account';

  // ============== SAVED PLACES ==============
  static const String savedPlaces = '/users/places';
  static String savedPlace(String id) => '/users/places/$id';

  // ============== EMERGENCY CONTACTS ==============
  static const String emergencyContacts = '/users/emergency-contacts';
  static String emergencyContact(String id) => '/users/emergency-contacts/$id';

  // ============== NOTIFICATIONS ==============
  static const String notificationSettings = '/users/notifications';

  // ============== EMAIL VERIFICATION ==============
  static const String resendEmailVerification =
      '/users/email/resend-verification';
  static const String verifyEmail = '/users/email/verify';

  // ============== RIDE HISTORY ==============
  static const String userRides = '/users/rides';

  // ============== WALLET ==============
  static const String wallet = '/user/wallet';
  static const String addFunds = '/user/wallet/add-funds';

  // ============== RIDES ==============
  static const String requestRide = '/rides/request';
  static String ride(String id) => '/rides/$id';
  static const String rideHistory = '/rides/history';
  static String cancelRide(String id) => '/rides/$id/cancel';
  static String rateRide(String id) => '/rides/$id/rate';
}
