// Models for Socket.IO event payloads used in ride / delivery matching.

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────

class GeoPoint {
  final String type;
  final List<double> coordinates; // [lng, lat]

  const GeoPoint({this.type = 'Point', required this.coordinates});

  double get longitude => coordinates[0];
  double get latitude => coordinates[1];

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      type: json['type'] as String? ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};
}

class SocketLocation {
  final String address;
  final GeoPoint coordinates;

  const SocketLocation({required this.address, required this.coordinates});

  factory SocketLocation.fromJson(Map<String, dynamic> json) {
    return SocketLocation(
      address: json['address'] as String,
      coordinates: GeoPoint.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'coordinates': coordinates.toJson(),
  };
}

// ─────────────────────────────────────────────────────────────
// ride:new  –  received by DRIVER
// ─────────────────────────────────────────────────────────────

class RideNewFare {
  final double totalFare;

  const RideNewFare({required this.totalFare});

  factory RideNewFare.fromJson(Map<String, dynamic> json) {
    return RideNewFare(totalFare: (json['totalFare'] as num).toDouble());
  }

  Map<String, dynamic> toJson() => {'totalFare': totalFare};
}

class RideNewPackage {
  final String description;
  final String size;
  final bool fragile;

  const RideNewPackage({
    required this.description,
    required this.size,
    required this.fragile,
  });

