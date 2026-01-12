import '../../core/constants/constants.dart';
import 'location_model.dart';
import 'driver.dart';

class Ride {
  final String id;
  final String userId;
  final String userName;
  final LocationModel pickupLocation;
  final LocationModel destinationLocation;
  final RideStatus status;
  final double estimatedFare;
  final double? actualFare;
  final double distanceKm;
  final int estimatedDurationMin;
  final Driver? driver;
  final DateTime requestTime;
  final DateTime? acceptTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final PaymentMethod paymentMethod;

  Ride({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.status,
    required this.estimatedFare,
    this.actualFare,
    required this.distanceKm,
    required this.estimatedDurationMin,
    this.driver,
    required this.requestTime,
    this.acceptTime,
    this.startTime,
    this.endTime,
    this.paymentMethod = PaymentMethod.cash,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'status': status.toString(),
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'distanceKm': distanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'driver': driver?.toJson(),
      'requestTime': requestTime.toIso8601String(),
      'acceptTime': acceptTime?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'paymentMethod': paymentMethod.toString(),
    };
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      pickupLocation: LocationModel.fromJson(
        json['pickupLocation'] as Map<String, dynamic>,
      ),
      destinationLocation: LocationModel.fromJson(
        json['destinationLocation'] as Map<String, dynamic>,
      ),
      status: RideStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      actualFare: (json['actualFare'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      estimatedDurationMin: json['estimatedDurationMin'] as int,
      driver: json['driver'] != null
          ? Driver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      requestTime: DateTime.parse(json['requestTime'] as String),
      acceptTime: json['acceptTime'] != null
          ? DateTime.parse(json['acceptTime'] as String)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['paymentMethod'],
      ),
    );
  }

  Ride copyWith({
    String? id,
    String? userId,
    String? userName,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    RideStatus? status,
    double? estimatedFare,
    double? actualFare,
    double? distanceKm,
    int? estimatedDurationMin,
    Driver? driver,
    DateTime? requestTime,
    DateTime? acceptTime,
    DateTime? startTime,
    DateTime? endTime,
    PaymentMethod? paymentMethod,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      status: status ?? this.status,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      driver: driver ?? this.driver,
      requestTime: requestTime ?? this.requestTime,
      acceptTime: acceptTime ?? this.acceptTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
