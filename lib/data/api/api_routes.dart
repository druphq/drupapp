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
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String uploadProfileImage = '/user/profile/image';

  // ============== SAVED PLACES ==============
  static const String savedPlaces = '/user/saved-places';
  static String savedPlace(String id) => '/user/saved-places/$id';

  // ============== EMERGENCY CONTACTS ==============
  static const String emergencyContacts = '/user/emergency-contacts';
  static String emergencyContact(String id) => '/user/emergency-contacts/$id';

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
