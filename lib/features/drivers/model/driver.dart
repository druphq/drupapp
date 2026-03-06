import '../../passenger/model/location_model.dart';
import 'vehicle.dart';

/// Driver rating info from API
class DriverRating {
  final double average;
  final int count;

  DriverRating({this.average = 5.0, this.count = 0});

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      average: (json['average'] as num?)?.toDouble() ?? 5.0,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'average': average, 'count': count};

  DriverRating copyWith({double? average, int? count}) {
    return DriverRating(
      average: average ?? this.average,
      count: count ?? this.count,
    );
  }
}

/// Driver ride stats from API
class DriverStats {
  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final int acceptanceRate;

  DriverStats({
    this.totalRides = 0,
    this.completedRides = 0,
    this.cancelledRides = 0,
    this.acceptanceRate = 0,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      totalRides: json['totalRides'] as int? ?? 0,
      completedRides: json['completedRides'] as int? ?? 0,
      cancelledRides: json['cancelledRides'] as int? ?? 0,
      acceptanceRate: json['acceptanceRate'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalRides': totalRides,
    'completedRides': completedRides,
    'cancelledRides': cancelledRides,
    'acceptanceRate': acceptanceRate,
  };

  DriverStats copyWith({
    int? totalRides,
    int? completedRides,
    int? cancelledRides,
    int? acceptanceRate,
  }) {
    return DriverStats(
      totalRides: totalRides ?? this.totalRides,
      completedRides: completedRides ?? this.completedRides,
      cancelledRides: cancelledRides ?? this.cancelledRides,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
    );
  }
}

/// Driver earnings from API
class DriverEarnings {
  final double total;
  final double currentWeek;
  final double pendingPayout;

  DriverEarnings({
    this.total = 0,
    this.currentWeek = 0,
    this.pendingPayout = 0,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currentWeek: (json['currentWeek'] as num?)?.toDouble() ?? 0,
      pendingPayout: (json['pendingPayout'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'currentWeek': currentWeek,
    'pendingPayout': pendingPayout,
  };

  DriverEarnings copyWith({
    double? total,
    double? currentWeek,
    double? pendingPayout,
  }) {
    return DriverEarnings(
      total: total ?? this.total,
      currentWeek: currentWeek ?? this.currentWeek,
      pendingPayout: pendingPayout ?? this.pendingPayout,
    );
  }
}

class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? dateOfBirth;
  final String? profilePhoto;
  final String? status;
  final String? profileStatus;
  final bool isOnline;
  final bool isOnRide;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final Vehicle? vehicle;
  final DriverRating rating;
  final DriverStats stats;
  final DriverEarnings earnings;
  final LocationModel? currentLocation;
  final List<dynamic> documents;
  final DateTime? createdAt;

  Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.dateOfBirth,
    this.profilePhoto,
    this.status,
    this.profileStatus,
    this.isOnline = false,
    this.isOnRide = false,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.vehicle,
    DriverRating? rating,
    DriverStats? stats,
    DriverEarnings? earnings,
    this.currentLocation,
    this.documents = const [],
    this.createdAt,
  }) : rating = rating ?? DriverRating(),
       stats = stats ?? DriverStats(),
       earnings = earnings ?? DriverEarnings();

  /// Full name: "Dubem Harrison"
  String get fullName => '$firstName $lastName';

  /// Whether the driver is active and can go online
  bool get isActive => status == 'active';

  /// Whether profile is complete
  bool get isProfileComplete => profileStatus == 'complete';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'profilePhoto': profilePhoto,
      'status': status,
      'profileStatus': profileStatus,
      'isOnline': isOnline,
      'isOnRide': isOnRide,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'vehicle': vehicle?.toJson(),
      'rating': rating.toJson(),
      'stats': stats.toJson(),
      'earnings': earnings.toJson(),
      'currentLocation': currentLocation?.toJson(),
      'documents': documents,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Handle currentLocation which may be GeoJSON format from API
    LocationModel? location;
    if (json['currentLocation'] != null) {
      final locData = json['currentLocation'] as Map<String, dynamic>;
      if (locData.containsKey('coordinates')) {
        // GeoJSON format: { type: "Point", coordinates: [lng, lat] }
        final coords = locData['coordinates'] as List<dynamic>?;
        if (coords != null && coords.length >= 2) {
          location = LocationModel(
            latitude: (coords[1] as num).toDouble(),
            longitude: (coords[0] as num).toDouble(),
          );
        }
      } else {
        location = LocationModel.fromJson(locData);
      }
    }

    return Driver(
      id: (json['id'] ?? json['_id']) as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      status: json['status'] as String?,
      profileStatus: json['profileStatus'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      isOnRide: json['isOnRide'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      rating: json['rating'] != null && json['rating'] is Map
          ? DriverRating.fromJson(json['rating'] as Map<String, dynamic>)
          : DriverRating(average: (json['rating'] as num?)?.toDouble() ?? 5.0),
      stats: json['stats'] != null
          ? DriverStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      earnings: json['earnings'] != null
          ? DriverEarnings.fromJson(json['earnings'] as Map<String, dynamic>)
          : null,
      currentLocation: location,
      documents: json['documents'] as List<dynamic>? ?? const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Driver copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? dateOfBirth,
    String? profilePhoto,
    String? status,
    String? profileStatus,
    bool? isOnline,
    bool? isOnRide,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    Vehicle? vehicle,
    DriverRating? rating,
    DriverStats? stats,
    DriverEarnings? earnings,
    LocationModel? currentLocation,
    List<dynamic>? documents,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      status: status ?? this.status,
      profileStatus: profileStatus ?? this.profileStatus,
      isOnline: isOnline ?? this.isOnline,
      isOnRide: isOnRide ?? this.isOnRide,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      vehicle: vehicle ?? this.vehicle,
      rating: rating ?? this.rating,
      stats: stats ?? this.stats,
      earnings: earnings ?? this.earnings,
      currentLocation: currentLocation ?? this.currentLocation,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
