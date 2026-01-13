import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import 'providers.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize with null user (not logged in)
    state = const AsyncData(null);
  }

  Future<bool> loginWithPhone(String phone) async {
    state = const AsyncLoading();

    final authService = ref.read(authServiceProvider);

    try {
      final user = await authService.loginWithPhone(phone);

      if (user != null) {
        state = AsyncData(user);
        return true;
      } else {
        state = AsyncError('Invalid credentials', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> sendOTP(String phone) async {
    final authService = ref.read(authServiceProvider);

    try {
      return await authService.sendOTP(phone);
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    state = const AsyncLoading();

    final authService = ref.read(authServiceProvider);

    try {
      final user = await authService.verifyOTP(phone, otp);

      if (user != null) {
        state = AsyncData(user);
        return true;
      } else {
        state = AsyncError('Invalid OTP', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();

    final authService = ref.read(authServiceProvider);

    try {
      final user = await authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (user != null) {
        state = AsyncData(user);
        return true;
      } else {
        state = AsyncError('Registration failed', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }

  Future<void> updateProfile(User updatedUser) async {
    final authService = ref.read(authServiceProvider);

    try {
      final user = await authService.updateProfile(updatedUser);
      state = AsyncData(user);
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
  return authState.value?.userType == 'driver';
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).value;
});
