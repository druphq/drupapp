import '../models/user.dart';

class AuthService {
  User? _currentUser;

  /// Login with email and password (Mock implementation)
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // Create mock user
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first.toUpperCase(),
        email: email,
        phone: '+1234567890',
        userType: 'rider',
        rating: 4.8,
        totalRides: 25,
      );

      return _currentUser;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Login with phone and OTP (Mock implementation)
  Future<bool> sendOTP(String phone) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock OTP sent successfully
      print('OTP sent to $phone');
      return true;
    } catch (e) {
      print('Send OTP error: $e');
      return false;
    }
  }

  /// Verify OTP (Mock implementation)
  Future<User?> verifyOTP(String phone, String otp) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock OTP validation (accept any 6-digit OTP)
      if (otp.length != 6) {
        throw Exception('Invalid OTP');
      }

      // Create mock user
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'User ${phone.substring(phone.length - 4)}',
        email: '$phone@example.com',
        phone: phone,
        userType: 'rider',
        rating: 5.0,
        totalRides: 0,
      );

      return _currentUser;
    } catch (e) {
      print('Verify OTP error: $e');
      return null;
    }
  }

  /// Login as driver (Mock implementation)
  Future<User?> loginAsDriver(String email, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // Create mock driver user
      _currentUser = User(
        id: 'driver_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first.toUpperCase(),
        email: email,
        phone: '+1234567890',
        userType: 'driver',
        rating: 4.9,
        totalRides: 150,
      );

      return _currentUser;
    } catch (e) {
      print('Driver login error: $e');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
  }

  /// Get current user
  User? getCurrentUser() {
    return _currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }

  /// Check if current user is driver
  bool isDriver() {
    return _currentUser?.userType == 'driver';
  }

  /// Register new user (Mock implementation)
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw Exception('All fields are required');
      }

      // Create mock user
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        userType: 'rider',
        rating: 5.0,
        totalRides: 0,
      );

      return _currentUser;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  /// Update user profile (Mock implementation)
  Future<User?> updateProfile(User updatedUser) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = updatedUser;
      return _currentUser;
    } catch (e) {
      print('Update profile error: $e');
      return null;
    }
  }
}
