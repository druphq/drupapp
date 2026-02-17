import 'package:equatable/equatable.dart';

// ============================================================================
// LOCATION MODELS
// ============================================================================

/// Location object for ride requests
class RideLocation extends Equatable {
  final String name;
  final String address;
  final RideCoordinates coordinates;
  final String? placeId;
  ////////////////
  String? city = '';
  String? state = '';

  RideLocation({
    required this.address,
    required this.name,
    required this.coordinates,
    this.placeId,
  }) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      city = parts[0];
      state = parts[1];
    } else if (parts.isNotEmpty) {
      city = parts[0];
      state = '';
    }
  }

  Map<String, dynamic> toJson() => {
    'address': name,
    'coordinates': coordinates.toJson(),
    if (placeId != null) 'placeId': placeId,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
  };

  factory RideLocation.fromJson(Map<String, dynamic> json) {
    // Handle GeoJSON format from API response
    final coords = json['coordinates'];
    RideCoordinates coordinates;

    if (coords is Map<String, dynamic>) {
      if (coords.containsKey('type') && coords['type'] == 'Point') {
        // GeoJSON format: [longitude, latitude]
        final coordsList = coords['coordinates'] as List;
        coordinates = RideCoordinates(
          latitude: (coordsList[1] as num).toDouble(),
          longitude: (coordsList[0] as num).toDouble(),
        );
      } else {
        coordinates = RideCoordinates.fromJson(coords);
      }
    } else {
      coordinates = RideCoordinates(latitude: 0, longitude: 0);
    }

    return RideLocation(
      name: json['address'] as String? ?? '',
      coordinates: coordinates,
      placeId: json['placeId'] as String?,
      address: '${json['city'] ?? ''}, ${json['state'] ?? ''}'
          .trim()
          .replaceAll(RegExp(r'^,|,$'), ''),
    );
  }

  @override
  List<Object?> get props => [address, coordinates, placeId, city, state];
}

/// Coordinates for ride location
class RideCoordinates extends Equatable {
  final double latitude;
  final double longitude;

