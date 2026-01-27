import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API Keys - Loaded from environment variables
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Map Settings
  static const double defaultZoom = 15.0;
  static const double defaultCameraZoom = 14.5;
  static const int locationUpdateIntervalMillis = 3000; // 3 seconds

  // Ride Settings
  static const double baseFare = 2.5;
  static const double perKmRate = 1.5;
  static const double perMinuteRate = 0.3;
  static const double bookingFee = 1.0;

  // Driver Settings
  static const int maxDriverSearchRadius = 10; // km
  static const int rideRequestTimeoutSeconds = 60;

  // Mock Data
  static const int numberOfMockDrivers = 5;
  static const double driverMovementSpeedKmH = 40.0; // km/h for simulation

  // Storage Keys
  static const String userIdKey = 'userId';
  static const String userTypeKey = 'userType';
  static const String isLoggedInKey = 'isLoggedIn';


  // Cache Keys
  static const String airportsKey = 'app_cachedAirports';
}

enum UserType { rider, driver }

enum RideStatus {
  pending,
  accepted,
  driverArriving,
  tripStarted,
  tripCompleted,
  cancelled,
}

enum PaymentMethod { cash, card, wallet }
