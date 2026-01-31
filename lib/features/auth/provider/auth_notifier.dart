import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/services/auth_service.dart';
import '../repository/auth_repository.dart';
import '../model/auth.dart';
import '../../../di/providers.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;
  final AuthRepository _authRepo = AuthRepository();

  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check for existing authentication
    final isAuth = await _authRepo.isAuthenticated();
    if (isAuth) {
      final user = await _authRepo.getCurrentUser();
      state = AsyncData(user);
    } else {
      state = const AsyncData(null);
    }
  }

  /// Login with Google
  /// Returns GoogleSignInResult for API authentication flow
  Future<GoogleSignInResult?> loginWithGoogle() async {
    state = const AsyncLoading();

    final authService = ref.read(authServiceProvider);

    try {
      final result = await authService.loginWithGoogle();

      if (result == null) {
        // User cancelled or failed
        state = const AsyncData(null);
        return null;
      }

      // Return the result for the UI to continue with phone verification
      state = const AsyncData(null);
      return result;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  /// Request OTP for phone login
  /// Returns true if OTP was sent successfully
  Future<bool> loginWithPhone(String phone) async {
    state = const AsyncLoading();

    try {
      final response = await _authRepo.signIn(
        SignInRequest(phoneNumber: phone),
      );

      if (response.success) {
        // OTP sent successfully, keep loading state
        // UI will navigate to OTP screen
        state = const AsyncData(null);
        return true;
      } else {
        state = AsyncError(
          response.message ?? 'Failed to send OTP',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  /// Verify OTP and authenticate user
  Future<bool> verifyOTP(String phone, String otp) async {
    state = const AsyncLoading();

    try {
      final response = await _authRepo.verifyOtp(
        VerifyOtpRequest(phoneNumber: phone, otp: otp),
      );

      if (response.success && response.data != null) {
        // Tokens and user are automatically stored by repository
        state = AsyncData(response.data!.user);
        return true;
      } else {
        state = AsyncError(
          response.message ?? 'Invalid OTP',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  /// Complete Google Sign-In with phone verification
  /// Call after user verifies OTP with Google data
  Future<bool> completeGoogleSignIn({
    required String phone,
    required String otp,
    required GoogleData googleData,
  }) async {
    state = const AsyncLoading();

    try {
      final response = await _authRepo.googleComplete(
        GoogleCompleteRequest(
          phoneNumber: phone,
          otp: otp,
          googleData: googleData,
        ),
      );

      if (response.success && response.data != null) {
        // Tokens and user are automatically stored by repository
        state = AsyncData(response.data!.user);
        return true;
      } else {
        state = AsyncError(
          response.message ?? 'Google sign-in completion failed',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  /// Logout user and clear all auth data
  Future<void> logout() async {
    try {
      // Logout from API and clear tokens
      await _authRepo.logout();

      // Also sign out from Google
      final authService = ref.read(authServiceProvider);
      await authService.signOutGoogle();

      state = const AsyncData(null);
    } catch (e) {
      // Even if API call fails, clear local state
      state = const AsyncData(null);
    }
  }

  /// Update user profile in cache
  Future<void> updateProfile(User updatedUser) async {
    try {
      await _authRepo.updateCachedUser(updatedUser);
      state = AsyncData(updatedUser);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

// Provider instance
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      return AuthNotifier(ref);
    });

// Computed providers for convenience
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value != null;
});

final isDriverProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.userType == UserType.driver;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).value;
});
