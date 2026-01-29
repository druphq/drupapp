import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../api/api_routes.dart';
import '../services/api_service.dart';
import '../../features/auth/repository/auth_repository.dart';

/// Repository for user-related operations
/// Uses AuthRepository for user data management and caching
class UserRepository {
  final AuthRepository _authRepo;
  final ApiService _apiService;

  UserRepository({AuthRepository? authRepository, ApiService? apiService})
    : _authRepo = authRepository ?? AuthRepository(),
      _apiService = apiService ?? ApiService();

  /// Get current user from cache
  Future<User?> getCurrentUser() async {
    return await _authRepo.getCurrentUser();
  }

  /// Fetch user profile from API and update cache
  /// Returns updated User object
  Future<ApiResponse<User>> getUserProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.userProfile,
      );

      if (response.success && response.data != null) {
        final userData =
            response.data!['data']?['user'] as Map<String, dynamic>?;

        if (userData != null) {
          final user = User.fromJson(userData);
          // Cache the updated user
          await _authRepo.updateCachedUser(user);

          return ApiResponse.success(
            data: user,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch profile',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update user profile via API
  /// Updates firstName, lastName, email, dateOfBirth
  Future<ApiResponse<User>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (email != null) data['email'] = email;
      if (dateOfBirth != null)
        data['dateOfBirth'] = dateOfBirth.toIso8601String();

      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.updateProfile,
        data: data,
      );

      if (response.success && response.data != null) {
        final userData =
            response.data!['data']?['user'] as Map<String, dynamic>?;

        if (userData != null) {
          // Get current user and update with new data
          final currentUser = await _authRepo.getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(
              firstName: userData['firstName'] as String?,
              lastName: userData['lastName'] as String?,
              email: userData['email'] as String?,
              isEmailVerified:
                  userData['isEmailVerified'] as bool? ??
                  currentUser.isEmailVerified,
            );

            // Cache the updated user
            await _authRepo.updateCachedUser(updatedUser);

            return ApiResponse.success(
              data: updatedUser,
              message: response.message,
              statusCode: response.statusCode,
            );
          }
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update profile',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Upload profile photo
  Future<ApiResponse<String>> uploadProfilePhoto(File photoFile) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoFile.path),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.uploadProfilePhoto,
        data: formData,
      );

      if (response.success && response.data != null) {
        final profilePhoto =
            response.data!['data']?['user']?['profilePhoto']
                as Map<String, dynamic>?;
        final photoUrl = profilePhoto?['url'] as String?;

        if (photoUrl != null) {
          // Update cached user with new photo URL
          final currentUser = await _authRepo.getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(profileImage: photoUrl);
            await _authRepo.updateCachedUser(updatedUser);
          }

          return ApiResponse.success(
            data: photoUrl,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to upload photo',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return ApiResponse.failure(message: e.toString());
    }
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

  /// Get saved places
  Future<ApiResponse<List<SavedPlace>>> getSavedPlaces() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.savedPlaces,
      );

      if (response.success && response.data != null) {
        final placesData = response.data!['data']?['places'] as List<dynamic>?;

        if (placesData != null) {
          final places = placesData
              .map((e) => SavedPlace.fromJson(e as Map<String, dynamic>))
              .toList();

          // Update cached user with places
          final currentUser = await _authRepo.getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(savedPlaces: places);
            await _authRepo.updateCachedUser(updatedUser);
          }

          return ApiResponse.success(
            data: places,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch saved places',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching saved places: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Add saved place
  Future<ApiResponse<SavedPlace>> addSavedPlace(
    Map<String, dynamic> placeData,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.savedPlaces,
        data: placeData,
      );

      if (response.success) {
        // Refresh saved places
        await getSavedPlaces();

        return ApiResponse.success(
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to add place',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error adding saved place: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update saved place
  Future<ApiResponse<void>> updateSavedPlace(
    String placeId,
    Map<String, dynamic> placeData,
  ) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.savedPlace(placeId),
        data: placeData,
      );

      if (response.success) {
        // Refresh saved places
        await getSavedPlaces();

        return ApiResponse.success(
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update place',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating saved place: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Delete saved place
  Future<ApiResponse<void>> deleteSavedPlace(String placeId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiRoutes.savedPlace(placeId),
      );

      if (response.success) {
        // Refresh saved places
        await getSavedPlaces();

        return ApiResponse.success(
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to delete place',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error deleting saved place: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Get emergency contacts
  Future<ApiResponse<List<EmergencyContact>>> getEmergencyContacts() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.emergencyContacts,
      );

      if (response.success && response.data != null) {
        final contactsData =
            response.data!['data']?['contacts'] as List<dynamic>?;

        if (contactsData != null) {
          final contacts = contactsData
              .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList();

          // Update cached user
          final currentUser = await _authRepo.getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(
              emergencyContacts: contacts,
            );
            await _authRepo.updateCachedUser(updatedUser);
          }

          return ApiResponse.success(
            data: contacts,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch contacts',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching emergency contacts: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Add emergency contact
  Future<ApiResponse<void>> addEmergencyContact(
    Map<String, dynamic> contactData,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.emergencyContacts,
        data: contactData,
      );

      if (response.success) {
        await getEmergencyContacts();
        return ApiResponse.success(message: response.message);
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to add contact',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update emergency contact
  Future<ApiResponse<void>> updateEmergencyContact(
    String contactId,
    Map<String, dynamic> contactData,
  ) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.emergencyContact(contactId),
        data: contactData,
      );

      if (response.success) {
        await getEmergencyContacts();
        return ApiResponse.success(message: response.message);
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update contact',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Delete emergency contact
  Future<ApiResponse<void>> deleteEmergencyContact(String contactId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiRoutes.emergencyContact(contactId),
      );

      if (response.success) {
        await getEmergencyContacts();
        return ApiResponse.success(message: response.message);
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to delete contact',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update notification settings
  Future<ApiResponse<NotificationPreferences>> updateNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.notificationSettings,
        data: settings,
      );

      if (response.success && response.data != null) {
        final prefsData =
            response.data!['data']?['preferences'] as Map<String, dynamic>?;

        if (prefsData != null) {
          final prefs = NotificationPreferences.fromJson(prefsData);

          // Update cached user
          final currentUser = await _authRepo.getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(
              notificationPreferences: prefs,
            );
            await _authRepo.updateCachedUser(updatedUser);
          }

          return ApiResponse.success(
            data: prefs,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update settings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update device token for push notifications
  Future<ApiResponse<void>> updateDeviceToken(
    String deviceToken,
    String deviceType,
  ) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.deviceToken,
        data: {'deviceToken': deviceToken, 'deviceType': deviceType},
      );

      return response.success
          ? ApiResponse.success(message: response.message)
          : ApiResponse.failure(
              message: response.message ?? 'Failed to update token',
            );
    } catch (e) {
      debugPrint('Error updating device token: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Resend email verification OTP
  Future<ApiResponse<void>> resendEmailVerification() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.resendEmailVerification,
      );

      return response.success
          ? ApiResponse.success(message: response.message)
          : ApiResponse.failure(
              message: response.message ?? 'Failed to resend OTP',
            );
    } catch (e) {
      debugPrint('Error resending email verification: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Verify email with OTP
  Future<ApiResponse<void>> verifyEmail(String otp) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.verifyEmail,
        data: {'otp': otp},
      );

      if (response.success) {
        // Update cached user email verification status
        final currentUser = await _authRepo.getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(isEmailVerified: true);
          await _authRepo.updateCachedUser(updatedUser);
        }

        return ApiResponse.success(message: response.message);
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to verify email',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error verifying email: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Get user ride history
  Future<ApiResponse<List<dynamic>>> getUserRideHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.userRides,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.success && response.data != null) {
        final ridesData = response.data!['data']?['rides'] as List<dynamic>?;

        return ApiResponse.success(
          data: ridesData ?? [],
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch ride history',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching ride history: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Delete user account (permanent)
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiRoutes.deleteAccount,
      );

      if (response.success) {
        // Clear all local data
        await _authRepo.logout();

        return ApiResponse.success(message: response.message);
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to delete account',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }
}
