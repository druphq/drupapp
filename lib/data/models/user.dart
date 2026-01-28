import 'package:equatable/equatable.dart';

/// User type enumeration
enum UserType {
  rider,
  driver;

  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'driver':
        return UserType.driver;
      case 'rider':
      default:
        return UserType.rider;
    }
  }
}

/// User model matching API response
class User extends Equatable {
  final String id;
  final String phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String? profileImage;
  final String? googleId;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final UserStatus status;
  final ProfileCompletionStatus profileStatus;
  final UserType userType;
  final List<SavedPlace> savedPlaces;
  final List<EmergencyContact> emergencyContacts;
  final NotificationPreferences notificationPreferences;
  final Wallet wallet;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.fullName = '',
    this.profileImage,
    this.googleId,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.status = UserStatus.active,
    this.profileStatus = ProfileCompletionStatus.incomplete,
    this.userType = UserType.rider,
    this.savedPlaces = const [],
    this.emergencyContacts = const [],
    this.notificationPreferences = const NotificationPreferences(),
    this.wallet = const Wallet(),
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create User from API JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      fullName: json['fullName'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      googleId: json['googleId'] as String?,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      status: UserStatus.fromString(json['status'] as String? ?? 'active'),
      profileStatus: ProfileCompletionStatus.fromString(
        json['profileStatus'] as String? ?? 'incomplete',
      ),
      userType: UserType.fromString(json['userType'] as String? ?? 'rider'),
      savedPlaces:
          (json['savedPlaces'] as List<dynamic>?)
              ?.map((e) => SavedPlace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      emergencyContacts:
          (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>,
            )
          : const NotificationPreferences(),
      wallet: json['wallet'] != null
          ? Wallet.fromJson(json['wallet'] as Map<String, dynamic>)
          : const Wallet(),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'profileImage': profileImage,
      'googleId': googleId,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'status': status.name,
      'profileStatus': profileStatus.name,
      'userType': userType.name,
      'savedPlaces': savedPlaces.map((e) => e.toJson()).toList(),
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'notificationPreferences': notificationPreferences.toJson(),
      'wallet': wallet.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    String? profileImage,
    String? googleId,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    UserStatus? status,
    ProfileCompletionStatus? profileStatus,
    UserType? userType,
    List<SavedPlace>? savedPlaces,
    List<EmergencyContact>? emergencyContacts,
    NotificationPreferences? notificationPreferences,
    Wallet? wallet,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      googleId: googleId ?? this.googleId,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      status: status ?? this.status,
      profileStatus: profileStatus ?? this.profileStatus,
      userType: userType ?? this.userType,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      wallet: wallet ?? this.wallet,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if profile is complete
  bool get isProfileComplete =>
      profileStatus == ProfileCompletionStatus.complete;

  /// Get display name
  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return phone;
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    email,
    firstName,
    lastName,
    fullName,
    profileImage,
    googleId,
    isPhoneVerified,
    isEmailVerified,
    status,
    profileStatus,
    userType,
    savedPlaces,
    emergencyContacts,
    notificationPreferences,
    wallet,
    createdAt,
    updatedAt,
  ];
}

/// User account status
enum UserStatus {
  active,
  suspended,
  deactivated;

  static UserStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'suspended':
        return UserStatus.suspended;
      case 'deactivated':
        return UserStatus.deactivated;
      case 'active':
      default:
        return UserStatus.active;
    }
  }
}

/// Profile completion status
enum ProfileCompletionStatus {
  incomplete,
  complete;

  static ProfileCompletionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'complete':
        return ProfileCompletionStatus.complete;
      case 'incomplete':
      default:
        return ProfileCompletionStatus.incomplete;
    }
  }
}

/// Saved place model
class SavedPlace extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final SavedPlaceType type;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.type = SavedPlaceType.other,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: SavedPlaceType.fromString(json['type'] as String? ?? 'other'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'type': type.name,
  };

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, type];
}

/// Saved place type
enum SavedPlaceType {
  home,
  work,
  other;

  static SavedPlaceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'home':
        return SavedPlaceType.home;
      case 'work':
        return SavedPlaceType.work;
      case 'other':
      default:
        return SavedPlaceType.other;
    }
  }
}

/// Emergency contact model
class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? relationship;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    if (relationship != null) 'relationship': relationship,
  };

  @override
  List<Object?> get props => [id, name, phone, relationship];
}

/// Notification preferences model
class NotificationPreferences extends Equatable {
  final bool push;
  final bool sms;
  final bool email;
  final bool rideUpdates;
  final bool promotions;

  const NotificationPreferences({
    this.push = true,
    this.sms = true,
    this.email = true,
    this.rideUpdates = true,
    this.promotions = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      push: json['push'] as bool? ?? true,
      sms: json['sms'] as bool? ?? true,
      email: json['email'] as bool? ?? true,
      rideUpdates: json['rideUpdates'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'push': push,
    'sms': sms,
    'email': email,
    'rideUpdates': rideUpdates,
    'promotions': promotions,
  };

  @override
  List<Object?> get props => [push, sms, email, rideUpdates, promotions];
}

/// Wallet model
class Wallet extends Equatable {
  final double balance;
  final List<WalletTransaction> transactions;

  const Wallet({this.balance = 0, this.transactions = const []});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map(
                (e) => WalletTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'transactions': transactions.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [balance, transactions];
}

/// Wallet transaction model
class WalletTransaction extends Equatable {
  final String id;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.fromString(json['type'] as String),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.name,
    if (description != null) 'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, amount, type, description, createdAt];
}

/// Transaction type
enum TransactionType {
  credit,
  debit;

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
      default:
        return TransactionType.debit;
    }
  }
}