  const RideCoordinates({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory RideCoordinates.fromJson(Map<String, dynamic> json) {
    return RideCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [latitude, longitude];
}

// ============================================================================
// FARE ESTIMATE MODELS
// ============================================================================

/// Request model for fare estimates
class FareEstimateRequest extends Equatable {
  final RideLocation pickup;
  final RideLocation dropoff;

  const FareEstimateRequest({required this.pickup, required this.dropoff});

  Map<String, dynamic> toJson() => {
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
  };

  @override
  List<Object?> get props => [pickup, dropoff];
}

/// Fare breakdown details
class FareDetails extends Equatable {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgePricing;
  final double surgeMultiplier;
  final double discount;
  final double serviceFee;
  final double tax;
  final double tip;
  final double totalFare;
  final double? waitingFare;

  const FareDetails({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgePricing,
    required this.surgeMultiplier,
    required this.discount,
    required this.serviceFee,
    required this.tax,
    required this.tip,
    required this.totalFare,
    this.waitingFare,
  });

  factory FareDetails.fromJson(Map<String, dynamic> json) {
    return FareDetails(
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0,
      distanceFare: (json['distanceFare'] as num?)?.toDouble() ?? 0,
      timeFare: (json['timeFare'] as num?)?.toDouble() ?? 0,
      surgePricing: (json['surgePricing'] as num?)?.toDouble() ?? 0,
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      totalFare: (json['totalFare'] as num?)?.toDouble() ?? 0,
      waitingFare: (json['waitingFare'] as num?)?.toDouble(),
    );
  }

  double get totalBeforeDiscount =>
      baseFare + distanceFare + timeFare + surgePricing;

  @override
  List<Object?> get props => [
    baseFare,
    distanceFare,
    timeFare,
    surgePricing,
    surgeMultiplier,
    discount,
    serviceFee,
    tax,
    tip,
    totalFare,
    waitingFare,
  ];
}

/// Single vehicle type estimate
class VehicleEstimate extends Equatable {
  final String vehicleType;
  final String rideType;
  final FareDetails fare;
  final int estimatedDistance; // in meters
  final int estimatedDuration; // in seconds
  final int luggageAllowance; // in kg

  const VehicleEstimate({
    required this.vehicleType,
    required this.rideType,
    required this.fare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.luggageAllowance,
  });

  factory VehicleEstimate.fromJson(Map<String, dynamic> json) {
    return VehicleEstimate(
      vehicleType: json['vehicleType'] as String,
      rideType: json['rideType'] as String? ?? 'individual',
      fare: FareDetails.fromJson(json['fare'] as Map<String, dynamic>),
      estimatedDistance: json['estimatedDistance'] as int? ?? 0,
      estimatedDuration: json['estimatedDuration'] as int? ?? 0,
      luggageAllowance: json['luggageAllowance'] as int? ?? 0,
    );
  }

  /// Get distance in km
  double get distanceKm => estimatedDistance / 1000;

  /// Get duration in minutes
  int get durationMinutes => (estimatedDuration / 60).ceil();

  @override
  List<Object?> get props => [
    vehicleType,
    rideType,
    fare,
    estimatedDistance,
    estimatedDuration,
    luggageAllowance,
  ];
}

/// Response model for fare estimates
class FareEstimateResponse extends Equatable {
  final List<VehicleEstimate> estimates;

  const FareEstimateResponse({required this.estimates});

  factory FareEstimateResponse.fromJson(Map<String, dynamic> json) {
    final estimatesList = json['estimates'] as List? ?? [];
    return FareEstimateResponse(
      estimates: estimatesList
          .map((e) => VehicleEstimate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [estimates];
}

// ============================================================================
// AVAILABLE SLOTS MODELS
// ============================================================================

/// Request model for available slots
class AvailableSlotsRequest extends Equatable {
  final RideLocation pickup;
  final RideLocation dropoff;
  final DateTime scheduledTime;

  const AvailableSlotsRequest({
    required this.pickup,
    required this.dropoff,
    required this.scheduledTime,
  });

  Map<String, dynamic> toJson() => {
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'scheduledTime': scheduledTime.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [pickup, dropoff, scheduledTime];
}

/// Pickup window for scheduled rides
class PickupWindow extends Equatable {
  final DateTime start;
  final DateTime end;

  const PickupWindow({required this.start, required this.end});

  factory PickupWindow.fromJson(Map<String, dynamic> json) {
    return PickupWindow(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  @override
  List<Object?> get props => [start, end];
}

/// Available slot for shared rides
class RideSlot extends Equatable {
  final String slotId;
  final DateTime? date;
  final String? departureTime;
  final DateTime? departureDateTime;
  final String? rideType;
  final int? availableSeats;
  final int? totalSeats;
  final double? price;
  final int? luggageAllowance;
  final PickupWindow? pickupWindow;
  final String? currency;
  final List<ExistingRides> existingRides;

  const RideSlot({
    required this.slotId,
    this.date,
    this.departureTime,
    this.departureDateTime,
    this.rideType,
    this.availableSeats,
    this.totalSeats,
    this.price,
    this.luggageAllowance,
    this.pickupWindow,
    this.currency,
    this.existingRides = const [],
  });

  factory RideSlot.fromJson(Map<String, dynamic> json) {
    final existingRidesList = json['existingRides'] as List? ?? [];

    // Handle price from either 'price' field or nested 'fare.totalFare'
    double? price;
    if (json.containsKey('price')) {
      price = (json['price'] as num?)?.toDouble();
    } else if (json.containsKey('fare')) {
      final fare = json['fare'] as Map<String, dynamic>;
      price = (fare['totalFare'] as num?)?.toDouble();
    }

    return RideSlot(
      slotId: json['slotId'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      departureTime: json['departureTime'] as String?,
      departureDateTime: json['departureDateTime'] != null
          ? DateTime.parse(json['departureDateTime'] as String)
          : null,
      rideType: json['rideType'] as String?,
      availableSeats: json['availableSeats'] as int?,
      totalSeats: json['totalSeats'] as int?,
      price: price,
      luggageAllowance: json['luggageAllowance'] as int? ?? 0,
      pickupWindow: json['pickupWindow'] != null
          ? PickupWindow.fromJson(json['pickupWindow'] as Map<String, dynamic>)
          : null,
      currency: json['currency'] as String? ?? 'NGN',
      existingRides: existingRidesList
          .map((e) => ExistingRides.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    slotId,
    date,
    departureTime,
    departureDateTime,
    rideType,
    availableSeats,
    totalSeats,
    price,
    luggageAllowance,
    pickupWindow,
    currency,
    existingRides,
  ];
}

class ExistingRides extends Equatable {
  final String rideId;
  final DateTime scheduledTime;
  final int bookedSeats;
  final int availableSeats;
  final String pickupAddress;
  final String dropoffAddress;
  final PickupWindow pickupWindow;

  const ExistingRides({
    required this.rideId,
    required this.scheduledTime,
    required this.bookedSeats,
    required this.availableSeats,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupWindow,
  });

  factory ExistingRides.fromJson(Map<String, dynamic> json) {
    return ExistingRides(
      rideId: json['rideId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      bookedSeats: json['bookedSeats'] as int,
      availableSeats: json['availableSeats'] as int,
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      pickupWindow: PickupWindow.fromJson(
        json['pickupWindow'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [
    rideId,
    scheduledTime,
    bookedSeats,
    availableSeats,
    pickupAddress,
    dropoffAddress,
    pickupWindow,
  ];
}

/// Response model for available slots
class AvailableSlotsResponse extends Equatable {
  final List<RideSlot> slots;

  const AvailableSlotsResponse({required this.slots});

  factory AvailableSlotsResponse.fromJson(Map<String, dynamic> json) {
    // Handle both "slots" array and "options" object format
    if (json.containsKey('options')) {
      // New format: options object with individual, shared2, shared3
      final options = json['options'] as Map<String, dynamic>;
      final slots = <RideSlot>[];

      options.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          // Generate a slotId from the ride type
          final rideType = value['rideType'] as String? ?? key;
          final modifiedValue = Map<String, dynamic>.from(value);
          modifiedValue['slotId'] = 'slot_$rideType';

          // Set default values for optional fields
          if (!modifiedValue.containsKey('date')) {
            modifiedValue['date'] = DateTime.now().toIso8601String();
          }
          if (!modifiedValue.containsKey('departureTime')) {
            modifiedValue['departureTime'] = 'now';
          }
          if (!modifiedValue.containsKey('departureDateTime')) {
            modifiedValue['departureDateTime'] = DateTime.now()
                .toIso8601String();
          }
          if (!modifiedValue.containsKey('pickupWindow')) {
            modifiedValue['pickupWindow'] = {
              'start': DateTime.now().toIso8601String(),
              'end': DateTime.now()
                  .add(Duration(minutes: 30))
                  .toIso8601String(),
            };
          }

          slots.add(RideSlot.fromJson(modifiedValue));
        }
      });
      return AvailableSlotsResponse(slots: slots);
    } else {
      final slotsList = json['slots'] as List? ?? [];
      return AvailableSlotsResponse(
        slots: slotsList
            .map((e) => RideSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
  }

  @override
  List<Object?> get props => [slots];
}

// ============================================================================
// BOOK RIDE MODELS
// ============================================================================

/// Request model for booking a ride
class BookRideRequest extends Equatable {
  final RideLocation pickup;
  final RideLocation dropoff;
  final String? joinRideId; // For shared rides
  final String? rideType;
  final String? vehicleType; // for individual rides
  final DateTime? scheduledTime;
  final List<RideLocation>? stops;

  const BookRideRequest({
    required this.pickup,
    required this.dropoff,
    this.joinRideId,
    this.rideType,
    this.vehicleType,
    this.scheduledTime,
    this.stops,
  });

  Map<String, dynamic> toJson() => {
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    if (rideType != null) 'rideType': rideType,
    if (rideType != null) 'vehicleType': 'sedan',
    if (joinRideId != null) 'joinRideId': joinRideId,
    if (scheduledTime != null)
      'scheduledTime': scheduledTime!.toUtc().toIso8601String(),
    if (stops != null && stops!.isNotEmpty)
      'stops': stops!.map((s) => {'location': s.toJson()}).toList(),
  };

  @override
  List<Object?> get props => [
    pickup,
    dropoff,
    joinRideId,
    rideType,
    scheduledTime,
    stops,
  ];
}

/// Booked ride details
class BookedRide extends Equatable {
  final String id;
  final String rideNumber;
  final String? userId;
  final String rideType;
  final String vehicleType;
  final RideLocation pickup;
  final RideLocation dropoff;
  final List<RideLocation> stops;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final PickupWindow? pickupWindow;
  final int luggageAllowance;
  final int estimatedDistance;
  final int estimatedDuration;
  final FareDetails fare;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final double cancellationFee;
  final List<String> sharedWith;
  final bool isSharedRideHost;
  final bool sosTriggered;
  final DateTime createdAt;
  final DriverInfo? driver;
  final DateTime? matchedAt;
  final DateTime? paymentDeadline;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final RideRating? driverRating;

  const BookedRide({
    required this.id,
    required this.rideNumber,
    this.userId,
    required this.rideType,
    required this.vehicleType,
    required this.pickup,
    required this.dropoff,
    required this.stops,
    required this.isScheduled,
    this.scheduledTime,
    this.pickupWindow,
    required this.luggageAllowance,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.fare,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.cancellationFee,
    required this.sharedWith,
    required this.isSharedRideHost,
    required this.sosTriggered,
    required this.createdAt,
    this.driver,
    this.matchedAt,
    this.completedAt,
    this.paymentDeadline,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.driverRating,
  });

  factory BookedRide.fromJson(Map<String, dynamic> json) {
    final stopsList = json['stops'] as List? ?? [];
    final sharedWithList = json['sharedWith'] as List? ?? [];

    return BookedRide(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      rideNumber: json['rideNumber'] as String? ?? '',
      userId: json['userId'] as String?,
      rideType: json['rideType'] as String? ?? 'individual',
      vehicleType: json['vehicleType'] as String? ?? '',
      pickup: RideLocation.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: RideLocation.fromJson(json['dropoff'] as Map<String, dynamic>),
      stops: stopsList
          .map(
            (e) => RideLocation.fromJson(
              (e as Map<String, dynamic>)['location'] as Map<String, dynamic>,
            ),
          )
          .toList(),
      isScheduled: json['isScheduled'] as bool? ?? false,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      pickupWindow: json['pickupWindow'] != null
          ? PickupWindow.fromJson(json['pickupWindow'] as Map<String, dynamic>)
          : null,
      luggageAllowance: json['luggageAllowance'] as int? ?? 0,
      estimatedDistance: json['estimatedDistance'] as int? ?? 0,
      estimatedDuration: json['estimatedDuration'] as int? ?? 0,
      fare: FareDetails.fromJson(json['fare'] as Map<String, dynamic>),
      currency: json['currency'] as String? ?? 'NGN',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      status: json['status'] as String? ?? 'pending',
      cancellationFee: (json['cancellationFee'] as num?)?.toDouble() ?? 0,
      sharedWith: sharedWithList.map((e) => e.toString()).toList(),
      isSharedRideHost: json['isSharedRideHost'] as bool? ?? false,
      sosTriggered: json['sosTriggered'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      driver: json['driver'] != null
          ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancelledBy: json['cancelledBy'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      driverRating: json['driverRating'] != null
          ? RideRating.fromJson(json['driverRating'] as Map<String, dynamic>)
          : null,
      paymentDeadline: json['paymentDeadline'] != null
          ? DateTime.parse(json['paymentDeadline'] as String)
          : null,
    );
  }

  /// Get distance in km
  double get distanceKm => estimatedDistance / 1000;

  /// Get duration in minutes
  int get durationMinutes => (estimatedDuration / 60).ceil();

  @override
  List<Object?> get props => [
    id,
    rideNumber,
    userId,
    rideType,
    vehicleType,
    pickup,
    dropoff,
    stops,
    isScheduled,
    scheduledTime,
    pickupWindow,
    luggageAllowance,
    estimatedDistance,
    estimatedDuration,
    fare,
    currency,
    paymentMethod,
    paymentStatus,
    status,
    cancellationFee,
    sharedWith,
    isSharedRideHost,
    sosTriggered,
    createdAt,
    driver,
    matchedAt,
    completedAt,
    cancelledAt,
    cancelledBy,
    cancellationReason,
    driverRating,
    paymentDeadline,
  ];
}

/// Response model for booking a ride
class BookRideResponse extends Equatable {
  final BookedRide ride;

  const BookRideResponse({required this.ride});

  factory BookRideResponse.fromJson(Map<String, dynamic> json) {
    return BookRideResponse(
      ride: BookedRide.fromJson(json['ride'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [ride];
}

// ============================================================================
// DRIVER INFO MODEL
// ============================================================================

/// Driver vehicle info
class VehicleInfo extends Equatable {
  final String type;
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;

  const VehicleInfo({
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      type: json['type'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      color: json['color'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [type, make, model, year, color, licensePlate];
}

/// Driver rating info
class DriverRatingInfo extends Equatable {
  final double average;
  final int count;

  const DriverRatingInfo({required this.average, required this.count});

  factory DriverRatingInfo.fromJson(Map<String, dynamic> json) {
    return DriverRatingInfo(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [average, count];
}

/// Driver information for rides
class DriverInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profilePhoto;
  final VehicleInfo vehicle;
  final DriverRatingInfo rating;

  const DriverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profilePhoto,
    required this.vehicle,
    required this.rating,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      vehicle: VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>),
      rating: DriverRatingInfo.fromJson(json['rating'] as Map<String, dynamic>),
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    phone,
    profilePhoto,
    vehicle,
    rating,
  ];
}

// ============================================================================
// PAYMENT MODELS
// ============================================================================

/// Request model for initializing ride payment
class InitPaymentRequest extends Equatable {
  final String rideId;
  final String paymentMethod;

  const InitPaymentRequest({required this.rideId, required this.paymentMethod});

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'paymentMethod': paymentMethod,
  };

  @override
  List<Object?> get props => [rideId, paymentMethod];
}

/// Payment info in payment response
class PaymentInfo extends Equatable {
  final String reference;
  final double amount;
  final String status;

  const PaymentInfo({
    required this.reference,
    required this.amount,
    required this.status,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      reference: json['reference'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [reference, amount, status];
}

/// Response model for payment initialization
class InitPaymentResponse extends Equatable {
  final String? paymentReference;
  final String? authorizationUrl;
  final String? accessCode;
  final String? paymentMethod;
  final PaymentInfo? payment;

  const InitPaymentResponse({
    this.paymentReference,
    this.authorizationUrl,
    this.accessCode,
    this.paymentMethod,
    this.payment,
  });

  factory InitPaymentResponse.fromJson(Map<String, dynamic> json) {
    return InitPaymentResponse(
      paymentReference: json['reference'] as String?,
      authorizationUrl: json['authorizationUrl'] as String?,
      accessCode: json['accessCode'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      payment: json['payment'] != null
          ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Check if card payment (has authorization URL)
  bool get isCardPayment => authorizationUrl != null;

  @override
  List<Object?> get props => [
    paymentReference,
    authorizationUrl,
    accessCode,
    paymentMethod,
    payment,
  ];
}

/// Request for paying with saved card
class PayWithSavedCardRequest extends Equatable {
  final String rideId;
  final String cardId;

  const PayWithSavedCardRequest({required this.rideId, required this.cardId});

  Map<String, dynamic> toJson() => {'rideId': rideId, 'cardId': cardId};

  @override
  List<Object?> get props => [rideId, cardId];
}

/// Response for payment verification
class VerifyPaymentResponse extends Equatable {
  final String status;
  final String reference;
  final double amount;

  const VerifyPaymentResponse({
    required this.status,
    required this.reference,
    required this.amount,
  });

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPaymentResponse(
      status: json['status'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [status, reference, amount];
}

/// Saved card model
class SavedCard extends Equatable {
  final String id;
  final String cardType;
  final String last4;
  final String expMonth;
  final String expYear;
  final String? bank;
  final String brand;
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.cardType,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.bank,
    required this.brand,
    required this.isDefault,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      cardType: json['cardType'] as String? ?? '',
      last4: json['last4'] as String? ?? '',
      expMonth: json['expMonth'] as String? ?? '',
      expYear: json['expYear'] as String? ?? '',
      bank: json['bank'] as String?,
      brand: json['brand'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    cardType,
    last4,
    expMonth,
    expYear,
    bank,
    brand,
    isDefault,
  ];
}

/// Response for saved cards list
class SavedCardsResponse extends Equatable {
  final List<SavedCard> cards;

  const SavedCardsResponse({required this.cards});

  factory SavedCardsResponse.fromJson(Map<String, dynamic> json) {
    final cardsList = json['cards'] as List? ?? [];
    return SavedCardsResponse(
      cards: cardsList
          .map((e) => SavedCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [cards];
}

/// Wallet balance response
class WalletBalanceResponse extends Equatable {
  final double balance;
  final String currency;

  const WalletBalanceResponse({required this.balance, required this.currency});

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    return WalletBalanceResponse(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
    );
  }

  @override
  List<Object?> get props => [balance, currency];
}

/// Request for wallet top up
class WalletTopUpRequest extends Equatable {
  final double amount;

  const WalletTopUpRequest({required this.amount});

  Map<String, dynamic> toJson() => {'amount': amount};

  @override
  List<Object?> get props => [amount];
}

/// Response for wallet top up
class WalletTopUpResponse extends Equatable {
  final bool success;
  final String authorizationUrl;
  final String reference;

  const WalletTopUpResponse({
    required this.success,
    required this.authorizationUrl,
    required this.reference,
  });

  factory WalletTopUpResponse.fromJson(Map<String, dynamic> json) {
    return WalletTopUpResponse(
      success: json['success'] as bool? ?? false,
      authorizationUrl: json['authorizationUrl'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [success, authorizationUrl, reference];
}

/// Wallet transaction model
class WalletTransaction extends Equatable {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String reference;
  final double balanceAfter;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.reference,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    description,
    reference,
    balanceAfter,
    createdAt,
  ];
}

/// Response for wallet transactions
class WalletTransactionsResponse extends Equatable {
  final List<WalletTransaction> transactions;
  final PaginationInfo pagination;

  const WalletTransactionsResponse({
    required this.transactions,
    required this.pagination,
  });

  factory WalletTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final transactionsList = json['transactions'] as List? ?? [];
    return WalletTransactionsResponse(
      transactions: transactionsList
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [transactions, pagination];
}

/// Payment history entity info
class PaymentEntityInfo extends Equatable {
  final String id;
  final String? rideNumber;
  final String? status;
  final RideLocation? pickup;
  final RideLocation? dropoff;

  const PaymentEntityInfo({
    required this.id,
    this.rideNumber,
    this.status,
    this.pickup,
    this.dropoff,
  });

  factory PaymentEntityInfo.fromJson(Map<String, dynamic> json) {
    return PaymentEntityInfo(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      rideNumber: json['rideNumber'] as String?,
      status: json['status'] as String?,
      pickup: json['pickup'] != null
          ? RideLocation.fromJson(json['pickup'] as Map<String, dynamic>)
          : null,
      dropoff: json['dropoff'] != null
          ? RideLocation.fromJson(json['dropoff'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, rideNumber, status, pickup, dropoff];
}

/// Payment history item
class PaymentHistoryItem extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String paymentType;
  final String paymentMethod;
  final String status;
  final String reference;
  final PaymentEntityInfo? entityId;
  final DateTime createdAt;

  const PaymentHistoryItem({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentType,
    required this.paymentMethod,
    required this.status,
    required this.reference,
    this.entityId,
    required this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['user'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      paymentType: json['paymentType'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      entityId: json['entityId'] != null
          ? PaymentEntityInfo.fromJson(json['entityId'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    currency,
    paymentType,
    paymentMethod,
    status,
    reference,
    entityId,
    createdAt,
  ];
}

/// Response for payment history
class PaymentHistoryResponse extends Equatable {
  final List<PaymentHistoryItem> payments;
  final PaginationInfo pagination;

  const PaymentHistoryResponse({
    required this.payments,
    required this.pagination,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final paymentsList = json['payments'] as List? ?? [];
    return PaymentHistoryResponse(
      payments: paymentsList
          .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [payments, pagination];
}

// ============================================================================
// RIDE HISTORY & MANAGEMENT MODELS
// ============================================================================

/// Pagination info
class PaginationInfo extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
    );
  }

  bool get hasMore => page < pages;

  @override
  List<Object?> get props => [page, limit, total, pages];
}

/// Response for ride history
class RideHistoryResponse extends Equatable {
  final List<BookedRide> rides;
  final PaginationInfo pagination;

  const RideHistoryResponse({required this.rides, required this.pagination});

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    final ridesList = json['rides'] as List? ?? [];
    return RideHistoryResponse(
      rides: ridesList
          .map((e) => BookedRide.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [rides, pagination];
}

/// Request model for cancelling a ride
class CancelRideRequest extends Equatable {
  final String reason;

  const CancelRideRequest({required this.reason});

  Map<String, dynamic> toJson() => {'reason': reason};

  @override
  List<Object?> get props => [reason];
}

/// Response model for cancelling a ride
class CancelRideResponse extends Equatable {
  final BookedRide ride;

  const CancelRideResponse({required this.ride});

  factory CancelRideResponse.fromJson(Map<String, dynamic> json) {
    return CancelRideResponse(
      ride: BookedRide.fromJson(json['ride'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [ride];
}

/// Ride rating
class RideRating extends Equatable {
  final int rating;
  final String? comment;
  final DateTime? ratedAt;

  const RideRating({required this.rating, this.comment, this.ratedAt});

  factory RideRating.fromJson(Map<String, dynamic> json) {
    return RideRating(
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      ratedAt: json['ratedAt'] != null
          ? DateTime.parse(json['ratedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [rating, comment, ratedAt];
}

/// Request model for rating a ride
class RateRideRequest extends Equatable {
  final int rating;
  final String? comment;

  const RateRideRequest({required this.rating, this.comment});

  Map<String, dynamic> toJson() => {
    'rating': rating,
    if (comment != null) 'comment': comment,
  };

  @override
  List<Object?> get props => [rating, comment];
}

/// Response model for rating a ride
class RateRideResponse extends Equatable {
  final BookedRide ride;

  const RateRideResponse({required this.ride});

  factory RateRideResponse.fromJson(Map<String, dynamic> json) {
    return RateRideResponse(
      ride: BookedRide.fromJson(json['ride'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [ride];
}

/// Response model for active ride
class ActiveRideResponse extends Equatable {
  final BookedRide? ride;

  const ActiveRideResponse({this.ride});

  factory ActiveRideResponse.fromJson(Map<String, dynamic> json) {
    final rideData = json['ride'];
    return ActiveRideResponse(
      ride: rideData != null
          ? BookedRide.fromJson(rideData as Map<String, dynamic>)
          : null,
    );
  }

  bool get hasActiveRide => ride != null;

  @override
  List<Object?> get props => [ride];
}
