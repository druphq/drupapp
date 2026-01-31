import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/models/location_model.dart';
import '../../../di/providers.dart';

class UserState {
  final User? user;
  final LocationModel? currentLocation;
  final bool isLoading;
  final bool isUploadingPhoto;
  final String? errorMessage;
  final String? successMessage;
  final List<dynamic> rideHistory;
  final List<SavedPlace> savedPlaces;
  final List<EmergencyContact> emergencyContacts;

  UserState({
    this.user,
    this.currentLocation,
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.errorMessage,
    this.successMessage,
    this.rideHistory = const [],
    this.savedPlaces = const [],
    this.emergencyContacts = const [],
  });

  UserState copyWith({
    User? user,
    LocationModel? currentLocation,
    bool? isLoading,
    bool? isUploadingPhoto,
    String? errorMessage,
    String? successMessage,
    List<dynamic>? rideHistory,
    List<SavedPlace>? savedPlaces,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserState(
      user: user ?? this.user,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      errorMessage: errorMessage,
      successMessage: successMessage,
      rideHistory: rideHistory ?? this.rideHistory,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

// Provider instance
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((
  ref,
) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<UserState> {
  final Ref ref;

  UserNotifier(this.ref) : super(UserState()) {
    _initialize();
  }

  /// Initialize user state from cache
  Future<void> _initialize() async {
    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    if (user != null) {
      state = state.copyWith(
        user: user,
        savedPlaces: user.savedPlaces,
        emergencyContacts: user.emergencyContacts,
      );
    }
  }

  /// Clear any messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// Fetch user profile from API
  Future<void> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.getUserProfile();

      if (response.success && response.data != null) {
        state = state.copyWith(
          user: response.data,
          savedPlaces: response.data!.savedPlaces,
          emergencyContacts: response.data!.emergencyContacts,
          isLoading: false,
          successMessage: 'Profile loaded',
        );
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to load profile',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Update profile info
  Future<bool> updateProfileInfo({
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          user: response.data,
          isLoading: false,
          successMessage: response.message ?? 'Profile updated',
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to update profile',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Upload profile photo
  Future<bool> uploadPhoto(File photoFile) async {
    state = state.copyWith(isUploadingPhoto: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.uploadProfilePhoto(photoFile);

      if (response.success && response.data != null) {
        // Update user with new photo URL
        final updatedUser = state.user?.copyWith(profileImage: response.data);
        state = state.copyWith(
          user: updatedUser,
          isUploadingPhoto: false,
          successMessage: 'Photo uploaded',
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to upload photo',
          isUploadingPhoto: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isUploadingPhoto: false,
      );
      return false;
    }
  }

  /// Load saved places
  Future<void> loadSavedPlaces() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.getSavedPlaces();

      if (response.success && response.data != null) {
        state = state.copyWith(savedPlaces: response.data!, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to load places',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Add saved place
  Future<bool> addSavedPlace({
    required String name,
    required String type,
    required Map<String, dynamic> address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.addSavedPlace({
        'name': name,
        'type': type,
        'address': address,
      });

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Place added',
        );
        await loadSavedPlaces(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to add place',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update saved place
  Future<bool> updateSavedPlace({
    required String placeId,
    String? name,
    String? type,
    Map<String, dynamic>? address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (type != null) data['type'] = type;
      if (address != null) data['address'] = address;

      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.updateSavedPlace(placeId, data);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Place updated',
        );
        await loadSavedPlaces(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to update place',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Delete saved place
  Future<bool> deleteSavedPlace(String placeId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.deleteSavedPlace(placeId);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Place deleted',
        );
        await loadSavedPlaces(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to delete place',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Load emergency contacts
  Future<void> loadEmergencyContacts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.getEmergencyContacts();

      if (response.success && response.data != null) {
        state = state.copyWith(
          emergencyContacts: response.data!,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to load contacts',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.addEmergencyContact({
        'name': name,
        'phone': phone,
        'relationship': relationship,
      });

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Contact added',
        );
        await loadEmergencyContacts(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to add contact',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update emergency contact
  Future<bool> updateEmergencyContact({
    required String contactId,
    String? name,
    String? phone,
    String? relationship,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (relationship != null) data['relationship'] = relationship;

      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.updateEmergencyContact(
        contactId,
        data,
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Contact updated',
        );
        await loadEmergencyContacts(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to update contact',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteEmergencyContact(String contactId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.deleteEmergencyContact(contactId);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Contact deleted',
        );
        await loadEmergencyContacts(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to delete contact',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings({
    bool? push,
    bool? sms,
    bool? email,
    bool? rideUpdates,
    bool? promotions,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = <String, dynamic>{};
      if (push != null) data['push'] = push;
      if (sms != null) data['sms'] = sms;
      if (email != null) data['email'] = email;
      if (rideUpdates != null) data['rideUpdates'] = rideUpdates;
      if (promotions != null) data['promotions'] = promotions;

      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.updateNotificationSettings(data);

      if (response.success && response.data != null) {
        // Update user with new preferences
        final updatedUser = state.user?.copyWith(
          notificationPreferences: response.data,
        );
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          successMessage: response.message ?? 'Settings updated',
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to update settings',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update device token
  Future<void> updateDeviceToken(String deviceToken, String deviceType) async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.updateDeviceToken(deviceToken, deviceType);
      // Silent update, no state change needed
    } catch (e) {
      // Log error but don't update state
      print('Error updating device token: $e');
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.resendEmailVerification();

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Verification code sent',
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to send code',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Verify email with OTP
  Future<bool> verifyEmail(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.verifyEmail(otp);

      if (response.success) {
        // Update user verification status
        final updatedUser = state.user?.copyWith(isEmailVerified: true);
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
          successMessage: response.message ?? 'Email verified',
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Invalid OTP',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Load ride history
  Future<void> loadRideHistory({int page = 1, int limit = 10}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.getUserRideHistory(
        page: page,
        limit: limit,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(rideHistory: response.data!, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to load history',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final response = await userRepository.deleteAccount();

      if (response.success) {
        // Clear state
        state = UserState();
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to delete account',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Legacy method - load user profile from cache
  Future<void> loadUserProfile(String userId) async {
    await fetchUserProfile();
  }

  /// Legacy method - update profile
  Future<bool> updateProfile(User updatedUser) async {
    return await updateProfileInfo(
      firstName: updatedUser.firstName,
      lastName: updatedUser.lastName,
      email: updatedUser.email,
    );
  }

  /// Update user location
  Future<void> updateUserLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      if (location != null) {
        state = state.copyWith(currentLocation: location);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