  factory RideNewPackage.fromJson(Map<String, dynamic> json) {
    return RideNewPackage(
      description: json['description'] as String,
      size: json['size'] as String,
      fragile: json['fragile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'size': size,
    'fragile': fragile,
  };
}

class RideNewEvent {
  final String rideId;
  final String rideNumber;
  final String rideType; // "delivery" | "ride"
  final SocketLocation pickup;
  final SocketLocation dropoff;
  final String vehicleType;
  final RideNewFare fare;
  final int estimatedDistance; // metres
  final int estimatedDuration; // seconds
  final bool isScheduled;
  final RideNewPackage? package;

  const RideNewEvent({
    required this.rideId,
    required this.rideNumber,
    required this.rideType,
    required this.pickup,
    required this.dropoff,
    required this.vehicleType,
    required this.fare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.isScheduled,
    this.package,
  });

  bool get isDelivery => rideType == 'delivery';

  factory RideNewEvent.fromJson(Map<String, dynamic> json) {
    return RideNewEvent(
      rideId: json['rideId'] as String,
      rideNumber: json['rideNumber'] as String,
      rideType: json['rideType'] as String,
      pickup: SocketLocation.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: SocketLocation.fromJson(json['dropoff'] as Map<String, dynamic>),
      vehicleType: json['vehicleType'] as String,
      fare: RideNewFare.fromJson(json['fare'] as Map<String, dynamic>),
      estimatedDistance: json['estimatedDistance'] as int,
      estimatedDuration: json['estimatedDuration'] as int,
      isScheduled: json['isScheduled'] as bool? ?? false,
      package: json['package'] != null
          ? RideNewPackage.fromJson(json['package'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'rideNumber': rideNumber,
    'rideType': rideType,
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'vehicleType': vehicleType,
    'fare': fare.toJson(),
    'estimatedDistance': estimatedDistance,
    'estimatedDuration': estimatedDuration,
    'isScheduled': isScheduled,
    if (package != null) 'package': package!.toJson(),
  };
}

// ─────────────────────────────────────────────────────────────
// ride:matched  –  received by PASSENGER
// ─────────────────────────────────────────────────────────────

class MatchedDriver {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? profilePhoto;
  final double rating;

  const MatchedDriver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profilePhoto,
    required this.rating,
  });

  String get fullName => '$firstName $lastName';

  factory MatchedDriver.fromJson(Map<String, dynamic> json) {
    return MatchedDriver(
      id: json['_id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'profilePhoto': profilePhoto,
    'rating': rating,
  };
}

class MatchedVehicle {
  final String make;
  final String model;
  final String licensePlate;
  final String color;

  const MatchedVehicle({
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.color,
  });

  String get displayName => '$color $make $model';

  factory MatchedVehicle.fromJson(Map<String, dynamic> json) {
    return MatchedVehicle(
      make: json['make'] as String,
      model: json['model'] as String,
      licensePlate: json['licensePlate'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'licensePlate': licensePlate,
    'color': color,
  };
}

class RideMatchedEvent {
  final String rideId;
  final String rideNumber;
  final MatchedDriver driver;
  final MatchedVehicle vehicle;
  final int estimatedArrival; // minutes
  final String message;

  const RideMatchedEvent({
    required this.rideId,
    required this.rideNumber,
    required this.driver,
    required this.vehicle,
    required this.estimatedArrival,
    required this.message,
  });

  factory RideMatchedEvent.fromJson(Map<String, dynamic> json) {
    return RideMatchedEvent(
      rideId: json['rideId'] as String,
      rideNumber: json['rideNumber'] as String,
      driver: MatchedDriver.fromJson(json['driver'] as Map<String, dynamic>),
      vehicle: MatchedVehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      estimatedArrival: json['estimatedArrival'] as int,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'rideNumber': rideNumber,
    'driver': driver.toJson(),
    'vehicle': vehicle.toJson(),
    'estimatedArrival': estimatedArrival,
    'message': message,
  };
}

// ─────────────────────────────────────────────────────────────
// ride:driver_arrived  –  received by PASSENGER
// ─────────────────────────────────────────────────────────────

class RideDriverArrivedEvent {
  final String rideId;
  final String rideNumber;
  final String message;

  const RideDriverArrivedEvent({
    required this.rideId,
    required this.rideNumber,
    required this.message,
  });

  factory RideDriverArrivedEvent.fromJson(Map<String, dynamic> json) {
    return RideDriverArrivedEvent(
      rideId: json['rideId'] as String,
      rideNumber: json['rideNumber'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'rideNumber': rideNumber,
    'message': message,
  };
}

// ─────────────────────────────────────────────────────────────
// delivery:package_picked_up  –  received by PASSENGER
// ─────────────────────────────────────────────────────────────

class DeliveryPackagePickedUpEvent {
  final String deliveryId;
  final String rideNumber;
  final String message;

  const DeliveryPackagePickedUpEvent({
    required this.deliveryId,
    required this.rideNumber,
    required this.message,
  });

  factory DeliveryPackagePickedUpEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryPackagePickedUpEvent(
      deliveryId: json['deliveryId'] as String,
      rideNumber: json['rideNumber'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'deliveryId': deliveryId,
    'rideNumber': rideNumber,
    'message': message,
  };
}

// ─────────────────────────────────────────────────────────────
// delivery:completed  –  received by PASSENGER
// ─────────────────────────────────────────────────────────────

class DeliveryCompletedEvent {
  final String deliveryId;
  final String rideNumber;
  final String? receivedBy;
  final String message;

  const DeliveryCompletedEvent({
    required this.deliveryId,
    required this.rideNumber,
    this.receivedBy,
    required this.message,
  });

  factory DeliveryCompletedEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryCompletedEvent(
      deliveryId: json['deliveryId'] as String,
      rideNumber: json['rideNumber'] as String,
      receivedBy: json['receivedBy'] as String?,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'deliveryId': deliveryId,
    'rideNumber': rideNumber,
    if (receivedBy != null) 'receivedBy': receivedBy,
    'message': message,
  };
}

// ─────────────────────────────────────────────────────────────
// ride:cancelled  –  received by DRIVER (user cancelled)
// ─────────────────────────────────────────────────────────────

class RideCancelledEvent {
  final String rideId;
  final String rideNumber;
  final String message;

  const RideCancelledEvent({
    required this.rideId,
    required this.rideNumber,
    required this.message,
  });

  factory RideCancelledEvent.fromJson(Map<String, dynamic> json) {
    return RideCancelledEvent(
      rideId: json['rideId'] as String,
      rideNumber: json['rideNumber'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'rideNumber': rideNumber,
    'message': message,
  };
}
