import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

/// Google Sign-In result containing user data for API authentication
class GoogleSignInResult {
  final String idToken;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;

  GoogleSignInResult({
    required this.idToken,
    this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
  });
}

/// Legacy Auth Service - for backward compatibility
/// Use AuthRepository for new API-based authentication
class AuthService {
  User? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Sign in with Google
  Future<GoogleSignInResult?> loginWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google Sign-In cancelled by user');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null) {
        print('Failed to get Google ID token');
        return null;
      }

      // Parse name into first and last name
      String? firstName;
      String? lastName;
      final displayName = googleUser.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        final nameParts = displayName.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      return GoogleSignInResult(
        idToken: idToken,
        email: googleUser.email,
        firstName: firstName,
        lastName: lastName,
        profileImage: googleUser.photoUrl,
      );
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out error: $e');
    }
  }

  /// Check if user is signed in with Google
  Future<bool> isGoogleSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Login with email and password (Mock implementation)
  Future<User?> loginWithPhone(String phone) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (phone.isEmpty) {
        throw Exception('Phone number is required');
      }

      final now = DateTime.now();
      // Create mock user
      _currentUser = User(
        id: 'user_${now.millisecondsSinceEpoch}',
        phone: phone,
        userType: UserType.rider,
        createdAt: now,
        updatedAt: now,
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

      final now = DateTime.now();
      // Create mock user
      _currentUser = User(
        id: 'user_${now.millisecondsSinceEpoch}',
        firstName: 'User',
        lastName: phone.substring(phone.length - 4),
        email: '$phone@example.com',
        phone: phone,
        userType: UserType.rider,
        createdAt: now,
        updatedAt: now,
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

      final now = DateTime.now();
      // Create mock driver user
      _currentUser = User(
        id: 'driver_${now.millisecondsSinceEpoch}',
        firstName: email.split('@').first.toUpperCase(),
        email: email,
        phone: '+1234567890',
        userType: UserType.driver,
        createdAt: now,
        updatedAt: now,
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
    await signOutGoogle();
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
    return _currentUser?.userType == UserType.driver;
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

      final now = DateTime.now();
      // Create mock user
      _currentUser = User(
        id: 'user_${now.millisecondsSinceEpoch}',
        firstName: name,
        email: email,
        phone: phone,
        userType: UserType.rider,
        createdAt: now,
        updatedAt: now,
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
