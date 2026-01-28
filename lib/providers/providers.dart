import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../data/services/location_service.dart';
import '../data/services/google_maps_service.dart';
import '../data/services/ride_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/driver_repository.dart';
import '../data/repositories/ride_repository.dart';

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
