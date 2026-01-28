import '../models/user.dart';
import '../../features/auth/repository/auth_repository.dart';

/// Repository for user-related operations
/// Uses AuthRepository for user data management
class UserRepository {
  final AuthRepository _authRepo;

  UserRepository({AuthRepository? authRepository})
    : _authRepo = authRepository ?? AuthRepository();

  /// Get current user from cache
  Future<User?> getCurrentUser() async {
    return await _authRepo.getCurrentUser();
  }

  /// Update user profile in cache
  /// For API-based profile updates, use user profile API endpoints
  Future<User?> updateUserProfile(User user) async {
    await _authRepo.updateCachedUser(user);
    return user;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _authRepo.isAuthenticated();
  }

  /// Check if user is driver
  Future<bool> isDriver() async {
    final user = await getCurrentUser();
    return user?.userType == UserType.driver;
  }

  /// Update user location
  /// TODO: Implement API call to update location
  Future<void> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
  ) async {
    // TODO: Implement API endpoint for location updates
    // For now, location updates are handled locally
  }

  /// Get user ride history
  /// TODO: Implement API call to /rides/history
  Future<List<dynamic>> getUserRideHistory(String userId) async {
    // TODO: Implement ride history API call
    return [];
  }
}
