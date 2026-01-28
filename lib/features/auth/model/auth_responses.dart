import 'package:equatable/equatable.dart';
import '../../../data/models/user.dart';
import 'auth_requests.dart';

/// Response model for OTP request (sign-in)
class SignInResponse extends Equatable {
  final String message;
  final String phone;

  const SignInResponse({required this.message, required this.phone});

  factory SignInResponse.fromJson(Map<String, dynamic> json) {
    return SignInResponse(
      message: json['message'] as String? ?? 'OTP sent successfully',
      phone: json['phone'] as String,
    );
  }

  @override
  List<Object?> get props => [message, phone];
}

/// Response model for OTP verification
class VerifyOtpResponse extends Equatable {
  final String token;
  final String refreshToken;
  final ProfileStatus profileStatus;
  final User user;

  const VerifyOtpResponse({
    required this.token,
    required this.refreshToken,
    required this.profileStatus,
    required this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      profileStatus: ProfileStatus.fromString(json['profileStatus'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, profileStatus, user];
}

/// Response model for Google Sign-In (Step 1)
class GoogleSignInResponse extends Equatable {
  final bool requiresPhoneVerification;
  final GoogleData googleData;

  const GoogleSignInResponse({
    required this.requiresPhoneVerification,
    required this.googleData,
  });

  factory GoogleSignInResponse.fromJson(Map<String, dynamic> json) {
    return GoogleSignInResponse(
      requiresPhoneVerification: json['requiresPhoneVerification'] as bool,
      googleData: GoogleData(
        googleId: json['googleId'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        profileImage: json['profileImage'] as String?,
      ),
    );
  }

  @override
  List<Object?> get props => [requiresPhoneVerification, googleData];
}

/// Response model for Google Sign-In completion
class GoogleCompleteResponse extends Equatable {
  final String token;
  final String refreshToken;
  final ProfileStatus profileStatus;
  final User user;

  const GoogleCompleteResponse({
    required this.token,
    required this.refreshToken,
    required this.profileStatus,
    required this.user,
  });

  factory GoogleCompleteResponse.fromJson(Map<String, dynamic> json) {
    return GoogleCompleteResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      profileStatus: ProfileStatus.fromString(json['profileStatus'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, profileStatus, user];
}

/// Response model for token refresh
class RefreshTokenResponse extends Equatable {
  final String token;
  final String refreshToken;

  const RefreshTokenResponse({required this.token, required this.refreshToken});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken];
}

/// Profile completion status
enum ProfileStatus {
  incomplete,
  complete;

  static ProfileStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'complete':
        return ProfileStatus.complete;
      case 'incomplete':
      default:
        return ProfileStatus.incomplete;
    }
  }

  bool get isComplete => this == ProfileStatus.complete;
  bool get isIncomplete => this == ProfileStatus.incomplete;
}
