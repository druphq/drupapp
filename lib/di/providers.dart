import 'package:drup/features/auth/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cache/cache_manager.dart';
import '../data/services/auth_service.dart';
import '../data/services/driver_service.dart';
import '../data/services/delivery_service.dart';
import '../data/services/location_service.dart';
import '../data/services/google_maps_service.dart';
import '../data/services/ride_service.dart';
import '../features/passenger/repository/user_repository.dart';
import '../features/drivers/repository/driver_repository.dart';
import '../features/passenger/repository/ride_repository.dart';
import '../features/passenger/repository/delivery_repository.dart';
import '../features/passenger/service/recent_locations_service.dart';
import '../network/socket_client.dart';

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

final driverServiceProvider = Provider<DriverService>((ref) {
  return DriverService();
});

final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService();
});

final recentLocationsServiceProvider = Provider<RecentLocationsService>((ref) {
  return RecentLocationsService(CacheManager.instance);
});

// ============================================================================
// Socket Provider (Singleton)
// ============================================================================

final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient.instance;
  ref.onDispose(() => client.dispose());
  return client;
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

/// Provider for delivery operations (API)
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final deliveryService = ref.watch(deliveryServiceProvider);
  return DeliveryRepository(deliveryService: deliveryService);
});
