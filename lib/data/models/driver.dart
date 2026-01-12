import 'location_model.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleModel;
  final String vehicleNumber;
  final String? photoUrl;
  final double rating;
  final int totalRides;
  final bool isAvailable;
  final LocationModel? currentLocation;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleModel,
    required this.vehicleNumber,
    this.photoUrl,
    this.rating = 5.0,
    this.totalRides = 0,
    this.isAvailable = true,
    this.currentLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'photoUrl': photoUrl,
      'rating': rating,
      'totalRides': totalRides,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation?.toJson(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      vehicleModel: json['vehicleModel'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      photoUrl: json['photoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: json['totalRides'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      currentLocation: json['currentLocation'] != null
          ? LocationModel.fromJson(
              json['currentLocation'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicleModel,
    String? vehicleNumber,
    String? photoUrl,
    double? rating,
    int? totalRides,
    bool? isAvailable,
    LocationModel? currentLocation,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
