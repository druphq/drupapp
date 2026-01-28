import '../models/user.dart';
import '../services/auth_service.dart';

class UserRepository {
  final AuthService _authService;

  UserRepository(this._authService);

  /// Get current user
  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  /// Update user profile
  Future<User?> updateUserProfile(User user) async {
    // Mock update - in real app, this would call an API
    await Future.delayed(const Duration(milliseconds: 500));
    return user;
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    // Mock - in real app, this would call an API
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    // Return mock user
    return User(
      id: userId,
      firstName: 'Mock',
      lastName: 'User',
      email: 'user@example.com',
      phone: '+1234567890',
      userType: UserType.rider,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _authService.isLoggedIn();
  }

  /// Check if user is driver
  bool isDriver() {
    return _authService.isDriver();
  }

  /// Update user location (Mock implementation)
  Future<bool> updateUserLocation(String userId, double lat, double lng) async {
    // Mock - in real app, this would call an API
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// Get user ride history (Mock implementation)
  Future<List<dynamic>> getUserRideHistory(String userId) async {
    // Mock - in real app, this would call an API
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}
