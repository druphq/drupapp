import 'package:equatable/equatable.dart';
import 'ride_api_models.dart';

// ============================================================================
// DELIVERY FARE ESTIMATE MODELS
// ============================================================================

/// Request model for delivery fare estimate
class DeliveryEstimateRequest extends Equatable {
  final RideLocation pickup;
  final RideLocation dropoff;
  final String vehicleType;
  final String? packageSize;

  const DeliveryEstimateRequest({
    required this.pickup,
    required this.dropoff,
    required this.vehicleType,
    this.packageSize,
  });

  Map<String, dynamic> toJson() => {
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'vehicleType': vehicleType,
    if (packageSize != null) 'packageSize': packageSize,
  };

  @override
  List<Object?> get props => [pickup, dropoff, vehicleType, packageSize];
}

/// Fare breakdown for deliveries (extends ride fare with packageSurcharge)
class DeliveryFareDetails extends Equatable {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgePricing;
  final double surgeMultiplier;
  final double discount;
  final double packageSurcharge;
  final double serviceFee;
  final double tax;
  final double tip;
  final double totalFare;

  const DeliveryFareDetails({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgePricing,
    required this.surgeMultiplier,
    required this.discount,
    required this.packageSurcharge,
    required this.serviceFee,
    required this.tax,
    required this.tip,
    required this.totalFare,
  });

