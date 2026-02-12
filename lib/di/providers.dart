import 'package:drup/features/auth/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cache/cache_manager.dart';
import '../data/services/auth_service.dart';
import '../data/services/location_service.dart';
import '../data/services/google_maps_service.dart';
import '../data/services/ride_service.dart';
import '../features/passenger/repository/user_repository.dart';
import '../features/drivers/repository/driver_repository.dart';
import '../features/passenger/repository/ride_repository.dart';
import '../features/passenger/service/recent_locations_service.dart';

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

final recentLocationsServiceProvider = Provider<RecentLocationsService>((ref) {
  return RecentLocationsService(CacheManager.instance);
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

/// Provider for ride operations (both local and API)
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final rideService = ref.watch(rideServiceProvider);
  return RideRepository(rideService);
});
