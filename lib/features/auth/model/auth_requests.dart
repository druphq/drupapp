import 'package:equatable/equatable.dart';

/// Request model for phone sign-in (OTP request)
class SignInRequest extends Equatable {
  final String phoneNumber;

  const SignInRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};

  @override
  List<Object?> get props => [phoneNumber];
}

/// Request model for OTP verification
class VerifyOtpRequest extends Equatable {
  final String phoneNumber;
  final String otp;
  final String? deviceToken;

  const VerifyOtpRequest({
    required this.phoneNumber,
    required this.otp,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
    'otp': otp,
    if (deviceToken != null) 'deviceToken': deviceToken,
  };

  @override
  List<Object?> get props => [phoneNumber, otp, deviceToken];
}

/// Request model for Google Sign-In (Step 1)
class GoogleSignInRequest extends Equatable {
  final String idToken;
  final String? deviceToken;

  const GoogleSignInRequest({required this.idToken, this.deviceToken});

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    if (deviceToken != null) 'deviceToken': deviceToken,
  };

  @override
  List<Object?> get props => [idToken, deviceToken];
}

/// Google data received from Step 1
class GoogleData extends Equatable {
  final String googleId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;

  const GoogleData({
    required this.googleId,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
  });

  factory GoogleData.fromJson(Map<String, dynamic> json) {
    return GoogleData(
      googleId: json['googleId'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'googleId': googleId,
    'email': email,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (profileImage != null) 'profileImage': profileImage,
  };

  @override
  List<Object?> get props => [
    googleId,
    email,
    firstName,
    lastName,
    profileImage,
  ];
}

/// Request model for Google Sign-In completion (Step 2)
class GoogleCompleteRequest extends Equatable {
  final String phoneNumber;
  final String otp;
  final GoogleData googleData;
  final String? deviceToken;

  const GoogleCompleteRequest({
    required this.phoneNumber,
    required this.otp,
    required this.googleData,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
    'otp': otp,
    'googleData': googleData.toJson(),
    if (deviceToken != null) 'deviceToken': deviceToken,
  };

  @override
  List<Object?> get props => [phoneNumber, otp, googleData, deviceToken];
}

/// Request model for token refresh
class RefreshTokenRequest extends Equatable {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};

  @override
  List<Object?> get props => [refreshToken];
}

/// Request model for logout
class LogoutRequest extends Equatable {
  final String refreshToken;

  const LogoutRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};

  @override
  List<Object?> get props => [refreshToken];
}
