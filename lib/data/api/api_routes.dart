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
  static const String fareEstimate = '/rides/estimate';
  static const String availableSlots = '/rides/available-slots';
  static const String bookRide = '/rides';
  static const String activeRide = '/rides/active';

  // ============== PAYMENTS ==============
  static const String initRidePayment = '/payments/ride';
  static const String payWithSavedCard = '/payments/ride/saved-card';
  static String verifyPayment(String reference) =>
      '/payments/verify/$reference';
  static const String savedCards = '/payments/cards';
  static String deleteCard(String cardId) => '/payments/cards/$cardId';
  static String setDefaultCard(String cardId) =>
      '/payments/cards/$cardId/default';
  static const String walletBalance = '/payments/wallet';
  static const String walletTopUp = '/payments/wallet/topup';
  static const String walletTransactions = '/payments/wallet/transactions';
  static const String paymentHistory = '/payments/history';

  // ============== DELIVERIES ==============
  static const String deliveryEstimate = '/deliveries/estimate';
  static const String bookDelivery = '/deliveries';
  static String pickupPackage(String rideId) =>
      '/deliveries/$rideId/pickup-package';
  static String deliverPackage(String rideId) => '/deliveries/$rideId/deliver';

  // ============== DRIVER APPLICATION (USER ROUTES) ==============
  static const String applyDriver = '/users/apply-driver';
  static const String driverStatus = '/users/driver-status';
  static const String switchRole = '/users/switch-role';

  // ============== DRIVER PROFILE ==============
  static const String driverProfile = '/drivers/profile';
  static const String driverProfilePhoto = '/drivers/profile/photo';
  static const String driverDeviceToken = '/drivers/device-token';

  // ============== DRIVER VEHICLE ==============
  static const String driverVehicle = '/drivers/vehicle';

  // ============== DRIVER DOCUMENTS ==============
  static const String driverDocuments = '/drivers/documents';

  // ============== DRIVER VERIFICATION ==============
  static const String driverVerificationStatus = '/drivers/verification-status';

  // ============== DRIVER STATUS & LOCATION ==============
  static const String driverOnlineStatus = '/drivers/status';
  static const String driverLocation = '/drivers/location';

  // ============== DRIVER RIDE OPERATIONS ==============
  static const String nearbyRides = '/rides/nearby';
  static String acceptRide(String rideId) => '/rides/$rideId/accept';
  static String declineRide(String rideId) => '/rides/$rideId/decline';
  static String arrivedAtPickup(String rideId) => '/rides/$rideId/arrived';
  static String startRide(String rideId) => '/rides/$rideId/start';
  static String completeRide(String rideId) => '/rides/$rideId/complete';
  static String driverCancelRide(String rideId) =>
      '/rides/$rideId/driver-cancel';
  static const String driverActiveRide = '/rides/driver/active';
  static const String driverScheduledRides = '/rides/driver/scheduled';
  static const String driverRideHistory = '/rides/driver/history';

  // ============== SHARED RIDE PASSENGER MANAGEMENT ==============
  static String ridePassengers(String rideId) => '/rides/$rideId/passengers';
  static String passengerArrived(String rideId, String passengerId) =>
      '/rides/$rideId/passengers/$passengerId/arrived';
  static String passengerPickedUp(String rideId, String passengerId) =>
      '/rides/$rideId/passengers/$passengerId/picked-up';
  static String passengerNoShow(String rideId, String passengerId) =>
      '/rides/$rideId/passengers/$passengerId/no-show';
  static String passengerArrivingDropoff(String rideId, String passengerId) =>
      '/rides/$rideId/passengers/$passengerId/arriving-dropoff';
  static String passengerDroppedOff(String rideId, String passengerId) =>
      '/rides/$rideId/passengers/$passengerId/dropped-off';

  // ============== DRIVER EARNINGS ==============
  static const String driverEarnings = '/drivers/earnings';

  // ============== DRIVER BANK ACCOUNT ==============
  static const String driverBankAccount = '/drivers/bank-account';
  static const String deleteDriverAccount = '/drivers/account';

  // ============== BANK LIST & VERIFICATION ==============
  static const String bankList = '/payments/banks';
  static const String verifyBankAccount = '/payments/verify-bank';
}