  factory DeliveryFareDetails.fromJson(Map<String, dynamic> json) {
    return DeliveryFareDetails(
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0,
      distanceFare: (json['distanceFare'] as num?)?.toDouble() ?? 0,
      timeFare: (json['timeFare'] as num?)?.toDouble() ?? 0,
      surgePricing: (json['surgePricing'] as num?)?.toDouble() ?? 0,
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      packageSurcharge: (json['packageSurcharge'] as num?)?.toDouble() ?? 0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      totalFare: (json['totalFare'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    baseFare,
    distanceFare,
    timeFare,
    surgePricing,
    surgeMultiplier,
    discount,
    packageSurcharge,
    serviceFee,
    tax,
    tip,
    totalFare,
  ];
}

/// Single delivery estimate
class DeliveryEstimate extends Equatable {
  final int estimatedDistance; // metres
  final int estimatedDuration; // seconds
  final DeliveryFareDetails fare;
  final String vehicleType;
  final String packageSize;

  const DeliveryEstimate({
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.fare,
    required this.vehicleType,
    required this.packageSize,
  });

  factory DeliveryEstimate.fromJson(Map<String, dynamic> json) {
    return DeliveryEstimate(
      estimatedDistance: json['estimatedDistance'] as int? ?? 0,
      estimatedDuration: json['estimatedDuration'] as int? ?? 0,
      fare: DeliveryFareDetails.fromJson(json['fare'] as Map<String, dynamic>),
      vehicleType: json['vehicleType'] as String? ?? '',
      packageSize: json['packageSize'] as String? ?? 'small',
    );
  }

  /// Distance in km
  double get distanceKm => estimatedDistance / 1000;

  /// Duration in minutes
  int get durationMinutes => (estimatedDuration / 60).ceil();

  @override
  List<Object?> get props => [
    estimatedDistance,
    estimatedDuration,
    fare,
    vehicleType,
    packageSize,
  ];
}

/// Response for delivery fare estimate
class DeliveryEstimateResponse extends Equatable {
  final DeliveryEstimate estimate;

  const DeliveryEstimateResponse({required this.estimate});

  factory DeliveryEstimateResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryEstimateResponse(
      estimate: DeliveryEstimate.fromJson(
        json['estimate'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [estimate];
}

// ============================================================================
// BOOK DELIVERY MODELS
// ============================================================================

/// Recipient information
class DeliveryRecipient extends Equatable {
  final String name;
  final String phone;
  final String? alternatePhone;
  final String? notes;

  const DeliveryRecipient({
    required this.name,
    required this.phone,
    this.alternatePhone,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    if (alternatePhone != null) 'alternatePhone': alternatePhone,
    if (notes != null) 'notes': notes,
  };

  factory DeliveryRecipient.fromJson(Map<String, dynamic> json) {
    return DeliveryRecipient(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      alternatePhone: json['alternatePhone'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, phone, alternatePhone, notes];
}

/// Package information
class DeliveryPackage extends Equatable {
  final String description;
  final String? size;
  final double? weight;
  final int? quantity;
  final bool fragile;

  const DeliveryPackage({
    required this.description,
    this.size,
    this.weight,
    this.quantity,
    this.fragile = false,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    if (size != null) 'size': size,
    if (weight != null) 'weight': weight,
    if (quantity != null) 'quantity': quantity,
    'fragile': fragile,
  };

  factory DeliveryPackage.fromJson(Map<String, dynamic> json) {
    return DeliveryPackage(
      description: json['description'] as String? ?? '',
      size: json['size'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      quantity: json['quantity'] as int?,
      fragile: json['fragile'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [description, size, weight, quantity, fragile];
}

/// Request model for booking a delivery
class BookDeliveryRequest extends Equatable {
  final RideLocation pickup;
  final RideLocation dropoff;
  final String vehicleType;
  final DeliveryRecipient recipient;
  final DeliveryPackage package;
  final DateTime? scheduledTime;
  final String? paymentMethod;
  final String? userNotes;

  const BookDeliveryRequest({
    required this.pickup,
    required this.dropoff,
    required this.vehicleType,
    required this.recipient,
    required this.package,
    this.scheduledTime,
    this.paymentMethod,
    this.userNotes,
  });

  Map<String, dynamic> toJson() => {
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'vehicleType': vehicleType,
    'recipient': recipient.toJson(),
    'package': package.toJson(),
    'rideType': 'delivery',
    if (scheduledTime != null)
      'scheduledTime': scheduledTime!.toUtc().toIso8601String(),
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (userNotes != null) 'userNotes': userNotes,
  };

  @override
  List<Object?> get props => [
    pickup,
    dropoff,
    vehicleType,
    recipient,
    package,
    scheduledTime,
    paymentMethod,
    userNotes,
  ];
}

/// Booked delivery details (response)
class BookedDelivery extends Equatable {
  final String id;
  final String rideNumber;
  final String rideType;
  final String? userId;
  final String vehicleType;
  final RideLocation pickup;
  final RideLocation dropoff;
  final DeliveryRecipient recipient;
  final DeliveryPackage package;
  final String deliveryCode;
  final int estimatedDistance;
  final int estimatedDuration;
  final DeliveryFareDetails fare;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? userNotes;
  final DateTime bookedAt;
  final DateTime createdAt;

  const BookedDelivery({
    required this.id,
    required this.rideNumber,
    required this.rideType,
    this.userId,
    required this.vehicleType,
    required this.pickup,
    required this.dropoff,
    required this.recipient,
    required this.package,
    required this.deliveryCode,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.fare,
    required this.isScheduled,
    this.scheduledTime,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.userNotes,
    required this.bookedAt,
    required this.createdAt,
  });

  factory BookedDelivery.fromJson(Map<String, dynamic> json) {
    return BookedDelivery(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      rideNumber: json['rideNumber'] as String? ?? '',
      rideType: json['rideType'] as String? ?? 'delivery',
      userId: json['user'] as String?,
      vehicleType: json['vehicleType'] as String? ?? '',
      pickup: RideLocation.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: RideLocation.fromJson(json['dropoff'] as Map<String, dynamic>),
      recipient: DeliveryRecipient.fromJson(
        json['recipient'] as Map<String, dynamic>,
      ),
      package: DeliveryPackage.fromJson(
        json['package'] as Map<String, dynamic>,
      ),
      deliveryCode: json['deliveryCode'] as String? ?? '',
      estimatedDistance: json['estimatedDistance'] as int? ?? 0,
      estimatedDuration: json['estimatedDuration'] as int? ?? 0,
      fare: DeliveryFareDetails.fromJson(json['fare'] as Map<String, dynamic>),
      isScheduled: json['isScheduled'] as bool? ?? false,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      status: json['status'] as String? ?? 'booked',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      userNotes: json['userNotes'] as String?,
      bookedAt: json['bookedAt'] != null
          ? DateTime.parse(json['bookedAt'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Distance in km
  double get distanceKm => estimatedDistance / 1000;

  /// Duration in minutes
  int get durationMinutes => (estimatedDuration / 60).ceil();

  @override
  List<Object?> get props => [
    id,
    rideNumber,
    rideType,
    userId,
    vehicleType,
    pickup,
    dropoff,
    recipient,
    package,
    deliveryCode,
    estimatedDistance,
    estimatedDuration,
    fare,
    isScheduled,
    scheduledTime,
    status,
    paymentStatus,
    paymentMethod,
    userNotes,
    bookedAt,
    createdAt,
  ];
}

/// Response model for booking a delivery
class BookDeliveryResponse extends Equatable {
  final BookedDelivery delivery;

  const BookDeliveryResponse({required this.delivery});

  factory BookDeliveryResponse.fromJson(Map<String, dynamic> json) {
    return BookDeliveryResponse(
      delivery: BookedDelivery.fromJson(
        json['delivery'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [delivery];
}
