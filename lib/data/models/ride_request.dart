import 'location_model.dart';

class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final LocationModel pickupLocation;
  final LocationModel destinationLocation;
  final double estimatedFare;
  final double distanceKm;
  final int estimatedDurationMin;
  final DateTime requestTime;
  final bool isAccepted;
  final String? acceptedByDriverId;

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.estimatedFare,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.requestTime,
    this.isAccepted = false,
    this.acceptedByDriverId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'estimatedFare': estimatedFare,
      'distanceKm': distanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'requestTime': requestTime.toIso8601String(),
      'isAccepted': isAccepted,
      'acceptedByDriverId': acceptedByDriverId,
    };
  }

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      pickupLocation: LocationModel.fromJson(
        json['pickupLocation'] as Map<String, dynamic>,
      ),
      destinationLocation: LocationModel.fromJson(
        json['destinationLocation'] as Map<String, dynamic>,
      ),
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      estimatedDurationMin: json['estimatedDurationMin'] as int,
      requestTime: DateTime.parse(json['requestTime'] as String),
      isAccepted: json['isAccepted'] as bool? ?? false,
      acceptedByDriverId: json['acceptedByDriverId'] as String?,
    );
  }

  RideRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    double? estimatedFare,
    double? distanceKm,
    int? estimatedDurationMin,
    DateTime? requestTime,
    bool? isAccepted,
    String? acceptedByDriverId,
  }) {
    return RideRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      requestTime: requestTime ?? this.requestTime,
      isAccepted: isAccepted ?? this.isAccepted,
      acceptedByDriverId: acceptedByDriverId ?? this.acceptedByDriverId,
    );
  }
}
