import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/models/location_model.dart';
import 'providers.dart';

class UserState {
  final User? user;
  final LocationModel? currentLocation;
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> rideHistory;

  UserState({
    this.user,
    this.currentLocation,
    this.isLoading = false,
    this.errorMessage,
    this.rideHistory = const [],
  });

  UserState copyWith({
    User? user,
    LocationModel? currentLocation,
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? rideHistory,
  }) {
    return UserState(
      user: user ?? this.user,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      rideHistory: rideHistory ?? this.rideHistory,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final Ref ref;

  UserNotifier(this.ref) : super(UserState());

  Future<void> loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final user = await userRepository.getUserById(userId);

      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: 'User not found',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> updateUserLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      if (location != null) {
        state = state.copyWith(currentLocation: location);

        if (state.user != null) {
          final userRepository = ref.read(userRepositoryProvider);
          await userRepository.updateUserLocation(
            state.user!.id,
            location.latitude,
            location.longitude,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadRideHistory(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final history = await userRepository.getUserRideHistory(userId);

      state = state.copyWith(rideHistory: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<bool> updateProfile(User updatedUser) async {
    state = state.copyWith(isLoading: true);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final updatedUserResult = await userRepository.updateUserProfile(
        updatedUser,
      );

      if (updatedUserResult != null) {
        state = state.copyWith(user: updatedUser, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to update profile',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }
}

// Provider instance
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((
  ref,
) {
  return UserNotifier(ref);
});
