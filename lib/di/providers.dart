import 'package:drup/features/auth/repository/auth_repository.dart';
import 'package:drup/features/passenger/repository/ride_api_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../data/services/location_service.dart';
import '../data/services/google_maps_service.dart';
import '../data/services/ride_service.dart';
import '../features/passenger/repository/user_repository.dart';
import '../features/drivers/repository/driver_repository.dart';
import '../features/passenger/repository/ride_repository.dart';

// ============================================================================
// Service Providers (Singletons)
// ============================================================================

final authServiceProvider = Provider<ExternalAuthService>((ref) {
  return ExternalAuthService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService();
});

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService();
});

// ============================================================================
// Repository Providers (Depend on Services)
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final rideService = ref.watch(rideServiceProvider);
  return RideRepository(rideService);
});

/// Provider for ride API operations (booking, payments, etc.)
final rideApiRepositoryProvider = Provider<RideApiRepository>((ref) {
  return RideApiRepository();
});
